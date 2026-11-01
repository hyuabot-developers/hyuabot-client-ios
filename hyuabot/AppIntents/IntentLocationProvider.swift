//
//  IntentLocationProvider.swift
//  hyuabot
//

import CoreLocation
import Foundation

enum IntentLocationResult: Equatable {
    case coordinate(ShuttleGeoCoordinate)
    case notAuthorized
    case unavailable
}

@MainActor
final class IntentLocationProvider: NSObject {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<IntentLocationResult, Never>?

    static func currentLocation(timeout: TimeInterval = 4) async -> IntentLocationResult {
        let provider = IntentLocationProvider()
        return await provider.requestOnce(timeout: timeout)
    }

    private func requestOnce(timeout: TimeInterval) async -> IntentLocationResult {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        default:
            return .notAuthorized
        }

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(timeout))
                self?.finish(.unavailable)
            }
        }
    }

    private func finish(_ result: IntentLocationResult) {
        guard let continuation else { return }
        self.continuation = nil
        manager.delegate = nil
        continuation.resume(returning: result)
    }
}

extension IntentLocationProvider: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(.unavailable)
            return
        }
        finish(.coordinate(ShuttleGeoCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        finish(.unavailable)
    }
}
