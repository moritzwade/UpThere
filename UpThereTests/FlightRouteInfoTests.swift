import Foundation
import Testing

@testable import UpThere

struct FlightRouteInfoTests {
    
    // MARK: - Parsing Tests
    
    @Test
    func testParseValidRouteResponse() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)
        
        #expect(routeInfo != nil)
        #expect(routeInfo?.airlineName == "United Airlines")
        #expect(routeInfo?.airlineIata == "UA")
        #expect(routeInfo?.airlineIcao == "UAL")
        #expect(routeInfo?.departureAirportIata == "LAX")
        #expect(routeInfo?.departureAirportIcao == "KLAX")
        #expect(routeInfo?.departureAirportName == "Los Angeles International")
        #expect(routeInfo?.arrivalAirportIata == "BOS")
        #expect(routeInfo?.arrivalAirportIcao == "KBOS")
        #expect(routeInfo?.arrivalAirportName == "Logan International")
        #expect(routeInfo?.flightStatus == "active")
    }
    
    @Test
    func testParsePartialRouteResponse() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)
        
        #expect(routeInfo != nil)
        #expect(routeInfo?.airlineName == nil)
        #expect(routeInfo?.airlineIata == nil)
        #expect(routeInfo?.airlineIcao == nil)
        #expect(routeInfo?.departureAirportIata == "FRA")
        #expect(routeInfo?.arrivalAirportIata == "JFK")
        #expect(routeInfo?.flightStatus == "landed")
    }
    
    @Test
    func testParseNoDataResponse() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.noDataResponse)
        
        #expect(routeInfo == nil)
    }
    
    @Test
    func testParseInvalidJSON() throws {
        #expect(throws: Error.self) {
            try FlightRouteInfo.parse(from: RouteTestData.invalidJSON)
        }
    }
    
    @Test
    func testParseMissingDataKey() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.missingDataKey)
        
        #expect(routeInfo == nil)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test
    func testLogoURLWithValidIata() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)!
        
        #expect(routeInfo.logoURL != nil)
        #expect(routeInfo.logoURL?.absoluteString == "https://images.kiwi.com/airlines/64/UA.png")
    }
    
    @Test
    func testLogoURLWithNoIata() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)!
        
        #expect(routeInfo.logoURL == nil)
    }
    
    @Test
    func testFormattedRoute() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)!
        
        #expect(routeInfo.formattedRoute == "LAX → BOS")
    }
    
    @Test
    func testFormattedRouteWithNoData() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)!
        
        #expect(routeInfo.formattedRoute == "FRA → JFK")
    }
    
    @Test
    func testFormattedAirline() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)!
        
        #expect(routeInfo.formattedAirline == "United Airlines (UAL)")
    }
    
    @Test
    func testFormattedAirlineWithNoData() throws {
        let routeInfo = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)!
        
        #expect(routeInfo.formattedAirline == nil)
    }
    
    @Test
    func testHasRouteData() throws {
        let fullRoute = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)!
        #expect(fullRoute.hasRouteData == true)
        
        let partialRoute = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)!
        #expect(partialRoute.hasRouteData == true)
    }
    
    // MARK: - Display Helpers Tests
    
    @Test
    func testDisplayStatus() throws {
        let activeRoute = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)!
        #expect(activeRoute.displayStatus == "En Route")
        
        let landedRoute = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)!
        #expect(landedRoute.displayStatus == "Landed")
    }
    
    @Test
    func testStatusColor() throws {
        let activeRoute = try FlightRouteInfo.parse(from: RouteTestData.validRouteResponse)!
        #expect(activeRoute.statusColor == "green")
        
        let landedRoute = try FlightRouteInfo.parse(from: RouteTestData.partialRouteResponse)!
        #expect(landedRoute.statusColor == "blue")
    }
}
