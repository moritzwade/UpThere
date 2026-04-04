import Foundation
import Testing

@testable import UpThere

struct BoundingBoxTests {
    
    // MARK: - Initialization Tests
    
    @Test
    func testAroundCreatesCorrectBounds() {
        let boundingBox = BoundingBox.around(
            latitude: 37.7749,
            longitude: -122.4194,
            radiusKm: 200
        )
        
        // With 200km radius at latitude ~38:
        // ~111km per degree latitude
        // ~111km per degree longitude at equator, less at higher latitudes
        
        let expectedLatDelta = 200.0 / 111.0 // ~1.8 degrees
        let expectedLonDelta = 200.0 / (111.0 * cos(37.7749 * .pi / 180)) // ~2.3 degrees
        
        #expect(abs(boundingBox.minLatitude - (37.7749 - expectedLatDelta)) < 0.1)
        #expect(abs(boundingBox.maxLatitude - (37.7749 + expectedLatDelta)) < 0.1)
        #expect(abs(boundingBox.minLongitude - (-122.4194 - expectedLonDelta)) < 0.1)
        #expect(abs(boundingBox.maxLongitude - (-122.4194 + expectedLonDelta)) < 0.1)
    }
    
    @Test
    func testAroundWithDifferentRadius() {
        let boundingBox100 = BoundingBox.around(
            latitude: 37.7749,
            longitude: -122.4194,
            radiusKm: 100
        )
        
        let boundingBox200 = BoundingBox.around(
            latitude: 37.7749,
            longitude: -122.4194,
            radiusKm: 200
        )
        
        // 100km box should be roughly half the size of 200km box
        let latRange100 = boundingBox100.maxLatitude - boundingBox100.minLatitude
        let latRange200 = boundingBox200.maxLatitude - boundingBox200.minLatitude
        
        #expect(abs(latRange100 - latRange200 / 2) < 0.1)
    }
    
    @Test
    func testAroundCenterPointIsCorrect() {
        let boundingBox = BoundingBox.around(
            latitude: 40.0,
            longitude: -75.0,
            radiusKm: 100
        )
        
        let centerLat = (boundingBox.minLatitude + boundingBox.maxLatitude) / 2
        let centerLon = (boundingBox.minLongitude + boundingBox.maxLongitude) / 2
        
        #expect(abs(centerLat - 40.0) < 0.001)
        #expect(abs(centerLon - (-75.0)) < 0.001)
    }
    
    // MARK: - Query Items Tests
    
    @Test
    func testQueryItems() {
        let boundingBox = BoundingBox(
            minLatitude: 36.0,
            maxLatitude: 38.0,
            minLongitude: -123.0,
            maxLongitude: -121.0
        )
        
        let queryItems = boundingBox.queryItems
        
        #expect(queryItems.count == 4)
        
        let lamin = queryItems.first { $0.name == "lamin" }
        let lamax = queryItems.first { $0.name == "lamax" }
        let lomin = queryItems.first { $0.name == "lomin" }
        let lomax = queryItems.first { $0.name == "lomax" }
        
        #expect(lamin?.value == "36.0")
        #expect(lamax?.value == "38.0")
        #expect(lomin?.value == "-123.0")
        #expect(lomax?.value == "-121.0")
    }
    
    // MARK: - Edge Cases
    
    @Test
    func testAroundNearEquator() {
        let boundingBox = BoundingBox.around(
            latitude: 0.0,
            longitude: 0.0,
            radiusKm: 100
        )
        
        // At equator, 1 degree longitude = 1 degree latitude (roughly)
        let expectedDelta = 100.0 / 111.0
        
        #expect(abs(boundingBox.minLatitude - (-expectedDelta)) < 0.1)
        #expect(abs(boundingBox.maxLatitude - expectedDelta) < 0.1)
        #expect(abs(boundingBox.minLongitude - (-expectedDelta)) < 0.1)
        #expect(abs(boundingBox.maxLongitude - expectedDelta) < 0.1)
    }
    
    @Test
    func testAroundNearNorthPole() {
        let boundingBox = BoundingBox.around(
            latitude: 80.0,
            longitude: 0.0,
            radiusKm: 100
        )
        
        // At 80 degrees latitude, longitude degrees are much narrower
        let latRange = boundingBox.maxLatitude - boundingBox.minLatitude
        let lonRange = boundingBox.maxLongitude - boundingBox.minLongitude
        
        // Latitude range should be ~1.8 degrees
        #expect(latRange > 1.5)
        #expect(latRange < 2.5)
        
        // Longitude range should be larger due to convergence
        #expect(lonRange > latRange)
    }
    
    @Test
    func testAroundNearDateLine() {
        let boundingBox = BoundingBox.around(
            latitude: 0.0,
            longitude: 179.0,
            radiusKm: 100
        )
        
        // Box should extend past the date line
        #expect(boundingBox.minLongitude < 179.0)
        #expect(boundingBox.maxLongitude > 179.0)
    }
}
