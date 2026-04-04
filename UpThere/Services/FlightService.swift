import Foundation
import os

/// Service for fetching flight data from OpenSky Network API
actor FlightService {
    private var credentials: ResolvedCredentials
    private let session: URLSession
    
    // OAuth2 token management
    private var accessToken: String?
    private var tokenExpiresAt: Date?
    
    // Track which credential source was last used (for logging)
    private var lastCredentialSource: String?
    
    private let decoder = JSONDecoder()
    
    /// Initializer for production use
    init(credentials: ResolvedCredentials) {
        self.credentials = credentials
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    /// Initializer with custom URLSession (for testing)
    init(credentials: ResolvedCredentials, session: URLSession) {
        self.credentials = credentials
        self.session = session
    }
    
    /// Update credentials when settings change
    func updateCredentials(_ newCredentials: ResolvedCredentials) {
        // Clear cached token when credentials change
        if credentials.sourceDescription != newCredentials.sourceDescription {
            accessToken = nil
            tokenExpiresAt = nil
        }
        credentials = newCredentials
    }
    
    /// Log the credential source once at first use
    private func logCredentialSource(_ source: String) {
        guard lastCredentialSource != source else { return }
        lastCredentialSource = source
        AppLogger.flightService.info("Using API credentials from: \(source, privacy: .public)")
    }
    
    /// Fetch all flights within a bounding box
    func fetchFlights(in boundingBox: BoundingBox) async throws -> [Flight] {
        logCredentialSource(credentials.sourceDescription)
        let url = try buildURL(for: boundingBox)
        AppLogger.flightService.debug("Fetching flights: \(url.absoluteString, privacy: .public)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication if configured
        if credentials.isConfigured {
            let token = try await getAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.flightService.error("Invalid response type from OpenSky API")
                throw OpenSkyError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let openSkyResponse = try OpenSkyResponse.parse(from: data)
                let flights = openSkyResponse.toFlights()
                AppLogger.flightService.info("Fetched \(flights.count, privacy: .public) flights")
                return flights
            case 401:
                // Token expired, refresh and retry
                AppLogger.flightService.warning("Received 401, refreshing token and retrying")
                accessToken = nil
                tokenExpiresAt = nil
                if credentials.isConfigured {
                    let newToken = try await getAccessToken()
                    return try await fetchFlightsWithToken(newToken, boundingBox: boundingBox)
                }
                throw OpenSkyError.unauthorized
            case 429:
                AppLogger.flightService.warning("Rate limited by OpenSky API (429)")
                throw OpenSkyError.rateLimited
            default:
                // Try to extract error message from response
                if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                    AppLogger.flightService.error("OpenSky API error (\(httpResponse.statusCode, privacy: .public)): \(errorText, privacy: .public)")
                } else {
                    AppLogger.flightService.error("OpenSky API error (\(httpResponse.statusCode, privacy: .public)): no response body")
                }
                throw OpenSkyError.invalidResponse
            }
        } catch let error as OpenSkyError {
            throw error
        } catch {
            AppLogger.flightService.error("Network error fetching flights: \(error.localizedDescription, privacy: .public)")
            throw OpenSkyError.networkError(error)
        }
    }
    
    /// Fetch flights with a specific token
    private func fetchFlightsWithToken(_ token: String, boundingBox: BoundingBox) async throws -> [Flight] {
        let url = try buildURL(for: boundingBox)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.flightService.error("Invalid response type from OpenSky API (retry)")
            throw OpenSkyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                AppLogger.flightService.error("OpenSky API error after token refresh (\(httpResponse.statusCode, privacy: .public)): \(errorText, privacy: .public)")
            } else {
                AppLogger.flightService.error("OpenSky API error after token refresh (\(httpResponse.statusCode, privacy: .public)): no response body")
            }
            throw OpenSkyError.invalidResponse
        }
        
        let openSkyResponse = try OpenSkyResponse.parse(from: data)
        let flights = openSkyResponse.toFlights()
        AppLogger.flightService.info("Fetched \(flights.count, privacy: .public) flights (after token refresh)")
        return flights
    }
    
    /// Get a valid access token, refreshing if needed
    private func getAccessToken() async throws -> String {
        // Check if we have a valid cached token
        if let token = accessToken, let expiresAt = tokenExpiresAt, Date() < expiresAt {
            return token
        }
        
        guard credentials.isConfigured else {
            throw OpenSkyError.unauthorized
        }
        
        return try await refreshToken()
    }
    
    /// Refresh the OAuth2 access token
    private func refreshToken() async throws -> String {
        guard let clientId = credentials.clientId,
              let clientSecret = credentials.clientSecret else {
            throw OpenSkyError.unauthorized
        }
        
        let authURL = URL(string: OpenSkyConfig.default.authURL)!
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "grant_type=client_credentials&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            if let errorText = String(data: data, encoding: .utf8) {
                AppLogger.flightService.error("Auth error (\(status, privacy: .public)): \(errorText, privacy: .public)")
            } else {
                AppLogger.flightService.error("Auth error (\(status, privacy: .public)): no response body")
            }
            throw OpenSkyError.unauthorized
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OpenSkyError.unauthorized
        }
        
        // Cache the token
        self.accessToken = accessToken
        
        // Set expiry (typically 30 minutes, with margin)
        let expiresIn = json["expires_in"] as? Int ?? 1800
        self.tokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn - 60))
        
        AppLogger.flightService.debug("OAuth token refreshed, expires in \(expiresIn - 60, privacy: .public)s")
        
        return accessToken
    }
    
    /// Fetch historical flight states for a specific aircraft.
    /// Returns an array of (timestamp, longitude, latitude) tuples.
    /// - Parameters:
    ///   - icao24: The ICAO24 hex identifier of the aircraft
    ///   - timeFrom: Start of the time range (Unix timestamp)
    ///   - timeTo: End of the time range (Unix timestamp)
    /// - Returns: Array of (date, longitude, latitude) tuples sorted by time
    func fetchFlightHistory(icao24: String, timeFrom: Int, timeTo: Int) async throws -> [(date: Date, longitude: Double, latitude: Double)] {
        let url = try buildHistoryURL(icao24: icao24, timeFrom: timeFrom, timeTo: timeTo)
        AppLogger.flightService.debug("Fetching flight history for \(icao24, privacy: .public) from \(timeFrom, privacy: .public) to \(timeTo, privacy: .public)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if credentials.isConfigured {
            let token = try await getAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.flightService.error("Invalid response type from OpenSky history API")
                throw OpenSkyError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                let historyResponse = try OpenSkyHistoryResponse.parse(from: data)
                let positions = historyResponse.toPositions()
                AppLogger.flightService.debug("Fetched \(positions.count, privacy: .public) historical positions for \(icao24, privacy: .public)")
                return positions
            case 401:
                AppLogger.flightService.warning("Received 401 from history API, refreshing token and retrying")
                accessToken = nil
                tokenExpiresAt = nil
                if credentials.isConfigured {
                    let newToken = try await getAccessToken()
                    return try await fetchFlightHistoryWithToken(newToken, icao24: icao24, timeFrom: timeFrom, timeTo: timeTo)
                }
                throw OpenSkyError.unauthorized
            case 429:
                AppLogger.flightService.warning("Rate limited by OpenSky history API (429)")
                throw OpenSkyError.rateLimited
            default:
                if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                    AppLogger.flightService.error("OpenSky history API error (\(httpResponse.statusCode, privacy: .public)): \(errorText, privacy: .public)")
                }
                throw OpenSkyError.invalidResponse
            }
        } catch let error as OpenSkyError {
            throw error
        } catch {
            AppLogger.flightService.error("Network error fetching flight history: \(error.localizedDescription, privacy: .public)")
            throw OpenSkyError.networkError(error)
        }
    }

    /// Fetch flight history with a specific token (retry after 401)
    private func fetchFlightHistoryWithToken(_ token: String, icao24: String, timeFrom: Int, timeTo: Int) async throws -> [(date: Date, longitude: Double, latitude: Double)] {
        let url = try buildHistoryURL(icao24: icao24, timeFrom: timeFrom, timeTo: timeTo)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.flightService.error("Invalid response type from OpenSky history API (retry)")
            throw OpenSkyError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                AppLogger.flightService.error("OpenSky history API error after token refresh (\(httpResponse.statusCode, privacy: .public)): \(errorText, privacy: .public)")
            }
            throw OpenSkyError.invalidResponse
        }

        let historyResponse = try OpenSkyHistoryResponse.parse(from: data)
        let positions = historyResponse.toPositions()
        AppLogger.flightService.debug("Fetched \(positions.count, privacy: .public) historical positions for \(icao24, privacy: .public) (after token refresh)")
        return positions
    }

    /// Build URL with query parameters
    private func buildURL(for boundingBox: BoundingBox) throws -> URL {
        var components = URLComponents(string: "\(OpenSkyConfig.default.baseURL)/states/all")
        components?.queryItems = boundingBox.queryItems

        guard let url = components?.url else {
            throw OpenSkyError.invalidResponse
        }

        return url
    }

    /// Build URL for the flight history endpoint
    private func buildHistoryURL(icao24: String, timeFrom: Int, timeTo: Int) throws -> URL {
        var components = URLComponents(string: "\(OpenSkyConfig.default.baseURL)/api/states/all")
        components?.queryItems = [
            URLQueryItem(name: "icao24", value: icao24),
            URLQueryItem(name: "time", value: String(timeFrom)),
            URLQueryItem(name: "endTime", value: String(timeTo))
        ]

        guard let url = components?.url else {
            throw OpenSkyError.invalidResponse
        }

        return url
    }
}
