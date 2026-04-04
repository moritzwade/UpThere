import Foundation
import os

/// Service for fetching flight route information from AviationStack API
actor FlightRouteService {
    private let config: AviationStackConfig
    private let session: URLSession
    
    /// In-memory cache for route info, keyed by ICAO24
    private var cache: [String: FlightRouteInfo] = [:]
    
    /// Initializer for production use
    nonisolated init(config: AviationStackConfig = .default) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: configuration)
    }
    
    /// Initializer with custom URLSession (for testing)
    nonisolated init(config: AviationStackConfig, session: URLSession) {
        self.config = config
        self.session = session
    }
    
    /// Fetch route information for a flight
    /// - Parameter flight: The flight to look up
    /// - Returns: Route info if available, nil if not found or not configured
    func fetchRoute(for flight: Flight) async throws -> FlightRouteInfo? {
        // Check cache first
        if let cached = cache[flight.id] {
            AppLogger.flightService.debug("Route cache hit for \(flight.id, privacy: .public)")
            return cached
        }
        
        guard config.isConfigured else {
            AppLogger.flightService.warning("AviationStack not configured, skipping route lookup")
            return nil
        }
        
        guard let callsign = flight.callsign.trimmingCharacters(in: .whitespaces).uppercased().nilIfEmpty else {
            AppLogger.flightService.debug("No callsign for flight \(flight.id, privacy: .public), skipping route lookup")
            return nil
        }
        
        let url = try buildURL(for: callsign)
        AppLogger.flightService.debug("Fetching route info: \(url.absoluteString, privacy: .public)")
        
        let request = URLRequest(url: url)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.flightService.error("Invalid response type from AviationStack API")
                throw AviationStackError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let routeInfo = try FlightRouteInfo.parse(from: data)
                if let routeInfo = routeInfo {
                    cache[flight.id] = routeInfo
                    AppLogger.flightService.info("Fetched route info for \(flight.id, privacy: .public)")
                } else {
                    AppLogger.flightService.debug("No route data found for flight \(callsign, privacy: .public)")
                }
                return routeInfo
            case 404:
                AppLogger.flightService.debug("No route data found for flight \(callsign, privacy: .public)")
                return nil
            case 429:
                AppLogger.flightService.warning("Rate limited by AviationStack API (429)")
                throw AviationStackError.rateLimited
            default:
                if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                    AppLogger.flightService.error("AviationStack API error (\(httpResponse.statusCode, privacy: .public)): \(errorText, privacy: .public)")
                }
                throw AviationStackError.invalidResponse
            }
        } catch let error as AviationStackError {
            throw error
        } catch {
            AppLogger.flightService.error("Network error fetching route info: \(error.localizedDescription, privacy: .public)")
            throw AviationStackError.networkError(error)
        }
    }
    
    /// Clear the route cache
    func clearCache() {
        cache.removeAll()
    }
    
    /// Build URL with query parameters for AviationStack flights endpoint
    private func buildURL(for callsign: String) throws -> URL {
        guard let apiKey = config.apiKey else {
            throw AviationStackError.unauthorized
        }
        
        var components = URLComponents(string: "\(config.baseURL)/flights")
        components?.queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "flight_icao", value: callsign)
        ]
        
        guard let url = components?.url else {
            throw AviationStackError.invalidResponse
        }
        
        return url
    }
}

// MARK: - AviationStack Errors

enum AviationStackError: Error, LocalizedError {
    case invalidResponse
    case networkError(Error)
    case unauthorized
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AviationStack API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "AviationStack API key not configured"
        case .rateLimited:
            return "AviationStack rate limit exceeded"
        }
    }
}

// MARK: - String helper

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
