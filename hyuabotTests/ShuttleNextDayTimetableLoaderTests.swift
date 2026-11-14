//
//  ShuttleNextDayTimetableLoaderTests.swift
//  hyuabotTests
//

import XCTest
@testable import hyuabot

@MainActor
final class ShuttleNextDayTimetableLoaderTests: XCTestCase {
    @MainActor
    private final class Harness {
        var stored: ShuttleNextDayTimetable?
        var published: [ShuttleNextDayTimetable?] = []
        var requests: [(date: String, completion: (ShuttleNextDayTimetableLoader.Departures?) -> Void)] = []
        var loader: ShuttleNextDayTimetableLoader!

        init() {
            loader = ShuttleNextDayTimetableLoader(
                current: { self.stored },
                publish: { value in
                    self.stored = value
                    self.published.append(value)
                },
                fetch: { date, completion in self.requests.append((date, completion)) }
            )
        }
    }

    private let sunday: ShuttleNextDayTimetableLoader.Departures = ["dormitory_o": ["STATION": ["09:00:00"]]]
    private let monday: ShuttleNextDayTimetableLoader.Departures = ["dormitory_o": ["STATION": ["07:50:00"]]]

    func testCachedDateIsNotRefetched() {
        let harness = Harness()
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        harness.requests[0].completion(sunday)

        XCTAssertEqual(harness.stored?.date, "2026-11-15")
        XCTAssertEqual(harness.stored?.isWeekend, true)
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        XCTAssertEqual(harness.requests.count, 1)
    }

    func testInFlightDateIsNotRequestedTwice() {
        let harness = Harness()
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        XCTAssertEqual(harness.requests.count, 1)
    }

    func testReplacementClearsObsoleteDateAndFailedFetchKeepsItCleared() {
        let harness = Harness()
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        harness.requests[0].completion(sunday)

        harness.loader.load(date: "2026-11-16", isWeekend: false)
        XCTAssertNil(harness.stored)
        XCTAssertEqual(harness.published.last, .some(nil))
        XCTAssertEqual(harness.requests.count, 2)

        harness.requests[1].completion(nil)
        XCTAssertNil(harness.stored)
        XCTAssertNil(harness.loader.inFlightDate)
        harness.loader.load(date: "2026-11-16", isWeekend: false)
        XCTAssertEqual(harness.requests.count, 3)

        harness.requests[2].completion(monday)
        XCTAssertEqual(harness.stored, ShuttleNextDayTimetable(date: "2026-11-16", isWeekend: false, departures: monday))
    }

    func testOlderCompletionAfterNewerResultIsDiscarded() {
        let harness = Harness()
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        harness.loader.load(date: "2026-11-16", isWeekend: false)

        harness.requests[1].completion(monday)
        harness.requests[0].completion(sunday)
        XCTAssertEqual(harness.stored?.date, "2026-11-16")
        XCTAssertFalse(harness.published.contains { $0?.date == "2026-11-15" })
    }

    func testOlderCompletionBeforeNewerResultIsDiscarded() {
        let harness = Harness()
        harness.loader.load(date: "2026-11-15", isWeekend: true)
        harness.loader.load(date: "2026-11-16", isWeekend: false)

        harness.requests[0].completion(sunday)
        XCTAssertNil(harness.stored)
        XCTAssertEqual(harness.loader.inFlightDate, "2026-11-16")

        harness.requests[1].completion(monday)
        XCTAssertEqual(harness.stored?.date, "2026-11-16")
    }
}
