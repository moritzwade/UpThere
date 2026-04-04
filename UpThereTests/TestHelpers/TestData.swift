import Foundation

/// Sample test data for OpenSky API responses
enum TestData {
    
    // MARK: - Valid API Responses
    
    /// Valid API response with one flight
    static let validResponseWithOneFlight = """
    {
        "time": 1704067200,
        "states": [
            ["3c6444", "UAL1234 ", "United States", 1704067190, 1704067200, -122.4194, 37.7749, 10000.0, false, 250.5, 180.0, 5.0, null, null, "1234", false, 0, 4]
        ]
    }
    """.data(using: .utf8)!
    
    /// Valid API response with multiple flights
    static let validResponseWithMultipleFlights = """
    {
        "time": 1704067200,
        "states": [
            ["3c6444", "UAL1234 ", "United States", 1704067190, 1704067200, -122.4194, 37.7749, 10000.0, false, 250.5, 180.0, 5.0, null, null, "1234", false, 0, 4],
            ["a1b2c3", "DAL567  ", "United States", 1704067195, 1704067200, -122.5000, 37.8000, 8500.0, false, 280.0, 200.0, -2.5, null, null, "5670", false, 0, 3],
            ["4d5e6f", "AAL890  ", "United States", 1704067180, 1704067200, -122.3000, 37.7500, 12000.0, false, 300.0, 90.0, 0.0, null, null, "8901", false, 0, 4]
        ]
    }
    """.data(using: .utf8)!
    
    /// Valid API response with no flights (empty states)
    static let validResponseWithNoFlights = """
    {
        "time": 1704067200,
        "states": []
    }
    """.data(using: .utf8)!
    
    /// Valid API response with null states
    static let validResponseWithNullStates = """
    {
        "time": 1704067200,
        "states": null
    }
    """.data(using: .utf8)!
    
    // MARK: - Flights on Ground
    
    /// Flight that is on the ground
    static let flightOnGround = """
    {
        "time": 1704067200,
        "states": [
            ["abc123", "SWA123 ", "United States", 1704067200, 1704067200, -122.4194, 37.7749, 0.0, true, 0.0, 270.0, 0.0, null, null, "1001", false, 0, 2]
        ]
    }
    """.data(using: .utf8)!
    
    // MARK: - Flights with Missing Data
    
    /// Flight with some null values (partial data)
    static let flightWithPartialData = """
    {
        "time": 1704067200,
        "states": [
            ["def456", "JBU456 ", "United States", null, 1704067200, null, null, null, false, null, null, null, null, null, null, false, 0, 1]
        ]
    }
    """.data(using: .utf8)!
    
    // MARK: - Invalid Responses
    
    /// Invalid JSON
    static let invalidJSON = "not valid json".data(using: .utf8)!
    
    /// Valid JSON but missing required fields
    static let missingRequiredFields = """
    {
        "time": 1704067200
    }
    """.data(using: .utf8)!
    
    /// Valid JSON but wrong time type
    static let wrongTimeType = """
    {
        "time": "1704067200",
        "states": []
    }
    """.data(using: .utf8)!
}
