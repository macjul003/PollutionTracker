import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var cityName: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
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

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func start() {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        self.location = loc
        reverseGeocode(location: loc)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        let isAuthorized: Bool
        #if os(macOS)
        isAuthorized = (manager.authorizationStatus == .authorizedAlways)
        #else
        isAuthorized = (manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways)
        #endif
        
        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
