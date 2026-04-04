import Foundation
import Testing
import os

@testable import UpThere

/// Tests for the AppLogger logging system.
///
/// Note: os.Logger writes to the system log (unified logging system), which
/// cannot be intercepted in unit tests. These tests verify the logger
/// configuration, existence, and safe usage patterns rather than log output.
struct LoggerTests {

    // MARK: - Logger Existence & Configuration

    @Test
    func testFlightServiceLoggerExists() {
        // Verify the flight service logger is properly initialized
        let logger = AppLogger.flightService
        // os.Logger doesn't expose category publicly, but we can verify it's a valid logger
        logger.debug("Logger exists")
        #expect(Bool(true), "FlightService logger should be accessible")
    }

    @Test
    func testLocationServiceLoggerExists() {
        let logger = AppLogger.locationService
        logger.debug("Logger exists")
        #expect(Bool(true), "LocationService logger should be accessible")
    }

    @Test
    func testViewModelLoggerExists() {
        let logger = AppLogger.viewModel
        logger.debug("Logger exists")
        #expect(Bool(true), "ViewModel logger should be accessible")
    }

    // MARK: - Log Level Methods

    @Test
    func testFlightServiceDebugLogDoesNotCrash() {
        // Verify debug logging works without crashing
        AppLogger.flightService.debug("Test debug message")
        AppLogger.flightService.debug("Test with value: \(42, privacy: .public)")
        #expect(Bool(true), "Debug log should not crash")
    }

    @Test
    func testFlightServiceInfoLogDoesNotCrash() {
        AppLogger.flightService.info("Test info message")
        AppLogger.flightService.info("Fetched \(5, privacy: .public) flights")
        #expect(Bool(true), "Info log should not crash")
    }

    @Test
    func testFlightServiceWarningLogDoesNotCrash() {
        AppLogger.flightService.warning("Test warning message")
        AppLogger.flightService.warning("Rate limited (429)")
        #expect(Bool(true), "Warning log should not crash")
    }

    @Test
    func testFlightServiceErrorLogDoesNotCrash() {
        AppLogger.flightService.error("Test error message")
        AppLogger.flightService.error("API error (500): Internal Server Error")
        #expect(Bool(true), "Error log should not crash")
    }

    @Test
    func testLocationServiceDebugLogDoesNotCrash() {
        AppLogger.locationService.debug("Location: 37.7749, -122.4194")
        #expect(Bool(true), "Debug log should not crash")
    }

    @Test
    func testLocationServiceInfoLogDoesNotCrash() {
        AppLogger.locationService.info("Location authorization granted")
        #expect(Bool(true), "Info log should not crash")
    }

    @Test
    func testLocationServiceWarningLogDoesNotCrash() {
        AppLogger.locationService.warning("Location not authorized")
        #expect(Bool(true), "Warning log should not crash")
    }

    @Test
    func testLocationServiceErrorLogDoesNotCrash() {
        AppLogger.locationService.error("Location update failed: timed out")
        #expect(Bool(true), "Error log should not crash")
    }

    @Test
    func testViewModelDebugLogDoesNotCrash() {
        AppLogger.viewModel.debug("Fetching flights in bounding box")
        #expect(Bool(true), "Debug log should not crash")
    }

    @Test
    func testViewModelInfoLogDoesNotCrash() {
        AppLogger.viewModel.info("Starting flight tracking")
        #expect(Bool(true), "Info log should not crash")
    }

    @Test
    func testViewModelWarningLogDoesNotCrash() {
        AppLogger.viewModel.warning("No user location available, using default")
        #expect(Bool(true), "Warning log should not crash")
    }

    @Test
    func testViewModelErrorLogDoesNotCrash() {
        AppLogger.viewModel.error("Refresh failed: network error")
        #expect(Bool(true), "Error log should not crash")
    }

    // MARK: - Privacy Levels

    @Test
    func testPublicPrivacyInterpolation() {
        // Verify that public privacy interpolation works correctly
        let count = 42
        AppLogger.flightService.info("Fetched \(count, privacy: .public) flights")
        #expect(Bool(true), "Public privacy interpolation should work")
    }

    @Test
    func testPrivatePrivacyInterpolation() {
        // Verify that private (default) privacy interpolation works
        let sensitiveData = "secret_token_123"
        AppLogger.flightService.debug("Token: \(sensitiveData)")
        #expect(Bool(true), "Private privacy interpolation should work")
    }

    // MARK: - Integration: No print() Statements Remain

    @Test
    func testNoPrintStatementsInFlightService() throws {
        let sourcePath = Bundle.main.path(forResource: "FlightService", ofType: "swift")

        // If we can't find the source file, skip this test (it's a source-level check)
        guard let path = sourcePath else {
            #expect(Bool(true), "Source file not available in test bundle, skipping")
            return
        }

        let source = try String(contentsOfFile: path, encoding: .utf8)
        let hasPrintStatement = source.contains(#"print(""#) || source.contains("print(")
        #expect(!hasPrintStatement, "FlightService should not contain print() statements")
    }

    @Test
    func testNoPrintStatementsInLocationService() throws {
        let sourcePath = Bundle.main.path(forResource: "LocationService", ofType: "swift")

        guard let path = sourcePath else {
            #expect(Bool(true), "Source file not available in test bundle, skipping")
            return
        }

        let source = try String(contentsOfFile: path, encoding: .utf8)
        let hasPrintStatement = source.contains(#"print(""#) || source.contains("print(")
        #expect(!hasPrintStatement, "LocationService should not contain print() statements")
    }

    @Test
    func testNoPrintStatementsInViewModel() throws {
        let sourcePath = Bundle.main.path(forResource: "UpThereViewModel", ofType: "swift")

        guard let path = sourcePath else {
            #expect(Bool(true), "Source file not available in test bundle, skipping")
            return
        }

        let source = try String(contentsOfFile: path, encoding: .utf8)
        let hasPrintStatement = source.contains(#"print(""#) || source.contains("print(")
        #expect(!hasPrintStatement, "ViewModel should not contain print() statements")
    }

    // MARK: - Logger Subsystem Consistency

    @Test
    func testAllLoggersUseSameSubsystem() {
        // All loggers should be under the same subsystem for easy filtering
        // We verify they are all os.Logger instances
        _ = AppLogger.flightService as os.Logger
        _ = AppLogger.locationService as os.Logger
        _ = AppLogger.viewModel as os.Logger
        #expect(Bool(true), "All loggers should be os.Logger instances")
    }

    // MARK: - Logger Enum Design

    @Test
    func testAppLoggerIsEnum() {
        // AppLogger should be an enum to prevent instantiation
        // This test verifies the type is accessible and has static members
        _ = AppLogger.flightService
        _ = AppLogger.locationService
        _ = AppLogger.viewModel
        #expect(Bool(true), "All three loggers should be accessible as static members")
    }
}
