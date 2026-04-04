import Foundation
import Testing
import CoreLocation

@testable import UpThere

struct FlightTrailTests {
    
    // MARK: - Initialization Tests
    
    @Test
    func testInitCreatesEmptyTrail() {
        let trail = FlightTrail(icao24: "3c6444")
        
        #expect(trail.id == "3c6444")
        #expect(trail.positionCount == 0)
        #expect(!trail.isValid)
        #expect(!trail.isCompleteHistory)
    }
    
    // MARK: - Append Tests
    
    @Test
    func testAppendAddsPosition() {
        var trail = FlightTrail(icao24: "3c6444")
        let date = Date()
        let coord = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        trail.append(date: date, coordinate: coord)
        
        #expect(trail.positionCount == 1)
        #expect(trail.positions[0].date == date)
        #expect(trail.positions[0].coordinate.latitude == 37.7749)
        #expect(trail.positions[0].coordinate.longitude == -122.4194)
    }
    
    @Test
    func testAppendMultiplePositionsKeepsOrder() {
        var trail = FlightTrail(icao24: "3c6444")
        let baseDate = Date()
        
        trail.append(date: baseDate.addingTimeInterval(10), coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42))
        trail.append(date: baseDate, coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        trail.append(date: baseDate.addingTimeInterval(5), coordinate: CLLocationCoordinate2D(latitude: 37.775, longitude: -122.415))
        
        // Should be sorted by date
        #expect(trail.positions[0].date == baseDate)
        #expect(trail.positions[1].date == baseDate.addingTimeInterval(5))
        #expect(trail.positions[2].date == baseDate.addingTimeInterval(10))
    }
    
    @Test
    func testAppendSkipsDuplicateTimestamp() {
        var trail = FlightTrail(icao24: "3c6444")
        let date = Date()
        
        trail.append(date: date, coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        trail.append(date: date, coordinate: CLLocationCoordinate2D(latitude: 38.00, longitude: -123.00))
        
        #expect(trail.positionCount == 1)
        #expect(trail.positions[0].coordinate.latitude == 37.77)
    }
    
    // MARK: - Trim Tests
    
    @Test
    func testTrimRemovesOldPositions() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        // Add position 6 minutes ago (should be trimmed)
        trail.append(date: now.addingTimeInterval(-360), coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        // Add position 4 minutes ago (should be kept)
        trail.append(date: now.addingTimeInterval(-240), coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42))
        // Add position now (should be kept)
        trail.append(date: now, coordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.43))
        
        #expect(trail.positionCount == 2)
        #expect(trail.positions[0].date == now.addingTimeInterval(-240))
        #expect(trail.positions[1].date == now)
    }
    
    @Test
    func testTrimRemovesAllOldPositions() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        trail.append(date: now.addingTimeInterval(-360), coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        trail.append(date: now.addingTimeInterval(-350), coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42))
        
        // Add a new position now — the old ones are > 5 min before this
        trail.append(date: now, coordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.43))
        
        #expect(trail.positionCount == 1)
        #expect(trail.positions[0].date == now)
    }
    
    // MARK: - Complete History Tests
    
    @Test
    func testSetCompleteHistory() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        let positions = [
            (date: now.addingTimeInterval(-3600), coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41)),
            (date: now.addingTimeInterval(-1800), coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42)),
            (date: now, coordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.43))
        ]
        
        trail.setCompleteHistory(positions: positions)
        
        #expect(trail.isCompleteHistory)
        #expect(trail.positionCount == 3)
        // Should NOT trim old positions since it's a complete history
        #expect(trail.positions[0].date == now.addingTimeInterval(-3600))
    }
    
    @Test
    func testCompleteHistoryDoesNotTrimOnAppend() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        trail.setCompleteHistory(positions: [
            (date: now.addingTimeInterval(-3600), coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        ])
        
        // Append a new position — should NOT trigger trimming
        trail.append(date: now, coordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.43))
        
        #expect(trail.positionCount == 2)
        #expect(trail.positions[0].date == now.addingTimeInterval(-3600))
    }
    
    @Test
    func testResetToAccumulated() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        trail.setCompleteHistory(positions: [
            (date: now.addingTimeInterval(-3600), coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41)),
            (date: now, coordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.43))
        ])
        
        trail.resetToAccumulated()
        
        #expect(!trail.isCompleteHistory)
        // Should trim the old position
        #expect(trail.positionCount == 1)
        #expect(trail.positions[0].date == now)
    }
    
    // MARK: - Coordinates Helper Tests
    
    @Test
    func testCoordinatesReturnsArrayOfCLLocationCoordinate2D() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        trail.append(date: now, coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        trail.append(date: now.addingTimeInterval(5), coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42))
        
        let coords = trail.coordinates
        
        #expect(coords.count == 2)
        #expect(coords[0].latitude == 37.77)
        #expect(coords[1].latitude == 37.78)
    }
    
    // MARK: - isValid Tests
    
    @Test
    func testIsValidRequiresAtLeastTwoPositions() {
        var trail = FlightTrail(icao24: "3c6444")
        
        #expect(!trail.isValid)
        
        let now = Date()
        trail.append(date: now, coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        #expect(!trail.isValid)
        
        trail.append(date: now.addingTimeInterval(5), coordinate: CLLocationCoordinate2D(latitude: 37.78, longitude: -122.42))
        #expect(trail.isValid)
    }
    
    // MARK: - coordinateRegion Tests
    
    @Test
    func testCoordinateRegionReturnsNilForEmptyTrail() {
        let trail = FlightTrail(icao24: "3c6444")
        #expect(trail.coordinateRegion == nil)
    }
    
    @Test
    func testCoordinateRegionEncompassesPositions() {
        var trail = FlightTrail(icao24: "3c6444")
        let now = Date()
        
        trail.append(date: now, coordinate: CLLocationCoordinate2D(latitude: 37.77, longitude: -122.41))
        trail.append(date: now.addingTimeInterval(5), coordinate: CLLocationCoordinate2D(latitude: 37.79, longitude: -122.39))
        
        let region = trail.coordinateRegion
        
        #expect(region != nil)
        // Center should be roughly midpoint
        #expect(abs(region!.center.latitude - 37.78) < 0.01)
        #expect(abs(region!.center.longitude - (-122.40)) < 0.01)
    }
}
