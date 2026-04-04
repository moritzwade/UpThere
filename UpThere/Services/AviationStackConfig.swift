import Foundation

/// Configuration for the AviationStack API
/// Sign up at: https://aviationstack.com/
struct AviationStackConfig {
    /// AviationStack API access key
    let apiKey: String?
    
    /// Base URL for the AviationStack API
    let baseURL: String = "https://api.aviationstack.com/v1"
    
    /// Whether the API key is configured
    var isConfigured: Bool {
        guard let apiKey = apiKey, !apiKey.isEmpty else { return false }
        return true
    }
    
    /// Default configuration from environment variables
    static let `default` = AviationStackConfig(
        apiKey: ProcessInfo.processInfo.environment["AVIATIONSTACK_API_KEY"]
    )
    
    /// Create a configuration with a specific API key
    init(apiKey: String?) {
        self.apiKey = apiKey
    }
}
