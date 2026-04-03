import Foundation

/// Configuration for the OpenSky Network API
/// Sign up at: https://opensky-network.org/
struct OpenSkyConfig {
    /// OpenSky username (required for authenticated requests)
    let username: String?
    
    /// OpenSky password (required for authenticated requests)
    let password: String?
    
    /// Base URL for the OpenSky API
    let baseURL: String = "https://opensky-network.org/api"
    
    /// Whether credentials are configured
    var isConfigured: Bool {
        guard let username = username, !username.isEmpty,
              let password = password, !password.isEmpty else {
            return false
        }
        return true
    }
    
    /// Default configuration from environment variables
    static let `default` = OpenSkyConfig(
        username: ProcessInfo.processInfo.environment["OPENSKY_USERNAME"],
        password: ProcessInfo.processInfo.environment["OPENSKY_PASSWORD"]
    )
    
    /// Create a configuration with specific credentials
    init(username: String?, password: String?) {
        self.username = username
        self.password = password
    }
}
