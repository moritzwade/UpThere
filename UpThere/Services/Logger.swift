import os

/// Centralized logging for the UpThere app.
///
/// All logs use the subsystem `com.moritzwade.upthere` and are categorized
/// by component. View them in Console.app by filtering on the subsystem.
///
/// Usage:
/// ```swift
/// AppLogger.flightService.debug("Building request URL")
/// AppLogger.viewModel.info("Tracking started")
/// AppLogger.locationService.error("Location failed", error: someError)
/// ```
enum AppLogger {
    private static let subsystem = "com.moritzwade.upthere"

    /// Logs for the OpenSky API network layer (FlightService actor)
    static let flightService = os.Logger(subsystem: subsystem, category: "FlightService")

    /// Logs for CoreLocation wrapper (LocationService)
    static let locationService = os.Logger(subsystem: subsystem, category: "LocationService")

    /// Logs for the main view model state machine
    static let viewModel = os.Logger(subsystem: subsystem, category: "ViewModel")
}
