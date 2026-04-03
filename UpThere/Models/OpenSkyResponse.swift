import Foundation

/// Response from OpenSky Network states/all endpoint
/// Note: We parse this manually since the states array contains mixed types
struct OpenSkyResponse {
    /// Unix timestamp of the request
    let time: Int
    
    /// Raw states array from JSON
    let states: [[Any]]?
    
    /// Convert to Flight objects
    func toFlights() -> [Flight] {
        guard let states = states else { return [] }
        
        let lastUpdate = Date(timeIntervalSince1970: TimeInterval(time))
        
        return states.compactMap { state in
            // Convert NSNumber to Double where needed
            let convertedState = state.map { value -> Any in
                if let nsNumber = value as? NSNumber {
                    return nsNumber.doubleValue
                }
                return value
            }
            return Flight(from: convertedState, lastUpdate: lastUpdate)
        }
    }
    
    /// Parse from JSON data
    static func parse(from data: Data) throws -> OpenSkyResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let time = json["time"] as? Int else {
            throw OpenSkyError.invalidResponse
        }
        
        var states: [[Any]]? = nil
        if let rawStates = json["states"] as? [[Any]] {
            states = rawStates
        }
        
        return OpenSkyResponse(time: time, states: states)
    }
}

/// OpenSky API errors
enum OpenSkyError: Error, LocalizedError {
    case invalidResponse
    case networkError(Error)
    case unauthorized
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenSky API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Invalid OpenSky credentials"
        case .rateLimited:
            return "OpenSky rate limit exceeded"
        }
    }
}

/// Bounding box for OpenSky API requests
struct BoundingBox {
    let minLatitude: Double
    let maxLatitude: Double
    let minLongitude: Double
    let maxLongitude: Double
    
    /// Create a bounding box centered on a location with a radius
    /// - Parameters:
    ///   - latitude: Center latitude
    ///   - longitude: Center longitude
    ///   - radiusKm: Radius in kilometers (default 200km)
    static func around(latitude: Double, longitude: Double, radiusKm: Double = 200) -> BoundingBox {
        // Approximate degrees per km
        let latDegPerKm = 1.0 / 111.0
        let lonDegPerKm = 1.0 / (111.0 * cos(latitude * .pi / 180))
        
        let latDelta = radiusKm * latDegPerKm
        let lonDelta = radiusKm * lonDegPerKm
        
        return BoundingBox(
            minLatitude: latitude - latDelta,
            maxLatitude: latitude + latDelta,
            minLongitude: longitude - lonDelta,
            maxLongitude: longitude + lonDelta
        )
    }
    
    /// Query parameters for OpenSky API
    var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "lamin", value: String(minLatitude)),
            URLQueryItem(name: "lamax", value: String(maxLatitude)),
            URLQueryItem(name: "lomin", value: String(minLongitude)),
            URLQueryItem(name: "lomax", value: String(maxLongitude))
        ]
    }
}
