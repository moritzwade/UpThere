import Foundation
import Testing

@testable import UpThere

@MainActor
struct AppSettingsTests {

    // MARK: - Defaults

    @Test
    func testDefaultSearchRadius() {
        let settings = AppSettings()
        #expect(settings.searchRadius == .twoHundred)
    }

    @Test
    func testDefaultRefreshOption() {
        let settings = AppSettings()
        #expect(settings.refreshOption == .often)
    }

    @Test
    func testDefaultMapStyle() {
        let settings = AppSettings()
        #expect(settings.mapStyle == .standard)
    }

    @Test
    func testDefaultCredentialsEmpty() {
        let settings = AppSettings()
        #expect(settings.customClientId.isEmpty)
        #expect(settings.customClientSecret.isEmpty)
        #expect(!settings.hasCustomCredentials)
    }

    // MARK: - Effective Refresh Interval

    @Test
    func testEffectiveRefreshInterval_presets() {
        let settings = AppSettings()

        settings.refreshOption = .often
        #expect(settings.effectiveRefreshInterval == 5)

        settings.refreshOption = .medium
        #expect(settings.effectiveRefreshInterval == 30)

        settings.refreshOption = .seldom
        #expect(settings.effectiveRefreshInterval == 60)
    }

    @Test
    func testEffectiveRefreshInterval_manual() {
        let settings = AppSettings()
        settings.refreshOption = .manual
        #expect(settings.effectiveRefreshInterval == nil)
    }

    @Test
    func testEffectiveRefreshInterval_custom() {
        let settings = AppSettings()
        settings.refreshOption = .custom
        settings.customRefreshSeconds = 15
        #expect(settings.effectiveRefreshInterval == 15)
    }

    @Test
    func testEffectiveRefreshInterval_custom_minimum() {
        let settings = AppSettings()
        settings.refreshOption = .custom
        settings.customRefreshSeconds = 0.5
        #expect(settings.effectiveRefreshInterval == 1)
    }

    // MARK: - Persistence

    @Test
    func testSearchRadiusPersistence() {
        let settings = AppSettings()
        settings.searchRadius = .fiveHundred
        #expect(settings.searchRadius == .fiveHundred)

        let fresh = AppSettings()
        #expect(fresh.searchRadius == .fiveHundred)

        UserDefaults.standard.removeObject(forKey: "upthere.searchRadius")
    }

    @Test
    func testRefreshOptionPersistence() {
        let settings = AppSettings()
        settings.refreshOption = .seldom
        #expect(settings.refreshOption == .seldom)

        let fresh = AppSettings()
        #expect(fresh.refreshOption == .seldom)

        UserDefaults.standard.removeObject(forKey: "upthere.refreshOption")
    }

    @Test
    func testMapStylePersistence() {
        let settings = AppSettings()
        settings.mapStyle = .hybrid
        #expect(settings.mapStyle == .hybrid)

        let fresh = AppSettings()
        #expect(fresh.mapStyle == .hybrid)

        UserDefaults.standard.removeObject(forKey: "upthere.mapStyle")
    }

    @Test
    func testCredentialsPersistence() {
        let settings = AppSettings()
        settings.customClientId = "my-id"
        settings.customClientSecret = "my-secret"
        #expect(settings.hasCustomCredentials)

        let fresh = AppSettings()
        #expect(fresh.customClientId == "my-id")
        #expect(fresh.customClientSecret == "my-secret")
        #expect(fresh.hasCustomCredentials)

        UserDefaults.standard.removeObject(forKey: "upthere.customClientId")
        UserDefaults.standard.removeObject(forKey: "upthere.customClientSecret")
    }

    // MARK: - Enum Cases

    @Test
    func testSearchRadiusCases() {
        #expect(SearchRadius.allCases.count == 4)
        #expect(SearchRadius.fifty.displayName == "50 km")
        #expect(SearchRadius.oneHundred.displayName == "100 km")
        #expect(SearchRadius.twoHundred.displayName == "200 km")
        #expect(SearchRadius.fiveHundred.displayName == "500 km")
    }

    @Test
    func testRefreshIntervalOptionCases() {
        #expect(RefreshIntervalOption.allCases.count == 5)
        #expect(RefreshIntervalOption.often.presetSeconds == 5)
        #expect(RefreshIntervalOption.medium.presetSeconds == 30)
        #expect(RefreshIntervalOption.seldom.presetSeconds == 60)
        #expect(RefreshIntervalOption.manual.presetSeconds == nil)
        #expect(RefreshIntervalOption.custom.presetSeconds == nil)
    }

    @Test
    func testAppMapStyleCases() {
        #expect(AppMapStyle.allCases.count == 3)
        #expect(AppMapStyle.standard.displayName == "Standard")
        #expect(AppMapStyle.satellite.displayName == "Satellite")
        #expect(AppMapStyle.hybrid.displayName == "Hybrid")
    }
}
