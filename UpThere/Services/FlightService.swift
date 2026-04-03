import Foundation

/// Service for fetching flight data from OpenSky Network API
actor FlightService {
    private let config: OpenSkyConfig
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    nonisolated init(config: OpenSkyConfig = .default) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }
    
    /// Fetch all flights within a bounding box
    /// - Parameter boundingBox: Geographic area to search
    /// - Returns: Array of flights
    func fetchFlights(in boundingBox: BoundingBox) async throws -> [Flight] {
        let url = try buildURL(for: boundingBox)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication if configured
        if config.isConfigured {
            let credentials = "\(config.username!):\(config.password!)"
            if let credentialData = credentials.data(using: .utf8) {
                let base64Credentials = credentialData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
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
                throw OpenSkyError.unauthorized
            case 429:
                throw OpenSkyError.rateLimited
            default:
                throw OpenSkyError.invalidResponse
            }
        } catch let error as OpenSkyError {
            throw error
        } catch {
            throw OpenSkyError.networkError(error)
        }
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
