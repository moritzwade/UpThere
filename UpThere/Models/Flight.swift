import Foundation
import CoreLocation

/// Represents a flight detected by OpenSky Network
struct Flight: Identifiable, Hashable {
    /// Unique identifier (ICAO24)
    let id: String
    
    /// Flight callsign (e.g., "UAL1234")
    let callsign: String
    
    /// Country where the aircraft is registered
    let originCountry: String
    
    /// Unix timestamp of last position update
    let lastContact: Date
    
    /// Current longitude (-180 to 180)
    let longitude: Double?
    
    /// Current latitude (-90 to 90)
    let latitude: Double?
    
    /// Barometric altitude in meters
    let baroAltitude: Double?
    
    /// Whether aircraft is on ground
    let onGround: Bool
    
    /// Ground speed in m/s
    let velocity: Double?
    
    /// True track angle (0-360 degrees)
    let trueTrack: Double?
    
    /// Vertical speed in m/s
    let verticalRate: Double?
    
    /// Squawk code
    let squawk: String?
    
    /// Coordinate if available
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    /// Altitude in feet (converted from meters)
    var altitudeFeet: Double? {
        guard let alt = baroAltitude else { return nil }
        return alt * 3.28084
    }
    
    /// Speed in knots (converted from m/s)
    var speedKnots: Double? {
        guard let speed = velocity else { return nil }
        return speed * 1.94384
    }
    
    /// Vertical rate in feet per minute (converted from m/s)
    var verticalRateFPM: Double? {
        guard let rate = verticalRate else { return nil }
        return rate * 196.85
    }
    
    /// Formatted callsign (trimmed and uppercased)
    var formattedCallsign: String {
        callsign.trimmingCharacters(in: .whitespaces).uppercased()
    }
    
    /// ICAO airline designator extracted from callsign (first 3 characters, e.g., "UAL" from "UAL1234")
    var airlineDesignator: String? {
        let trimmed = formattedCallsign
        guard trimmed.count >= 3 else { return nil }
        let designator = String(trimmed.prefix(3))
        // Validate it looks like an ICAO code (letters only)
        guard designator.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else { return nil }
        return designator
    }
}

/// Extension for creating Flight from OpenSky state array
extension Flight {
    /// Create a Flight from OpenSky state array
    /// States array: [icao24, callsign, origin_country, time_position, last_contact,
    ///                longitude, latitude, baro_altitude, on_ground, velocity,
    ///                true_track, vertical_rate, sensors, geo_altitude, squawk, spi, position_source]
    init?(from state: [Any], lastUpdate: Date) {
        guard state.count >= 17,
              let icao24 = state[0] as? String,
              let callsign = state[1] as? String,
              let originCountry = state[2] as? String else {
            return nil
        }
        
        self.id = icao24
        self.callsign = callsign
        self.originCountry = originCountry
        self.longitude = state[5] as? Double
        self.latitude = state[6] as? Double
        self.baroAltitude = state[7] as? Double
        self.onGround = (state[8] as? Bool) ?? false
        self.velocity = state[9] as? Double
        self.trueTrack = state[10] as? Double
        self.verticalRate = state[11] as? Double
        self.squawk = state[14] as? String
        
        if let lastContactInt = state[4] as? Int {
            self.lastContact = Date(timeIntervalSince1970: TimeInterval(lastContactInt))
        } else {
            self.lastContact = lastUpdate
        }
    }
}
