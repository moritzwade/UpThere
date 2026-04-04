import Foundation

/// Test data for AviationStack API responses
enum RouteTestData {
    
    // MARK: - Valid API Responses
    
    /// Valid response with complete route data
    static let validRouteResponse = """
    {
        "data": [{
            "flight_date": "2026-04-04",
            "flight_status": "active",
            "departure": {
                "airport": "Los Angeles International",
                "timezone": "America/Los_Angeles",
                "iata": "LAX",
                "icao": "KLAX",
                "scheduled": "2026-04-04T14:30:00+00:00",
                "estimated": "2026-04-04T14:35:00+00:00"
            },
            "arrival": {
                "airport": "Logan International",
                "timezone": "America/New_York",
                "iata": "BOS",
                "icao": "KBOS",
                "scheduled": "2026-04-04T22:54:00+00:00",
                "estimated": "2026-04-04T23:00:00+00:00"
            },
            "airline": {
                "name": "United Airlines",
                "iata": "UA",
                "icao": "UAL"
            },
            "flight": {
                "number": "1234",
                "iata": "UA1234",
                "icao": "UAL1234"
            }
        }]
    }
    """.data(using: .utf8)!
    
    /// Valid response with partial route data (no airline)
    static let partialRouteResponse = """
    {
        "data": [{
            "flight_date": "2026-04-04",
            "flight_status": "landed",
            "departure": {
                "airport": "Frankfurt Airport",
                "timezone": "Europe/Berlin",
                "iata": "FRA",
                "icao": "EDDF",
                "scheduled": "2026-04-04T08:00:00+00:00"
            },
            "arrival": {
                "airport": "John F. Kennedy International",
                "timezone": "America/New_York",
                "iata": "JFK",
                "icao": "KJFK",
                "scheduled": "2026-04-04T11:30:00+00:00"
            },
            "airline": {
                "name": null,
                "iata": null,
                "icao": null
            },
            "flight": {
                "number": "999",
                "iata": null,
                "icao": "DLH999"
            }
        }]
    }
    """.data(using: .utf8)!
    
    /// Valid response with no data (flight not found)
    static let noDataResponse = """
    {
        "data": []
    }
    """.data(using: .utf8)!
    
    // MARK: - Invalid Responses
    
    /// Invalid JSON
    static let invalidJSON = "not valid json".data(using: .utf8)!
    
    /// Valid JSON but missing data key
    static let missingDataKey = """
    {
        "pagination": {}
    }
    """.data(using: .utf8)!
}
