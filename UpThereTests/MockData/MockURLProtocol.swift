import Foundation

/// Mock URLProtocol for intercepting network requests in tests
class MockURLProtocol: URLProtocol {
    
    /// Request handler for custom responses per test
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept all requests
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let handler = MockURLProtocol.requestHandler {
            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        } else {
            // No handler configured - fail
            let error = NSError(domain: NSURLErrorDomain, code: URLError.badServerResponse.rawValue)
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // No-op for mock
    }
    
    // MARK: - Helper Methods
    
    /// Configure mock for successful API response
    static func configureSuccess(data: Data, statusCode: Int = 200) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
    }
    
    /// Configure mock for error response
    static func configureError(statusCode: Int, data: Data? = nil) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data ?? Data())
        }
    }
    
    /// Configure mock for auth token response
    static func configureAuthSuccess(accessToken: String = "mock_token") {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let tokenResponse = """
            {
                "access_token": "\(accessToken)",
                "expires_in": 1800,
                "token_type": "Bearer"
            }
            """.data(using: .utf8)!
            return (response, tokenResponse)
        }
    }
    
    /// Configure mock for network error
    static func configureNetworkError(_ error: Error) {
        requestHandler = { _ in
            throw error
        }
    }
    
    /// Reset mock configuration
    static func reset() {
        requestHandler = nil
    }
}
