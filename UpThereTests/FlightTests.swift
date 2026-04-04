import Foundation
import Testing

@testable import UpThere

struct FlightTests {
    
    // MARK: - Initialization Tests
    
    @Test
    func testInitFromValidState() {
        let timestamp = Date().timeIntervalSince1970
        let state: [Any] = [
            "3c6444",           // icao24
            "UAL1234 ",         // callsign
            "United States",    // origin_country
            Int(timestamp) - 60, // time_position
            Int(timestamp),      // last_contact
            -122.4194,         // longitude
            37.7749,           // latitude
            10000.0,           // baro_altitude
            false,             // on_ground
            250.5,             // velocity (m/s)
            180.0,             // true_track
            5.0,               // vertical_rate
            NSNull(),          // sensors
            NSNull(),          // geo_altitude
            "1234",            // squawk
            false,             // spi
            0,                 // position_source
            4                  // category
        ]
        
        let flight = Flight(from: state, lastUpdate: Date())
        
        #expect(flight != nil)
        #expect(flight?.id == "3c6444")
        #expect(flight?.callsign == "UAL1234 ")
        #expect(flight?.originCountry == "United States")
        #expect(flight?.longitude == -122.4194)
        #expect(flight?.latitude == 37.7749)
        #expect(flight?.baroAltitude == 10000.0)
        #expect(flight?.onGround == false)
        #expect(flight?.velocity == 250.5)
        #expect(flight?.trueTrack == 180.0)
        #expect(flight?.verticalRate == 5.0)
        #expect(flight?.squawk == "1234")
    }
    
    @Test
    func testInitFromInvalidStateTooFewElements() {
        let state: [Any] = ["3c6444", "UAL1234"]
        
        let flight = Flight(from: state, lastUpdate: Date())
        
        #expect(flight == nil)
    }
    
    @Test
    func testInitFromInvalidStateMissingIcao24() {
        let state: [Any] = [
            NSNull(),          // icao24 (invalid)
            "UAL1234 ",        // callsign
            "United States",   // origin_country
            1704067190,        // time_position
            1704067200,        // last_contact
            -122.4194,        // longitude
            37.7749,          // latitude
            10000.0,          // baro_altitude
            false,            // on_ground
            250.5,            // velocity
            180.0,           // true_track
            5.0,             // vertical_rate
            NSNull(),         // sensors
            NSNull(),         // geo_altitude
            "1234",          // squawk
            false,            // spi
            0                // position_source
        ]
        
        let flight = Flight(from: state, lastUpdate: Date())
        
        #expect(flight == nil)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test
    func testAltitudeFeetConversion() {
        let state = createValidState(baroAltitude: 10000.0)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        // 10000 meters * 3.28084 = 32808.4 feet
        #expect(flight.altitudeFeet != nil)
        #expect(flight.altitudeFeet! == 32808.4)
    }
    
    @Test
    func testAltitudeFeetReturnsNilWhenNoAltitude() {
        let state = createValidState(baroAltitude: nil)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.altitudeFeet == nil)
    }
    
    @Test
    func testSpeedKnotsConversion() {
        let state = createValidState(velocity: 250.5) // m/s
        let flight = Flight(from: state, lastUpdate: Date())!
        
        // 250.5 m/s * 1.94384 = 486.9 knots
        #expect(flight.speedKnots != nil)
        #expect(abs(flight.speedKnots! - 486.9) < 0.1)
    }
    
    @Test
    func testSpeedKnotsReturnsNilWhenNoVelocity() {
        let state = createValidState(velocity: nil)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.speedKnots == nil)
    }
    
    @Test
    func testSpeedKmhConversion() {
        let state = createValidState(velocity: 250.5) // m/s
        let flight = Flight(from: state, lastUpdate: Date())!
        
        // 250.5 m/s * 3.6 = 901.8 km/h
        #expect(flight.speedKmh != nil)
        #expect(abs(flight.speedKmh! - 901.8) < 0.1)
    }
    
    @Test
    func testSpeedKmhReturnsNilWhenNoVelocity() {
        let state = createValidState(velocity: nil)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.speedKmh == nil)
    }
    
    @Test
    func testVerticalRateFPMConversion() {
        let state = createValidState(verticalRate: 5.0) // m/s
        let flight = Flight(from: state, lastUpdate: Date())!
        
        // 5.0 m/s * 196.85 = 984.25 fpm
        #expect(flight.verticalRateFPM != nil)
        #expect(abs(flight.verticalRateFPM! - 984.25) < 0.1)
    }
    
    @Test
    func testFormattedCallsign() {
        let state = createValidState(callsign: "  ual1234  ")
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.formattedCallsign == "UAL1234")
    }
    
    @Test
    func testCoordinateReturnsCLLocationCoordinate2D() {
        let state = createValidState(longitude: -122.4194, latitude: 37.7749)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.coordinate != nil)
        #expect(flight.coordinate!.latitude == 37.7749)
        #expect(flight.coordinate!.longitude == -122.4194)
    }
    
    @Test
    func testCoordinateReturnsNilWhenMissingLatLon() {
        let state = createValidState(longitude: nil, latitude: nil)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.coordinate == nil)
    }
    
    @Test
    func testCoordinateReturnsNilWhenOnlyLatitude() {
        let state = createValidState(longitude: nil, latitude: 37.7749)
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.coordinate == nil)
    }
    
    // MARK: - Airline Designator Tests
    
    @Test
    func testAirlineDesignatorFromValidCallsign() {
        let state = createValidState(callsign: "UAL1234")
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.airlineDesignator == "UAL")
    }
    
    @Test
    func testAirlineDesignatorFromCallsignWithSpaces() {
        let state = createValidState(callsign: "  dal567  ")
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.airlineDesignator == "DAL")
    }
    
    @Test
    func testAirlineDesignatorReturnsNilForShortCallsign() {
        let state = createValidState(callsign: "AB")
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.airlineDesignator == nil)
    }
    
    @Test
    func testAirlineDesignatorReturnsNilForNumericCallsign() {
        let state = createValidState(callsign: "123456")
        let flight = Flight(from: state, lastUpdate: Date())!
        
        #expect(flight.airlineDesignator == nil)
    }
    
    // MARK: - Helper
    
    private func createValidState(
        icao24: String = "3c6444",
        callsign: String = "UAL1234",
        originCountry: String = "United States",
        longitude: Double? = -122.4194,
        latitude: Double? = 37.7749,
        baroAltitude: Double? = 10000.0,
        velocity: Double? = 250.5,
        trueTrack: Double? = 180.0,
        verticalRate: Double? = 5.0
    ) -> [Any] {
        let timestamp = Int(Date().timeIntervalSince1970)
        return [
            icao24,
            callsign,
            originCountry,
            timestamp - 60,
            timestamp,
            longitude as Any,
            latitude as Any,
            baroAltitude as Any,
            false,
            velocity as Any,
            trueTrack as Any,
            verticalRate as Any,
            NSNull(),
            NSNull(),
            "1234",
            false,
            0
        ]
    }
}
