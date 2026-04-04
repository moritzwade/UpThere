import Foundation
import CoreLocation
import Observation
import os

/// Main ViewModel for flight tracking
@Observable
@MainActor
class UpThereViewModel {
    // MARK: - Published State
    var flights: [Flight] = []
    var selectedFlight: Flight?
    var isLoading = false
    var errorMessage: String?
    var lastUpdateTime: Date?
    
    /// Flight trails keyed by ICAO24
    var trails: [String: FlightTrail] = [:]
    
    /// Complete historical trail for the selected flight (fetched from API)
    var selectedFlightTrail: FlightTrail?
    
    /// Whether we're currently fetching historical data for the selected flight
    var isLoadingTrail = false
    
    /// Route information for the selected flight (from AviationStack)
    var selectedFlightRoute: FlightRouteInfo?
    
    /// Whether we're currently fetching route info for the selected flight
    var isLoadingRoute = false
    
    // MARK: - Services
    private let flightService: FlightService
    private let locationService: LocationService
    private let routeService: FlightRouteService
    private let settings: AppSettings
    
    // MARK: - Configuration
    /// Search radius in kilometers (default 200km)
    var searchRadiusKm: Double = 200
    
    /// Auto-refresh interval in seconds (default 5 seconds)
    var refreshInterval: TimeInterval = 5
    
    /// Current user location
    var userLocation: CLLocation? {
        locationService.currentLocation
    }
    
    /// Authorization status for location
    var locationAuthorized: Bool {
        locationService.authorizationStatus.isAuthorized
    }
    
    /// Location authorization status
    var locationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    // MARK: - Private
    private var refreshTask: Task<Void, Never>?
    private var settingsObserverTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(settings: AppSettings = .shared) {
        self.settings = settings
        let credentials = ResolvedCredentials.resolve(from: settings)
        self.flightService = FlightService(credentials: credentials)
        self.locationService = LocationService()
        self.routeService = FlightRouteService()
    }
    
    // MARK: - Public Methods
    
    /// Start tracking flights
    func startTracking() {
        AppLogger.viewModel.info("Starting flight tracking")
        locationService.startUpdating()
        observeSettingsChanges()
        startAutoRefresh()
        Task {
            await refreshFlights()
        }
    }
    
    /// Stop tracking flights
    func stopTracking() {
        AppLogger.viewModel.info("Stopping flight tracking")
        stopAutoRefresh()
        settingsObserverTask?.cancel()
        settingsObserverTask = nil
        locationService.stopUpdating()
        trails.removeAll()
        selectedFlightTrail = nil
        selectedFlightRoute = nil
    }
    
    /// Manual refresh
    func refreshFlights() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let location = userLocation ?? LocationService.defaultLocation
        if userLocation == nil {
            AppLogger.viewModel.warning("No user location available, using default location")
        }
        
        do {
            let boundingBox = BoundingBox.around(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radiusKm: settings.searchRadius.rawValue
            )
            AppLogger.viewModel.debug("Fetching flights in bounding box")
            
            let newFlights = try await flightService.fetchFlights(in: boundingBox)
            let fetchTime = Date()
            
            // Update trails: add new positions for flights we just received
            updateTrails(with: newFlights, at: fetchTime)
            
            self.flights = newFlights
            lastUpdateTime = fetchTime
            AppLogger.viewModel.debug("Refresh complete: \(self.flights.count, privacy: .public) flights, \(self.trails.count, privacy: .public) trails")
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.viewModel.error("Refresh failed: \(error.localizedDescription, privacy: .public)")
        }
        
        isLoading = false
    }
    
    /// Update trails with new flight positions
    private func updateTrails(with flights: [Flight], at date: Date) {
        // Track which ICAO24s are still active
        let activeIcao24s = Set(flights.map(\.id))
        
        for flight in flights {
            guard let coordinate = flight.coordinate else { continue }
            
            if var trail = trails[flight.id] {
                // Append new position to existing trail
                trail.append(date: date, coordinate: coordinate)
                trails[flight.id] = trail
            } else {
                // Create new trail
                var trail = FlightTrail(icao24: flight.id)
                trail.append(date: date, coordinate: coordinate)
                trails[flight.id] = trail
            }
        }
        
        // Remove trails for flights that are no longer active AND older than max trail age
        let cutoff = date.addingTimeInterval(-FlightTrail.maxTrailAge)
        trails = trails.filter { icao24, trail in
            if activeIcao24s.contains(icao24) { return true }
            return trail.positions.contains { $0.date >= cutoff }
        }
    }
    
    /// Fetch complete historical trail for the selected flight
    func fetchSelectedFlightTrail() async {
        guard let flight = selectedFlight else {
            selectedFlightTrail = nil
            return
        }
        
        isLoadingTrail = true
        AppLogger.viewModel.debug("Fetching complete trail for \(flight.id, privacy: .public)")
        
        do {
            // Fetch last 24 hours of history (OpenSky free tier limit)
            let timeTo = Int(Date().timeIntervalSince1970)
            let timeFrom = timeTo - (24 * 3600) // 24 hours ago
            
            let positions = try await flightService.fetchFlightHistory(
                icao24: flight.id,
                timeFrom: timeFrom,
                timeTo: timeTo
            )
            
            let trailPositions = positions.compactMap { pos -> (date: Date, coordinate: CLLocationCoordinate2D)? in
                guard pos.latitude >= -90 && pos.latitude <= 90,
                      pos.longitude >= -180 && pos.longitude <= 180 else {
                    return nil
                }
                return (
                    date: pos.date,
                    coordinate: CLLocationCoordinate2D(latitude: pos.latitude, longitude: pos.longitude)
                )
            }
            
            var trail = FlightTrail(icao24: flight.id)
            trail.setCompleteHistory(positions: trailPositions)
            selectedFlightTrail = trail
            
            AppLogger.viewModel.debug("Fetched \(trailPositions.count, privacy: .public) positions for selected flight trail")
        } catch {
            AppLogger.viewModel.error("Failed to fetch flight trail: \(error.localizedDescription, privacy: .public)")
            // Fall back to accumulated trail
            if let accumulatedTrail = trails[flight.id] {
                selectedFlightTrail = accumulatedTrail
            }
        }
        
        isLoadingTrail = false
    }
    
    /// Select a flight to show details (toggle: tap same flight to deselect)
    func selectFlight(_ flight: Flight?) {
        if let flight = flight, flight.id == selectedFlight?.id {
            // Tapping the same flight → deselect
            selectedFlight = nil
            selectedFlightTrail = nil
            selectedFlightRoute = nil
            AppLogger.viewModel.debug("Deselected flight \(flight.id, privacy: .public)")
        } else if let flight = flight {
            // Selecting a new flight
            selectedFlight = flight
            selectedFlightRoute = nil
            Task {
                await fetchSelectedFlightTrail()
                await fetchSelectedFlightRoute(flight: flight)
            }
            AppLogger.viewModel.debug("Selected flight \(flight.id, privacy: .public)")
        } else {
            // Deselecting (e.g., tapping empty space)
            selectedFlight = nil
            selectedFlightTrail = nil
            selectedFlightRoute = nil
        }
    }
    
    /// Fetch route information for the selected flight
    private func fetchSelectedFlightRoute(flight: Flight) async {
        isLoadingRoute = true
        AppLogger.viewModel.debug("Fetching route info for \(flight.id, privacy: .public)")
        
        do {
            selectedFlightRoute = try await routeService.fetchRoute(for: flight)
            if selectedFlightRoute != nil {
                AppLogger.viewModel.info("Route info fetched for \(flight.id, privacy: .public)")
            } else {
                AppLogger.viewModel.debug("No route data available for \(flight.id, privacy: .public)")
            }
        } catch {
            AppLogger.viewModel.error("Failed to fetch route info: \(error.localizedDescription, privacy: .public)")
            selectedFlightRoute = nil
        }
        
        isLoadingRoute = false
    }
    
    /// Request location permission
    func requestLocationPermission() {
        locationService.requestPermission()
    }
    
    // MARK: - Private Methods
    
    /// Observe settings changes and react accordingly
    private func observeSettingsChanges() {
        settingsObserverTask?.cancel()
        settingsObserverTask = Task { [weak self] in
            guard let self = self else { return }
            var lastRefreshOption = self.settings.refreshOption
            var lastHasCredentials = self.settings.hasCustomCredentials
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000) // poll every 500ms
                guard !Task.isCancelled else { return }
                
                let currentRefreshOption = self.settings.refreshOption
                let currentHasCredentials = self.settings.hasCustomCredentials
                
                // Restart auto-refresh if interval option changed
                if currentRefreshOption != lastRefreshOption {
                    lastRefreshOption = currentRefreshOption
                    self.startAutoRefresh()
                }
                
                // Update FlightService credentials if they changed
                if currentHasCredentials != lastHasCredentials {
                    lastHasCredentials = currentHasCredentials
                    let credentials = ResolvedCredentials.resolve(from: self.settings)
                    await self.flightService.updateCredentials(credentials)
                }
            }
        }
    }
    
    private func startAutoRefresh() {
        stopAutoRefresh()
        
        // Manual mode: no auto-refresh
        guard let interval = settings.effectiveRefreshInterval else {
            AppLogger.viewModel.info("Auto-refresh disabled (manual mode)")
            return
        }
        
        refreshTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                if !Task.isCancelled {
                    await self.refreshFlights()
                }
            }
        }
        AppLogger.viewModel.debug("Auto-refresh started with interval: \(interval, privacy: .public)s")
    }
    
    private func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

// MARK: - Flight Distance Helpers

extension Flight {
    /// Calculate distance from a reference location
    func distance(from location: CLLocation) -> CLLocationDistance? {
        guard let coord = coordinate else { return nil }
        let flightLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return location.distance(from: flightLocation)
    }
    
    /// Distance in kilometers
    func distanceKm(from location: CLLocation) -> Double? {
        guard let distance = distance(from: location) else { return nil }
        return distance / 1000
    }
}
