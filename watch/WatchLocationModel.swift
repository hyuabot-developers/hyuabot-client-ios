//
//  WatchLocationModel.swift
//  hyuabot watch
//

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
    @Published private(set) var nearestStopID: String?
    /// True while a measurement is running, including while the permission prompt is up.
    @Published private(set) var isLocating = false
    /// Why the last measurement did not produce a nearest stop. nil after a successful one.
    @Published private(set) var failureReason: WatchFailureReason?

    private let locationManager = CLLocationManager()
    private var resolver = WatchLocationResolver()
    private var deadlineTask: Task<Void, Never>?
    private var lastCheckedAt: Date?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// Starts a measurement unless one is running or a recent result is still fresh.
    func resolve() {
        dispatch(.start(
            auth: Self.map(locationManager.authorizationStatus),
            servicesEnabled: CLLocationManager.locationServicesEnabled(),
            cached: locationManager.location.map(Self.sample),
            now: Date()
        ))
    }

    /// Called when the screen appears or the app becomes active. Re-measures when the last result is old or missing.
    func resumeIfNeeded() {
        if resolver.phase.hasFreshOutcome, let lastCheckedAt,
           Date().timeIntervalSince(lastCheckedAt) < Self.recheckInterval {
            return
        }
        resolve()
    }

    /// Stops a running measurement, e.g. when the app leaves the foreground.
    func cancel() {
        dispatch(.cancel)
    }

    func remember(_ stop: WatchShuttleStop) {
        WatchStopStore.save(stopID: stop.id)
    }

    private func dispatch(_ event: WatchLocationResolver.Event) {
        let before = resolver.phase
        let effects = resolver.handle(event, stops: Self.candidates)
        apply(effects)

        var isStart = false
        if case .start = event { isStart = true }
        let after = resolver.phase
        if after.isTerminal && (after != before || !effects.isEmpty || isStart) {
            publishOutcome()
        }
        isLocating = after == .updating || after == .awaitingAuthorization
    }

    private func apply(_ effects: [WatchLocationResolver.Effect]) {
        for effect in effects {
            switch effect {
            case .requestAuthorization:
                locationManager.requestWhenInUseAuthorization()
            case .startUpdating:
                locationManager.startUpdatingLocation()
            case .stopUpdating:
                locationManager.stopUpdatingLocation()
            case .scheduleDeadline:
                scheduleDeadline()
            case .cancelDeadline:
                deadlineTask?.cancel()
                deadlineTask = nil
            }
        }
    }

    private func scheduleDeadline() {
        deadlineTask?.cancel()
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(for: WatchNearestStopPolicy.timeout)
            guard !Task.isCancelled else { return }
            self?.dispatch(.deadline)
        }
    }

    /// Publishes the finished measurement to the UI and to the App Group.
    /// The manual selection (`watch_recent_stop_id`) is never changed here.
    private func publishOutcome() {
        switch resolver.phase {
        case let .resolved(stopID):
            let now = Date()
            lastCheckedAt = now
            nearestStopID = stopID
            failureReason = nil
            WatchStopStore.saveNearest(stopID: stopID, at: now)
            resolution = .nearest(stopID)
        case let .failed(reason):
            failureReason = reason
            if reason == .noStopNearby {
                lastCheckedAt = Date()
                nearestStopID = nil
                WatchStopStore.clearNearest()
            }
            // Keep the last known nearest stop on other failures. The complication then shows it as stale.
            if resolution == .locating {
                resolveFallback()
            }
        case .idle, .awaitingAuthorization, .updating:
            break
        }
    }

    private func resolveFallback() {
        if let stopID = WatchStopStore.selectedStopID() {
            resolution = .recent(stopID)
        } else {
            resolution = .stopList
        }
    }

    private static let recheckInterval: TimeInterval = 5 * 60

    private static var candidates: [WatchStopCandidate] {
        WatchShuttleStop.all.map { WatchStopCandidate(id: $0.id, latitude: $0.latitude, longitude: $0.longitude) }
    }

    private static func sample(_ location: CLLocation) -> WatchLocationSample {
        WatchLocationSample(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracy: location.horizontalAccuracy,
            timestamp: location.timestamp
        )
    }

    private static func map(_ status: CLAuthorizationStatus) -> WatchLocationResolver.Authorization {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }

    private static func map(_ error: any Error) -> WatchLocationResolver.ErrorKind {
        guard let code = (error as? CLError)?.code else { return .other }
        switch code {
        case .locationUnknown: return .locationUnknown
        case .denied: return .denied
        default: return .other
        }
    }
}

private extension WatchLocationResolver.Phase {
    var isTerminal: Bool {
        switch self {
        case .resolved, .failed: true
        case .idle, .awaitingAuthorization, .updating: false
        }
    }

    /// A finished result that is still valid for the recheck interval: a found stop or a confirmed "no stop nearby".
    var hasFreshOutcome: Bool {
        switch self {
        case .resolved, .failed(.noStopNearby): true
        case .idle, .awaitingAuthorization, .updating, .failed: false
        }
    }
}

extension WatchLocationModel: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let now = Date()
        for location in locations {
            dispatch(.sample(Self.sample(location), now: now))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        dispatch(.error(Self.map(error)))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        dispatch(.authorizationChanged(Self.map(manager.authorizationStatus)))
    }
}
