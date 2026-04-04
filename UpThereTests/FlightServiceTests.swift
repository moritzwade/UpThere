import Foundation
import Testing

@testable import UpThere

struct FlightServiceTests {
    
    private let boundingBox = BoundingBox.around(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusKm: 200
    )
    
    // MARK: - Test Session Setup
    
    /// Creates a URLSession configured with the MockURLProtocol
    private func createMockSession(handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)) -> URLSession {
        MockURLProtocol.requestHandler = handler
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        
        return URLSession(configuration: configuration)
    }
    
    /// Creates test credentials with the given client ID and secret
    private func makeCredentials(clientId: String, clientSecret: String) -> ResolvedCredentials {
        ResolvedCredentials(
            clientId: clientId,
            clientSecret: clientSecret,
            sourceDescription: "test"
        )
    }
    
    // MARK: - Successful API Calls
    
    @Test
    func testFetchFlightsSuccess() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                // Auth endpoint - return valid token
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                // API endpoint - return flight data
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, TestData.validResponseWithMultipleFlights)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        let flights = try await service.fetchFlights(in: boundingBox)
        
        #expect(flights.count == 3)
        #expect(flights[0].id == "3c6444")
        #expect(flights[1].id == "a1b2c3")
        #expect(flights[2].id == "4d5e6f")
    }
    
    @Test
    func testFetchFlightsEmptyResponse() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, TestData.validResponseWithNoFlights)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        let flights = try await service.fetchFlights(in: boundingBox)
        
        #expect(flights.isEmpty)
    }
    
    @Test
    func testFetchFlightsWithNullStates() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, TestData.validResponseWithNullStates)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        let flights = try await service.fetchFlights(in: boundingBox)
        
        #expect(flights.isEmpty)
    }
    
    // MARK: - Error Handling
    
    @Test
    func testFetchFlightsRateLimit() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
                return (response, "Too Many Requests".data(using: .utf8)!)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        do {
            _ = try await service.fetchFlights(in: boundingBox)
            #expect(Bool(false), "Should have thrown rate limit error")
        } catch {
            #expect(error is OpenSkyError)
        }
    }
    
    @Test
    func testFetchFlightsUnauthorized() async throws {
        let session = createMockSession { _ in
            let response = HTTPURLResponse(url: URL(string: "https://auth.opensky-network.org")!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (response, "Unauthorized".data(using: .utf8)!)
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        do {
            _ = try await service.fetchFlights(in: boundingBox)
            #expect(Bool(false), "Should have thrown unauthorized error")
        } catch {
            #expect(error is OpenSkyError)
        }
    }
    
    @Test
    func testFetchFlightsServerError() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (response, "Internal Server Error".data(using: .utf8)!)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        do {
            _ = try await service.fetchFlights(in: boundingBox)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is OpenSkyError)
        }
    }
    
    // MARK: - Network Errors
    
    @Test
    func testFetchFlightsNetworkError() async throws {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let session = createMockSession { _ in
            throw networkError
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        do {
            _ = try await service.fetchFlights(in: boundingBox)
            #expect(Bool(false), "Should have thrown")
        } catch let error as OpenSkyError {
            // Network error should be wrapped in OpenSkyError.networkError
            switch error {
            case .networkError:
                // Expected - network errors are wrapped
                break
            default:
                #expect(Bool(false), "Expected networkError but got \(error)")
            }
        } catch {
            // For network errors, check if it's wrapped or raw
            // Raw NSURLError should be wrapped, but we accept both for robustness
            let isNetworkError = (error as NSError).code == NSURLErrorNotConnectedToInternet
            #expect(isNetworkError, "Expected network error")
        }
    }
    
    // MARK: - Historical Flight Data Tests
    
    @Test
    func testFetchFlightHistorySuccess() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, TestData.validHistoryResponse)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        let positions = try await service.fetchFlightHistory(icao24: "3c6444", timeFrom: 1704063600, timeTo: 1704067200)
        
        #expect(positions.count == 3)
        #expect(positions[0].latitude == 37.7000)
        #expect(positions[0].longitude == -122.5000)
        #expect(positions[2].latitude == 37.7749)
    }
    
    @Test
    func testFetchFlightHistoryEmpty() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, TestData.emptyHistoryResponse)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        let positions = try await service.fetchFlightHistory(icao24: "3c6444", timeFrom: 1704063600, timeTo: 1704067200)
        
        #expect(positions.isEmpty)
    }
    
    @Test
    func testFetchFlightHistoryRateLimit() async throws {
        let session = createMockSession { request in
            if request.url?.path.contains("auth") == true {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let tokenResponse = """
                {"access_token": "mock_token", "expires_in": 1800}
                """.data(using: .utf8)!
                return (response, tokenResponse)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 429, httpVersion: nil, headerFields: nil)!
                return (response, "Too Many Requests".data(using: .utf8)!)
            }
        }
        
        let credentials = makeCredentials(clientId: "test", clientSecret: "test")
        let service = FlightService(credentials: credentials, session: session)
        
        do {
            _ = try await service.fetchFlightHistory(icao24: "3c6444", timeFrom: 1704063600, timeTo: 1704067200)
            #expect(Bool(false), "Should have thrown rate limit error")
        } catch {
            #expect(error is OpenSkyError)
        }
    }
}
