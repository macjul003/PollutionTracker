import Foundation
import CoreLocation

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var lastGeocodedLocation: CLLocation?

    @Published public var location: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus?
    @Published public var cityName: String?
    @Published public var statusMessage: String = "Initializing..."

    private static let sharedDefaults = UserDefaults(suiteName: "com.macjul003.PollutionTracker.shared")

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 100
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        statusMessage = "Started updates..."
    }

    private func reverseGeocode(location: CLLocation) {
        // Only re-geocode if moved more than 500m from last geocoded location
        if let last = lastGeocodedLocation, last.distance(from: location) < 500 {
            return
        }

        lastGeocodedLocation = location
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self, let placemark = placemarks?.first, error == nil else {
                return
            }
            let name = placemark.locality ?? placemark.administrativeArea ?? placemark.country
            self.cityName = name
            Self.sharedDefaults?.set(name, forKey: "lastCityName")
        }
    }

    private func saveLocationToSharedDefaults(_ location: CLLocation) {
        Self.sharedDefaults?.set(location.coordinate.latitude, forKey: "lastLatitude")
        Self.sharedDefaults?.set(location.coordinate.longitude, forKey: "lastLongitude")
    }

    public static func lastKnownLocation() -> (latitude: Double, longitude: Double, cityName: String?)? {
        guard let defaults = sharedDefaults,
              defaults.object(forKey: "lastLatitude") != nil else {
            return nil
        }
        let lat = defaults.double(forKey: "lastLatitude")
        let lon = defaults.double(forKey: "lastLongitude")
        let city = defaults.string(forKey: "lastCityName")
        return (lat, lon, city)
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
        saveLocationToSharedDefaults(loc)
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
