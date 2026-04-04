import Foundation
import Testing

@testable import UpThere

struct AirlineDatabaseTests {
    
    // MARK: - ICAO Lookup Tests
    
    @Test
    func testLookupByIcaoKnownAirline() {
        let info = AirlineDatabase.lookup(icao: "UAL")
        
        #expect(info != nil)
        #expect(info?.name == "United Airlines")
        #expect(info?.iata == "UA")
        #expect(info?.icao == "UAL")
    }
    
    @Test
    func testLookupByIcaoScandinavianAirlines() {
        let info = AirlineDatabase.lookup(icao: "SAS")
        
        #expect(info != nil)
        #expect(info?.name == "Scandinavian Airlines")
        #expect(info?.iata == "SK")
        #expect(info?.icao == "SAS")
    }
    
    @Test
    func testLookupByIcaoCaseInsensitive() {
        let info = AirlineDatabase.lookup(icao: "ual")
        
        #expect(info != nil)
        #expect(info?.name == "United Airlines")
    }
    
    @Test
    func testLookupByIcaoUnknown() {
        let info = AirlineDatabase.lookup(icao: "XXX")
        
        #expect(info == nil)
    }
    
    // MARK: - IATA Lookup Tests
    
    @Test
    func testLookupByIataKnownAirline() {
        let info = AirlineDatabase.lookupIata("UA")
        
        #expect(info != nil)
        #expect(info?.name == "United Airlines")
        #expect(info?.iata == "UA")
        #expect(info?.icao == "UAL")
    }
    
    @Test
    func testLookupByIataScandinavianAirlines() {
        let info = AirlineDatabase.lookupIata("SK")
        
        #expect(info != nil)
        #expect(info?.name == "Scandinavian Airlines")
    }
    
    @Test
    func testLookupByIataCaseInsensitive() {
        let info = AirlineDatabase.lookupIata("ua")
        
        #expect(info != nil)
        #expect(info?.name == "United Airlines")
    }
    
    @Test
    func testLookupByIataUnknown() {
        let info = AirlineDatabase.lookupIata("XX")
        
        #expect(info == nil)
    }
    
    // MARK: - Coverage Tests
    
    @Test
    func testMajorAirlinesPresent() {
        // Verify key airlines are in the database
        #expect(AirlineDatabase.lookup(icao: "AAL")?.name == "American Airlines")
        #expect(AirlineDatabase.lookup(icao: "DAL")?.name == "Delta Air Lines")
        #expect(AirlineDatabase.lookup(icao: "BAW")?.name == "British Airways")
        #expect(AirlineDatabase.lookup(icao: "DLH")?.name == "Lufthansa")
        #expect(AirlineDatabase.lookup(icao: "AFR")?.name == "Air France")
        #expect(AirlineDatabase.lookup(icao: "KLM")?.name == "KLM Royal Dutch Airlines")
        #expect(AirlineDatabase.lookup(icao: "UAE")?.name == "Emirates")
        #expect(AirlineDatabase.lookup(icao: "QFA")?.name == "Qantas")
        #expect(AirlineDatabase.lookup(icao: "RYR")?.name == "Ryanair")
        #expect(AirlineDatabase.lookup(icao: "EZY")?.name == "easyJet")
    }
}
