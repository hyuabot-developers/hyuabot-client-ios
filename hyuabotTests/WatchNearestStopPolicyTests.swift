import XCTest

/// Tests for the watch nearest-stop policy and resolver. The stop coordinates below are copies of
/// `WatchShuttleStop.all` in watch/ContentView.swift, because the watch app is not compiled into this test target.
final class WatchNearestStopPolicyTests: XCTestCase {
    private typealias Resolver = WatchLocationResolver
    private typealias Policy = WatchNearestStopPolicy

    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let stops: [WatchStopCandidate] = [
        WatchStopCandidate(id: "dormitory", latitude: 37.29339607529377, longitude: 126.83630604103446),
        WatchStopCandidate(id: "shuttlecock", latitude: 37.29875417910844, longitude: 126.83784054072336),
        WatchStopCandidate(id: "station", latitude: 37.309700971618255, longitude: 126.85207173389148),
        WatchStopCandidate(id: "terminal", latitude: 37.319338173415936, longitude: 126.8455263115596),
        WatchStopCandidate(id: "jungang", latitude: 37.31487247528457, longitude: 126.83963540399434)
    ]
    private let seoul = (latitude: 37.5665, longitude: 126.9780)

    private func sample(
        at stop: WatchStopCandidate? = nil, accuracy: Double = 20, age: TimeInterval = 0
    ) -> WatchLocationSample {
        let origin = stop ?? stops[0]
        return WatchLocationSample(
            latitude: origin.latitude, longitude: origin.longitude,
            horizontalAccuracy: accuracy, timestamp: now.addingTimeInterval(-age)
        )
    }

    private func farSample(accuracy: Double = 20) -> WatchLocationSample {
        WatchLocationSample(
            latitude: seoul.latitude, longitude: seoul.longitude,
            horizontalAccuracy: accuracy, timestamp: now
        )
    }

    private func start(
        _ resolver: inout Resolver, auth: Resolver.Authorization = .authorized,
        servicesEnabled: Bool = true, cached: WatchLocationSample? = nil
    ) -> [Resolver.Effect] {
        resolver.handle(.start(auth: auth, servicesEnabled: servicesEnabled, cached: cached, now: now), stops: stops)
    }

    // MARK: - Policy

    func testDecidesNearestStopAtItsOwnCoordinate() {
        for stop in stops {
            XCTAssertEqual(
                Policy.decide(sample(at: stop), maxAccuracy: 100, stops: stops),
                .nearest(stop.id),
                "expected \(stop.id)"
            )
        }
    }

    func testRejectsNegativeAccuracy() {
        XCTAssertEqual(Policy.decide(sample(accuracy: -1), maxAccuracy: 500, stops: stops), .unusable)
    }

    func testRejectsAccuracyAboveLimit() {
        XCTAssertEqual(Policy.decide(sample(accuracy: 600), maxAccuracy: 500, stops: stops), .unusable)
    }

    func testAcceptsAccuracyAtDeadlineLimit() {
        XCTAssertEqual(
            Policy.decide(sample(accuracy: 600), maxAccuracy: 1000, stops: stops),
            .nearest("dormitory")
        )
    }

    func testReportsNoStopNearbyFarAwayFromEveryStop() {
        XCTAssertEqual(Policy.decide(farSample(), maxAccuracy: 100, stops: stops), .noStopNearby)
    }

    func testUsesNearestStopWhenBetweenTwoStops() {
        // Slightly on the shuttlecock side of the midpoint between dormitory and shuttlecock.
        let lat = (stops[0].latitude + stops[1].latitude) / 2 + 0.00005
        let lon = (stops[0].longitude + stops[1].longitude) / 2 + 0.00005
        let between = WatchLocationSample(latitude: lat, longitude: lon, horizontalAccuracy: 10, timestamp: now)
        XCTAssertEqual(Policy.decide(between, maxAccuracy: 100, stops: stops), .nearest("shuttlecock"))
    }

    func testFreshnessWindow() {
        XCTAssertTrue(Policy.isUsable(sample(age: 59), now: now))
        XCTAssertFalse(Policy.isUsable(sample(age: 61), now: now))
        XCTAssertFalse(Policy.isUsable(sample(accuracy: -1), now: now))
    }

    func testBetterKeepsMoreAccurateThenNewer() {
        let coarse = sample(accuracy: 300, age: 5)
        let fine = sample(accuracy: 40, age: 10)
        XCTAssertEqual(Policy.better(nil, coarse), coarse)
        XCTAssertEqual(Policy.better(coarse, fine), fine)
        XCTAssertEqual(Policy.better(fine, coarse), fine)

        let older = sample(accuracy: 50, age: 20)
        let newer = sample(accuracy: 50, age: 2)
        XCTAssertEqual(Policy.better(older, newer), newer)
        XCTAssertEqual(Policy.better(newer, older), newer)
    }

    // MARK: - Resolver

    func testAuthorizedStartWithoutCacheUpdatesUntilDeadline() {
        var resolver = Resolver()
        let effects = start(&resolver)
        XCTAssertEqual(effects, [.startUpdating, .scheduleDeadline])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testFreshAccurateCacheResolvesWithoutUpdating() {
        var resolver = Resolver()
        let effects = start(&resolver, cached: sample(at: stops[0], accuracy: 50, age: 5))
        XCTAssertEqual(effects, [])
        XCTAssertEqual(resolver.phase, .resolved("dormitory"))
    }

    func testStaleCacheIsIgnored() {
        var resolver = Resolver()
        let effects = start(&resolver, cached: sample(at: stops[0], accuracy: 50, age: 120))
        XCTAssertEqual(effects, [.startUpdating, .scheduleDeadline])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testNotDeterminedWaitsForPromptThenUpdates() {
        var resolver = Resolver()
        XCTAssertEqual(start(&resolver, auth: .notDetermined), [.requestAuthorization])
        XCTAssertEqual(resolver.phase, .awaitingAuthorization)

        // Starting again while the prompt is up must not request a second prompt or start a timer.
        XCTAssertEqual(start(&resolver, auth: .notDetermined), [])

        let effects = resolver.handle(.authorizationChanged(.authorized), stops: stops)
        XCTAssertEqual(effects, [.startUpdating, .scheduleDeadline])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testDeniedFailsImmediately() {
        var resolver = Resolver()
        XCTAssertEqual(start(&resolver, auth: .denied), [])
        XCTAssertEqual(resolver.phase, .failed(.denied))
    }

    func testServicesDisabledFailsImmediately() {
        var resolver = Resolver()
        XCTAssertEqual(start(&resolver, servicesEnabled: false), [])
        XCTAssertEqual(resolver.phase, .failed(.servicesDisabled))
    }

    func testTransientLocationUnknownKeepsWaiting() {
        var resolver = Resolver()
        _ = start(&resolver)
        let effects = resolver.handle(.error(.locationUnknown), stops: stops)
        XCTAssertEqual(effects, [])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testCoarseFixIsNotDecidedEarly() {
        var resolver = Resolver()
        _ = start(&resolver)
        let effects = resolver.handle(.sample(sample(accuracy: 800), now: now), stops: stops)
        XCTAssertEqual(effects, [])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testAccurateFixResolvesImmediately() {
        var resolver = Resolver()
        _ = start(&resolver)
        let effects = resolver.handle(.sample(sample(at: stops[2], accuracy: 80), now: now), stops: stops)
        XCTAssertEqual(effects, [.stopUpdating, .cancelDeadline])
        XCTAssertEqual(resolver.phase, .resolved("station"))
    }

    func testDeadlineUsesBestFixWithinDeadlineAccuracy() {
        var resolver = Resolver()
        _ = start(&resolver)
        _ = resolver.handle(.sample(sample(at: stops[3], accuracy: 300), now: now), stops: stops)
        let effects = resolver.handle(.deadline, stops: stops)
        XCTAssertEqual(effects, [.stopUpdating, .cancelDeadline])
        XCTAssertEqual(resolver.phase, .resolved("terminal"))
    }

    func testDeadlineWithOnlyCoarseFixTimesOut() {
        var resolver = Resolver()
        _ = start(&resolver)
        _ = resolver.handle(.sample(sample(accuracy: 800), now: now), stops: stops)
        let effects = resolver.handle(.deadline, stops: stops)
        XCTAssertEqual(effects, [.stopUpdating])
        XCTAssertEqual(resolver.phase, .failed(.timedOut))
    }

    func testDeadlineWithNoFixTimesOut() {
        var resolver = Resolver()
        _ = start(&resolver)
        XCTAssertEqual(resolver.handle(.deadline, stops: stops), [.stopUpdating])
        XCTAssertEqual(resolver.phase, .failed(.timedOut))
    }

    func testFarAwayAccurateFixReportsNoStopNearby() {
        var resolver = Resolver()
        _ = start(&resolver)
        _ = resolver.handle(.sample(farSample(), now: now), stops: stops)
        XCTAssertEqual(resolver.phase, .failed(.noStopNearby))
    }

    func testOldSampleIsIgnored() {
        var resolver = Resolver()
        _ = start(&resolver)
        let stale = sample(accuracy: 20, age: 120)
        XCTAssertEqual(resolver.handle(.sample(stale, now: now), stops: stops), [])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testAuthorizationRevokedMidMeasurementFailsAndStops() {
        var resolver = Resolver()
        _ = start(&resolver)
        let effects = resolver.handle(.authorizationChanged(.denied), stops: stops)
        XCTAssertEqual(effects, [.stopUpdating, .cancelDeadline])
        XCTAssertEqual(resolver.phase, .failed(.denied))
    }

    func testDeniedErrorMidMeasurementFails() {
        var resolver = Resolver()
        _ = start(&resolver)
        XCTAssertEqual(resolver.handle(.error(.denied), stops: stops), [.stopUpdating, .cancelDeadline])
        XCTAssertEqual(resolver.phase, .failed(.denied))
    }

    func testRestartWhileUpdatingIsIgnored() {
        var resolver = Resolver()
        _ = start(&resolver)
        XCTAssertEqual(start(&resolver), [])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testCancelWhileUpdatingReturnsToIdle() {
        var resolver = Resolver()
        _ = start(&resolver)
        let effects = resolver.handle(.cancel, stops: stops)
        XCTAssertEqual(effects, [.stopUpdating, .cancelDeadline])
        XCTAssertEqual(resolver.phase, .idle)
    }

    func testCancelWhileAwaitingAuthorizationLeavesPromptAlone() {
        var resolver = Resolver()
        _ = start(&resolver, auth: .notDetermined)
        XCTAssertEqual(resolver.handle(.cancel, stops: stops), [])
        XCTAssertEqual(resolver.phase, .awaitingAuthorization)
    }

    func testFailedStateCanRetry() {
        var resolver = Resolver()
        _ = start(&resolver)
        _ = resolver.handle(.deadline, stops: stops)
        XCTAssertEqual(resolver.phase, .failed(.timedOut))

        let effects = start(&resolver)
        XCTAssertEqual(effects, [.startUpdating, .scheduleDeadline])
        XCTAssertEqual(resolver.phase, .updating)
    }

    func testResolvedStateCanRecheck() {
        var resolver = Resolver()
        _ = start(&resolver)
        _ = resolver.handle(.sample(sample(at: stops[0], accuracy: 20), now: now), stops: stops)
        XCTAssertEqual(resolver.phase, .resolved("dormitory"))

        let effects = start(&resolver)
        XCTAssertEqual(effects, [.startUpdating, .scheduleDeadline])
        XCTAssertEqual(resolver.phase, .updating)
    }
}
