import Foundation
import Observation
import MapKit
import SwiftUI

// MARK: - Refresh Interval Options

/// User-selectable refresh interval presets
enum RefreshIntervalOption: String, CaseIterable, Identifiable {
    case often
    case medium
    case seldom
    case manual
    case custom

    var id: String { rawValue }

    /// The fixed interval in seconds for preset options, or nil for manual/custom
    var presetSeconds: TimeInterval? {
        switch self {
        case .often: 5
        case .medium: 30
        case .seldom: 60
        case .manual: nil
        case .custom: nil
        }
    }

    /// Display label shown in the settings picker
    var displayName: String {
        switch self {
        case .often: "Often (5 s)"
        case .medium: "Medium (30 s)"
        case .seldom: "Seldom (60 s)"
        case .manual: "Manual"
        case .custom: "Custom"
        }
    }
}

// MARK: - Map Style

/// Map display style options
enum AppMapStyle: String, CaseIterable, Identifiable {
    case standard
    case satellite
    case hybrid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .satellite: "Satellite"
        case .hybrid: "Hybrid"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard: .standard
        case .satellite: .imagery
        case .hybrid: .hybrid
        }
    }
}

// MARK: - Search Radius Options

/// Search radius options in kilometers
enum SearchRadius: Double, CaseIterable, Identifiable {
    case fifty = 50
    case oneHundred = 100
    case twoHundred = 200
    case fiveHundred = 500

    var id: Double { rawValue }

    var displayName: String {
        switch self {
        case .fifty: "50 km"
        case .oneHundred: "100 km"
        case .twoHundred: "200 km"
        case .fiveHundred: "500 km"
        }
    }
}

// MARK: - AppSettings

/// Application-wide settings persisted via UserDefaults
@Observable
@MainActor
final class AppSettings {

    // MARK: - Shared Instance

    static let shared = AppSettings()

    // MARK: - Public Properties

    var searchRadius: SearchRadius {
        didSet {
            UserDefaults.standard.set(self.searchRadius.rawValue, forKey: Keys.searchRadius)
            AppLogger.viewModel.debug("Settings: search radius changed to \(self.searchRadius.displayName, privacy: .public)")
        }
    }

    var refreshOption: RefreshIntervalOption {
        didSet {
            UserDefaults.standard.set(self.refreshOption.rawValue, forKey: Keys.refreshOption)
            AppLogger.viewModel.debug("Settings: refresh option changed to \(self.refreshOption.displayName, privacy: .public)")
        }
    }

    var customRefreshSeconds: Double {
        didSet {
            UserDefaults.standard.set(self.customRefreshSeconds, forKey: Keys.customRefreshSeconds)
        }
    }

    var mapStyle: AppMapStyle {
        didSet {
            UserDefaults.standard.set(self.mapStyle.rawValue, forKey: Keys.mapStyle)
            AppLogger.viewModel.debug("Settings: map style changed to \(self.mapStyle.displayName, privacy: .public)")
        }
    }

    var customClientId: String {
        didSet {
            UserDefaults.standard.set(self.customClientId, forKey: Keys.customClientId)
        }
    }

    var customClientSecret: String {
        didSet {
            UserDefaults.standard.set(self.customClientSecret, forKey: Keys.customClientSecret)
        }
    }

    // MARK: - Computed Helpers

    /// The effective refresh interval, or nil when in manual mode
    var effectiveRefreshInterval: TimeInterval? {
        switch refreshOption {
        case .manual:
            return nil
        case .custom:
            return max(customRefreshSeconds, 1)
        case .often, .medium, .seldom:
            return refreshOption.presetSeconds
        }
    }

    /// Whether custom API credentials are configured in settings
    var hasCustomCredentials: Bool {
        !customClientId.isEmpty && !customClientSecret.isEmpty
    }

    // MARK: - Private

    private enum Keys {
        static let searchRadius = "upthere.searchRadius"
        static let refreshOption = "upthere.refreshOption"
        static let customRefreshSeconds = "upthere.customRefreshSeconds"
        static let mapStyle = "upthere.mapStyle"
        static let customClientId = "upthere.customClientId"
        static let customClientSecret = "upthere.customClientSecret"
    }

    /// Internal initializer for testing; reads from UserDefaults
    init() {
        let storedRadius = UserDefaults.standard.double(forKey: Keys.searchRadius)
        self.searchRadius = SearchRadius(rawValue: storedRadius) ?? .twoHundred

        if let raw = UserDefaults.standard.string(forKey: Keys.refreshOption),
           let option = RefreshIntervalOption(rawValue: raw) {
            self.refreshOption = option
        } else {
            self.refreshOption = .often
        }

        let storedCustomSeconds = UserDefaults.standard.double(forKey: Keys.customRefreshSeconds)
        self.customRefreshSeconds = storedCustomSeconds > 0 ? storedCustomSeconds : 10

        if let raw = UserDefaults.standard.string(forKey: Keys.mapStyle),
           let style = AppMapStyle(rawValue: raw) {
            self.mapStyle = style
        } else {
            self.mapStyle = .standard
        }

        self.customClientId = UserDefaults.standard.string(forKey: Keys.customClientId) ?? ""
        self.customClientSecret = UserDefaults.standard.string(forKey: Keys.customClientSecret) ?? ""
    }

    // MARK: - Test Helpers

    /// Private initializer that bypasses UserDefaults (for testing)
    private init(customClientId: String, customClientSecret: String) {
        self.searchRadius = .twoHundred
        self.refreshOption = .often
        self.customRefreshSeconds = 10
        self.mapStyle = .standard
        self.customClientId = customClientId
        self.customClientSecret = customClientSecret
    }

    /// Create a test instance with a given OpenSkyConfig (bypasses UserDefaults)
    static func testConfig(_ config: OpenSkyConfig) -> AppSettings {
        AppSettings(
            customClientId: config.clientId ?? "",
            customClientSecret: config.clientSecret ?? ""
        )
    }
}
