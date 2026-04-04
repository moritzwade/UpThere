import Foundation
import CoreLocation
import MapKit

/// Represents the recent flight path/trajectory for a single aircraft.
///
/// Trails are built client-side by accumulating positions from each 5-second refresh.
/// For non-selected flights, only the last 5 minutes of positions are kept.
/// For the selected flight, a complete historical trail is fetched from the API.
struct FlightTrail: Identifiable {
    /// ICAO24 identifier (same as Flight.id)
    let id: String
    
    /// Ordered list of timestamped positions (oldest first)
    private(set) var positions: [(date: Date, coordinate: CLLocationCoordinate2D)] = []
    
    /// Whether this trail was fetched from the historical API (complete flight)
    var isCompleteHistory: Bool = false
    
    /// Maximum age of positions to keep for accumulated trails
    static let maxTrailAge: TimeInterval = 5 * 60 // 5 minutes
    
    /// Create a new trail for the given ICAO24
    init(icao24: String) {
        self.id = icao24
    }
    
    /// Append a new position to the trail.
    /// Automatically trims positions older than 5 minutes (unless this is a complete history trail).
    mutating func append(date: Date, coordinate: CLLocationCoordinate2D) {
        // Don't add duplicate positions at the same timestamp
        if let last = positions.last, last.date == date {
            return
        }
        positions.append((date: date, coordinate: coordinate))
        // Keep sorted by date
        positions.sort { $0.date < $1.date }
        if !isCompleteHistory {
            trimToMaxAge()
        }
    }
    
    /// Trim positions older than maxTrailAge from the most recent position.
    private mutating func trimToMaxAge() {
        guard let mostRecent = positions.map(\.date).max() else { return }
        let cutoff = mostRecent.addingTimeInterval(-Self.maxTrailAge)
        positions.removeAll { $0.date < cutoff }
    }
    
    /// Replace the entire trail with positions from the historical API.
    mutating func setCompleteHistory(positions: [(date: Date, coordinate: CLLocationCoordinate2D)]) {
        self.positions = positions.sorted { $0.date < $1.date }
        self.isCompleteHistory = true
    }
    
    /// Reset to an accumulated trail (e.g., when deselecting a flight).
    mutating func resetToAccumulated() {
        isCompleteHistory = false
        trimToMaxAge()
    }
    
    /// Array of CLLocationCoordinate2D for MapKit polyline rendering
    var coordinates: [CLLocationCoordinate2D] {
        positions.map(\.coordinate)
    }
    
    /// Whether the trail has enough points to render (minimum 2)
    var isValid: Bool {
        positions.count >= 2
    }
    
    /// Number of positions in the trail
    var positionCount: Int {
        positions.count
    }
    
    /// MKCoordinateRegion that encompasses all positions in the trail
    var coordinateRegion: MKCoordinateRegion? {
        guard !positions.isEmpty else { return nil }
        
        let coords = positions.map(\.coordinate)
        let minLat = coords.map(\.latitude).min()!
        let maxLat = coords.map(\.latitude).max()!
        let minLon = coords.map(\.longitude).min()!
        let maxLon = coords.map(\.longitude).max()!
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Add 20% padding
        let latDelta = max((maxLat - minLat) * 1.2, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.2, 0.01)
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}
