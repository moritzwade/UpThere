import Foundation

/// Service for fetching flight data from OpenSky Network API
actor FlightService {
    private let config: OpenSkyConfig
    private let session: URLSession
    
    // OAuth2 token management
    private var accessToken: String?
    private var tokenExpiresAt: Date?
    
    private let decoder = JSONDecoder()
    
    nonisolated init(config: OpenSkyConfig = .default) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    /// Fetch all flights within a bounding box
    func fetchFlights(in boundingBox: BoundingBox) async throws -> [Flight] {
        let url = try buildURL(for: boundingBox)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication if configured
        if config.isConfigured {
            let token = try await getAccessToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenSkyError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let openSkyResponse = try OpenSkyResponse.parse(from: data)
                return openSkyResponse.toFlights()
            case 401:
                // Token expired, refresh and retry
                accessToken = nil
                tokenExpiresAt = nil
                if config.isConfigured {
                    let newToken = try await getAccessToken()
                    return try await fetchFlightsWithToken(newToken, boundingBox: boundingBox)
                }
                throw OpenSkyError.unauthorized
            case 429:
                throw OpenSkyError.rateLimited
            default:
                // Try to extract error message from response
                if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                    print("OpenSky API error (\(httpResponse.statusCode)): \(errorText)")
                }
                throw OpenSkyError.invalidResponse
            }
        } catch let error as OpenSkyError {
            throw error
        } catch {
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
            throw OpenSkyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8), !errorText.isEmpty {
                print("OpenSky API error (\(httpResponse.statusCode)): \(errorText)")
            }
            throw OpenSkyError.invalidResponse
        }
        
        let openSkyResponse = try OpenSkyResponse.parse(from: data)
        return openSkyResponse.toFlights()
    }
    
    /// Get a valid access token, refreshing if needed
    private func getAccessToken() async throws -> String {
        // Check if we have a valid cached token
        if let token = accessToken, let expiresAt = tokenExpiresAt, Date() < expiresAt {
            return token
        }
        
        guard config.isConfigured else {
            throw OpenSkyError.unauthorized
        }
        
        return try await refreshToken()
    }
    
    /// Refresh the OAuth2 access token
    private func refreshToken() async throws -> String {
        guard let clientId = config.clientId,
              let clientSecret = config.clientSecret else {
            throw OpenSkyError.unauthorized
        }
        
        let authURL = URL(string: config.authURL)!
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = "grant_type=client_credentials&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("Auth error: \(errorText)")
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
        
        return accessToken
    }
    
    /// Build URL with query parameters
    private func buildURL(for boundingBox: BoundingBox) throws -> URL {
        var components = URLComponents(string: "\(config.baseURL)/states/all")
        components?.queryItems = boundingBox.queryItems
        
        guard let url = components?.url else {
            throw OpenSkyError.invalidResponse
        }
        
        return url
    }
}
