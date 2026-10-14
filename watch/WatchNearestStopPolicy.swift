//
//  WatchNearestStopPolicy.swift
//  hyuabot watch
//
//  Pure nearest-stop logic. Foundation only, so the iOS unit tests can compile this file directly.
//

import Foundation

struct WatchStopCandidate: Equatable {
    let id: String
    let latitude: Double
    let longitude: Double
}

struct WatchLocationSample: Equatable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double
    let timestamp: Date
}

enum WatchFailureReason: Equatable {
    case denied
    case servicesDisabled
    case timedOut
    case unavailable
    case noStopNearby
}

enum WatchNearestStopPolicy {
    /// A fix at or below this accuracy is decided at once.
    static let immediateAccuracy: Double = 100
    /// At the deadline, the best fix is used only if it is at or below this accuracy.
    static let deadlineAccuracy: Double = 500
    /// If no stop is within this distance, the result is `noStopNearby`.
    static let maximumStopDistance: Double = 3000
    /// Samples older than this are ignored.
    static let maximumAge: TimeInterval = 60
    static let timeout: Duration = .seconds(10)

    enum Decision: Equatable {
        case nearest(String)
        case noStopNearby
        case unusable
    }

    static func isUsable(_ sample: WatchLocationSample, now: Date) -> Bool {
        guard sample.horizontalAccuracy >= 0 else { return false }
        return abs(now.timeIntervalSince(sample.timestamp)) <= maximumAge
    }

    /// Keeps the more accurate sample. Equal accuracy keeps the newer one.
    static func better(_ current: WatchLocationSample?, _ candidate: WatchLocationSample) -> WatchLocationSample {
        guard let current else { return candidate }
        if candidate.horizontalAccuracy < current.horizontalAccuracy {
            return candidate
        }
        if candidate.horizontalAccuracy == current.horizontalAccuracy, candidate.timestamp > current.timestamp {
            return candidate
        }
        return current
    }

    static func decide(_ sample: WatchLocationSample, maxAccuracy: Double, stops: [WatchStopCandidate]) -> Decision {
        guard sample.horizontalAccuracy >= 0, sample.horizontalAccuracy <= maxAccuracy else { return .unusable }
        guard let nearest = stops.min(by: { distance(sample, $0) < distance(sample, $1) }),
              distance(sample, nearest) <= maximumStopDistance
        else {
            return .noStopNearby
        }
        return .nearest(nearest.id)
    }

    /// Great-circle distance in meters (haversine).
    static func distance(_ sample: WatchLocationSample, _ stop: WatchStopCandidate) -> Double {
        let earthRadius = 6_371_000.0
        let lat1 = sample.latitude * .pi / 180
        let lat2 = stop.latitude * .pi / 180
        let dLat = (stop.latitude - sample.latitude) * .pi / 180
        let dLon = (stop.longitude - sample.longitude) * .pi / 180
        let hav = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(hav)))
    }
}

/// State machine for one measurement. Pure: it returns the side effects to run, and the model runs them.
struct WatchLocationResolver {
    enum Phase: Equatable {
        case idle
        case awaitingAuthorization
        case updating
        case resolved(String)
        case failed(WatchFailureReason)
    }

    enum Authorization: Equatable {
        case notDetermined
        case authorized
        case denied
    }

    enum ErrorKind: Equatable {
        case locationUnknown
        case denied
        case other
    }

    enum Event: Equatable {
        case start(auth: Authorization, servicesEnabled: Bool, cached: WatchLocationSample?, now: Date)
        case authorizationChanged(Authorization)
        case sample(WatchLocationSample, now: Date)
        case error(ErrorKind)
        case deadline
        case cancel
    }

    enum Effect: Equatable {
        case requestAuthorization
        case startUpdating
        case stopUpdating
        case scheduleDeadline
        case cancelDeadline
    }

    private(set) var phase: Phase = .idle
    private(set) var best: WatchLocationSample?

    mutating func handle(_ event: Event, stops: [WatchStopCandidate]) -> [Effect] {
        switch event {
        case let .start(auth, servicesEnabled, cached, now):
            start(auth: auth, servicesEnabled: servicesEnabled, cached: cached, now: now, stops: stops)
        case let .authorizationChanged(auth):
            authorizationChanged(auth)
        case let .sample(sample, now):
            receive(sample, now: now, stops: stops)
        case let .error(kind):
            receive(kind, stops: stops)
        case .deadline:
            deadline(stops: stops)
        case .cancel:
            cancel()
        }
    }

    private mutating func start(
        auth: Authorization, servicesEnabled: Bool, cached: WatchLocationSample?, now: Date, stops: [WatchStopCandidate]
    ) -> [Effect] {
        switch phase {
        case .updating, .awaitingAuthorization:
            return []
        case .idle, .resolved, .failed:
            break
        }
        best = nil
        guard servicesEnabled else {
            phase = .failed(.servicesDisabled)
            return []
        }
        switch auth {
        case .denied:
            phase = .failed(.denied)
            return []
        case .notDetermined:
            phase = .awaitingAuthorization
            return [.requestAuthorization]
        case .authorized:
            let cachedIsUsable = cached.map { WatchNearestStopPolicy.isUsable($0, now: now) } == true
            if let cached, cachedIsUsable, cached.horizontalAccuracy <= WatchNearestStopPolicy.immediateAccuracy {
                phase = result(WatchNearestStopPolicy.decide(
                    cached, maxAccuracy: WatchNearestStopPolicy.immediateAccuracy, stops: stops
                ))
                return []
            }
            phase = .updating
            return [.startUpdating, .scheduleDeadline]
        }
    }

    private mutating func authorizationChanged(_ auth: Authorization) -> [Effect] {
        switch (phase, auth) {
        case (.awaitingAuthorization, .authorized):
            best = nil
            phase = .updating
            return [.startUpdating, .scheduleDeadline]
        case (.awaitingAuthorization, .denied):
            phase = .failed(.denied)
            return []
        case (.updating, .denied):
            phase = .failed(.denied)
            return [.stopUpdating, .cancelDeadline]
        default:
            return []
        }
    }

    private mutating func receive(_ sample: WatchLocationSample, now: Date, stops: [WatchStopCandidate]) -> [Effect] {
        guard phase == .updating, WatchNearestStopPolicy.isUsable(sample, now: now) else { return [] }
        best = WatchNearestStopPolicy.better(best, sample)
        guard sample.horizontalAccuracy <= WatchNearestStopPolicy.immediateAccuracy else { return [] }
        return finish(WatchNearestStopPolicy.decide(
            sample, maxAccuracy: WatchNearestStopPolicy.immediateAccuracy, stops: stops
        ))
    }

    private mutating func receive(_ kind: ErrorKind, stops: [WatchStopCandidate]) -> [Effect] {
        guard phase == .updating else { return [] }
        switch kind {
        case .locationUnknown:
            // Transient. Keep waiting for the next fix or the deadline.
            return []
        case .denied:
            phase = .failed(.denied)
            return [.stopUpdating, .cancelDeadline]
        case .other:
            if let effects = settleWithBest(stops: stops) {
                return effects
            }
            phase = .failed(.unavailable)
            return [.stopUpdating, .cancelDeadline]
        }
    }

    private mutating func deadline(stops: [WatchStopCandidate]) -> [Effect] {
        guard phase == .updating else { return [] }
        if let effects = settleWithBest(stops: stops) {
            return effects
        }
        phase = .failed(.timedOut)
        return [.stopUpdating]
    }

    /// Decides from the best fix if it is accurate enough. Returns nil when there is no usable fix.
    private mutating func settleWithBest(stops: [WatchStopCandidate]) -> [Effect]? {
        guard let best, best.horizontalAccuracy <= WatchNearestStopPolicy.deadlineAccuracy else { return nil }
        return finish(WatchNearestStopPolicy.decide(
            best, maxAccuracy: WatchNearestStopPolicy.deadlineAccuracy, stops: stops
        ))
    }

    private mutating func cancel() -> [Effect] {
        // While the permission prompt is up, leave the phase alone. The system answer arrives as an event.
        guard phase == .updating else { return [] }
        phase = .idle
        best = nil
        return [.stopUpdating, .cancelDeadline]
    }

    private mutating func finish(_ decision: WatchNearestStopPolicy.Decision) -> [Effect] {
        phase = result(decision)
        return [.stopUpdating, .cancelDeadline]
    }

    private func result(_ decision: WatchNearestStopPolicy.Decision) -> Phase {
        switch decision {
        case let .nearest(stopID): .resolved(stopID)
        case .noStopNearby: .failed(.noStopNearby)
        case .unusable: .failed(.unavailable)
        }
    }
}
