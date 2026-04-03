import Foundation
import CoreLocation
#if canImport(AppKit)
import AppKit
#endif

/// Observable service for location updates
@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        #if os(macOS)
        authorizationStatus = CLLocationManager.authorizationStatus()
        #else
        authorizationStatus = locationManager.authorizationStatus
        #endif
    }
    
    /// Request location permission
    func requestPermission() {
        #if os(macOS)
        locationManager.requestAlwaysAuthorization()
        #else
        locationManager.requestWhenInUseAuthorization()
        #endif
    }
    
    /// Start updating location
    func startUpdating() {
        #if os(macOS)
        let isAuthorized = authorizationStatus == .authorizedAlways
        #else
        let isAuthorized = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #endif
        
        guard isAuthorized else {
            requestPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    /// Stop updating location
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Default location (San Francisco) when real location unavailable
    static let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.currentLocation = locations.last
            self.locationError = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            #if os(macOS)
            self.authorizationStatus = CLLocationManager.authorizationStatus()
            if self.authorizationStatus == .authorizedAlways {
                self.startUpdating()
            }
            #else
            self.authorizationStatus = manager.authorizationStatus
            if self.authorizationStatus == .authorizedWhenInUse ||
               self.authorizationStatus == .authorizedAlways {
                self.startUpdating()
            }
            #endif
        }
    }
}

/// Extension for checking if location services are available
extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        #if os(macOS)
        return self == .authorizedAlways
        #else
        return self == .authorizedWhenInUse || self == .authorizedAlways
        #endif
    }
    
    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }
}
