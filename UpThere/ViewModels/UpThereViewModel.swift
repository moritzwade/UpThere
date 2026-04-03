import Foundation
import CoreLocation
import Observation

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
    
    // MARK: - Services
    private let flightService: FlightService
    private let locationService: LocationService
    
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
    
    // MARK: - Initialization
    init() {
        self.flightService = FlightService()
        self.locationService = LocationService()
    }
    
    // MARK: - Public Methods
    
    /// Start tracking flights
    func startTracking() {
        locationService.startUpdating()
        startAutoRefresh()
        Task {
            await refreshFlights()
        }
    }
    
    /// Stop tracking flights
    func stopTracking() {
        stopAutoRefresh()
        locationService.stopUpdating()
    }
    
    /// Manual refresh
    func refreshFlights() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let location = userLocation ?? LocationService.defaultLocation
        
        do {
            let boundingBox = BoundingBox.around(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radiusKm: searchRadiusKm
            )
            
            flights = try await flightService.fetchFlights(in: boundingBox)
            lastUpdateTime = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Select a flight to show details
    func selectFlight(_ flight: Flight?) {
        selectedFlight = flight
    }
    
    /// Request location permission
    func requestLocationPermission() {
        locationService.requestPermission()
    }
    
    // MARK: - Private Methods
    
    private func startAutoRefresh() {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.refreshInterval * 1_000_000_000))
                if !Task.isCancelled {
                    await self.refreshFlights()
                }
            }
        }
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
