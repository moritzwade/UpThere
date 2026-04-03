import Foundation

/// Configuration for the OpenSky Network API
/// Sign up at: https://opensky-network.org/
struct OpenSkyConfig {
    /// OpenSky client ID (from Account page)
    let clientId: String?
    
    /// OpenSky client secret (from Account page)
    let clientSecret: String?
    
    /// Base URL for the OpenSky API
    let baseURL: String = "https://opensky-network.org/api"
    
    /// Auth URL for OAuth2 token
    let authURL: String = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"
    
    /// Whether credentials are configured
    var isConfigured: Bool {
        guard let clientId = clientId, !clientId.isEmpty,
              let clientSecret = clientSecret, !clientSecret.isEmpty else {
            return false
        }
        return true
    }
    
    /// Default configuration from environment variables
    static let `default` = OpenSkyConfig(
        clientId: ProcessInfo.processInfo.environment["OPENSKY_CLIENT_ID"],
        clientSecret: ProcessInfo.processInfo.environment["OPENSKY_CLIENT_SECRET"]
    )
    
    /// Create a configuration with specific credentials
    init(clientId: String?, clientSecret: String?) {
        self.clientId = clientId
        self.clientSecret = clientSecret
    }
}
