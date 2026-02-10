import Foundation
import CoreLocation

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published public var location: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus?
    @Published public var cityName: String?
    @Published public var statusMessage: String = "Initializing..."

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 100 // Avoid too many updates
        // Request permission immediately on launch
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation() 
        statusMessage = "Started updates..."
    }
    
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first, error == nil else {
                return
            }
            // Prioritize Locality (City), then AdministrativeArea (State), then Country
            self.cityName = placemark.locality ?? placemark.administrativeArea ?? placemark.country
        }
    }

    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func start() {
        manager.startUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.location = loc
        self.statusMessage = "Location received"
        // specific optimization removed to ensure reliability
        reverseGeocode(location: loc)
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        let isAuthorized: Bool
        #if os(macOS)
        isAuthorized = (manager.authorizationStatus == .authorizedAlways)
        #else
        isAuthorized = (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways)
        #endif
        
        if isAuthorized {
            statusMessage = "Authorized. Updating..."
            manager.startUpdatingLocation()
        } else {
            statusMessage = "Auth Status: \(manager.authorizationStatus.rawValue)"
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        statusMessage = "Error: \(error.localizedDescription)"
    }
}
