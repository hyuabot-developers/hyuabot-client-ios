//
//  RealtimeFreshnessTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class RealtimeFreshnessTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func timestamp(secondsAgo: TimeInterval) -> String {
        ISO8601DateFormatter().string(from: now.addingTimeInterval(-secondsAgo))
    }

    func testBusBoundaryAndFutureTimestamp() {
        XCTAssertFalse(RealtimeFreshness.isBusStale([timestamp(secondsAgo: 119)], now: now))
        XCTAssertTrue(RealtimeFreshness.isBusStale([timestamp(secondsAgo: 120)], now: now))
        XCTAssertFalse(RealtimeFreshness.isBusStale([timestamp(secondsAgo: -50)], now: now))
    }

    func testSubwayUsesNewestTrainAtEachStation() {
        XCTAssertFalse(RealtimeFreshness.isSubwayStale([timestamp(secondsAgo: 240), timestamp(secondsAgo: 179)], now: now))
        XCTAssertTrue(RealtimeFreshness.isSubwayStale([timestamp(secondsAgo: 240), timestamp(secondsAgo: 180)], now: now))
    }

    func testEmptyRealtimeListIsScheduled() {
        XCTAssertFalse(RealtimeFreshness.isBusStale([], now: now))
        XCTAssertFalse(RealtimeFreshness.isSubwayStale([nil], now: now))
        XCTAssertNil(RealtimeFreshness.latestUpdate([]))
    }

    func testAgeUsesServerTimeAndClampsFutureValues() {
        XCTAssertEqual(RealtimeFreshness.ageMinutes(now.addingTimeInterval(-120), now: now), 2)
        XCTAssertEqual(RealtimeFreshness.ageMinutes(now.addingTimeInterval(50), now: now), 0)
    }

    func testParsesFractionalAndWholeSecondTimestamps() {
        XCTAssertNotNil(RealtimeFreshness.parse("2026-09-29T12:00:00Z"))
        XCTAssertNotNil(RealtimeFreshness.parse("2026-09-29T12:00:00.123Z"))
    }

    func testStatusTextLoadingState() {
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[]],
            hasArrivals: false,
            lastSuccessfulCheckAt: nil,
            isLoading: true,
            hasError: false,
            isOffline: false,
            staleAfter: 120,
            now: now
        )
        XCTAssertEqual(status, String(localized: "transit.loading"))
    }

    func testStatusTextErrorState() {
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[]],
            hasArrivals: false,
            lastSuccessfulCheckAt: now,
            isLoading: false,
            hasError: true,
            isOffline: false,
            staleAfter: 120,
            now: now
        )
        XCTAssertEqual(status, String(localized: "transit.error"))
    }

    func testStatusTextOfflineState() {
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[]],
            hasArrivals: false,
            lastSuccessfulCheckAt: now,
            isLoading: false,
            hasError: true,
            isOffline: true,
            staleAfter: 120,
            now: now
        )
        XCTAssertEqual(status, String(localized: "transit.offline"))
    }

    func testStatusTextEmptyState() {
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[]],
            hasArrivals: false,
            lastSuccessfulCheckAt: now,
            isLoading: false,
            hasError: false,
            isOffline: false,
            staleAfter: 120,
            now: now
        )
        XCTAssertEqual(status, String(localized: "transit.empty"))
    }

    func testStatusTextCheckedState() {
        let testDate = now.addingTimeInterval(-30) // 30 seconds ago
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[timestamp(secondsAgo: 30)]],
            hasArrivals: true,
            lastSuccessfulCheckAt: testDate,
            isLoading: false,
            hasError: false,
            isOffline: false,
            staleAfter: 120,
            now: now
        )

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        let timeString = formatter.string(from: testDate)
        let expected = String(format: String(localized: "transit.checked.%@"), timeString)
        XCTAssertEqual(status, expected)
    }

    func testStatusTextStaleState() {
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[timestamp(secondsAgo: 180)]], // 180 seconds ago, exceeds 120s threshold
            hasArrivals: true,
            lastSuccessfulCheckAt: now.addingTimeInterval(-30),
            isLoading: false,
            hasError: false,
            isOffline: false,
            staleAfter: 120,
            now: now
        )

        let expected = String(format: String(localized: "transit.stale.%lld"), 3) // 3 minutes ago
        XCTAssertEqual(status, expected)
    }

    func testStatusTextScheduledState() {
        let status = RealtimeFreshness.statusText(
            stationUpdates: [[]],
            hasArrivals: true,
            lastSuccessfulCheckAt: now,
            isLoading: false,
            hasError: false,
            isOffline: false,
            staleAfter: 120,
            now: now
        )
        XCTAssertEqual(status, String(localized: "transit.timetable"))
    }
}
