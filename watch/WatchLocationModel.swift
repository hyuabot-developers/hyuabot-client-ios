import Combine
import CoreLocation
import Foundation

@MainActor
final class WatchLocationModel: NSObject, ObservableObject {
    enum Resolution: Equatable {
        case locating
        case nearest(String)
        case recent(String)
        case stopList

        var stopID: String? {
            switch self {
            case let .nearest(stopID), let .recent(stopID): stopID
            case .locating, .stopList: nil
            }
        }
    }

    @Published private(set) var resolution: Resolution = .locating
    private(set) var nearestStopID: String?

    private let locationManager = CLLocationManager()
    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func resolve() {
        guard resolution == .locating else { return }
        guard CLLocationManager.locationServicesEnabled() else {
            resolveFallback()
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            resolveFallback()
        @unknown default:
            resolveFallback()
        }
    }

    func remember(_ stop: WatchShuttleStop) {
        defaults.set(stop.id, forKey: Self.recentStopKey)
    }

    private func resolveFallback() {
        if let stopID = defaults.string(forKey: Self.recentStopKey),
           WatchShuttleStop.all.contains(where: { $0.id == stopID })
        {
            resolution = .recent(stopID)
        } else {
            resolution = .stopList
        }
    }

    private static let recentStopKey = "watch_recent_stop_id"
    private static let maximumAccuracy: CLLocationAccuracy = 500
    private static let maximumStopDistance: CLLocationDistance = 3_000
}

extension WatchLocationModel: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= Self.maximumAccuracy,
              let stop = WatchShuttleStop.all.min(by: {
                  $0.location.distance(from: location) < $1.location.distance(from: location)
              }),
              stop.location.distance(from: location) <= Self.maximumStopDistance else {
            resolveFallback()
            return
        }

        nearestStopID = stop.id
        remember(stop)
        resolution = .nearest(stop.id)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        resolveFallback()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard resolution == .locating else { return }
        resolve()
    }
}
