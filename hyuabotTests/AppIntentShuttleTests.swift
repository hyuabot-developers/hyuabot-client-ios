//
//  AppIntentShuttleTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AppIntentShuttleTests: XCTestCase {
    private func referenceNow() throws -> Foundation.Date {
        try XCTUnwrap(IntentClock.seoulCalendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 14, minute: 0)))
    }

    private func stop(_ id: String, _ destinations: [(String, [String])]) -> ShuttleStopTimes {
        ShuttleStopTimes(stopID: id, destinations: destinations.map { ShuttleDestinationTimes(destination: $0.0, times: $0.1) })
    }

    func testClockParsesAndFormatsShuttleTimes() throws {
        let now = try referenceNow()
        XCTAssertEqual(IntentClock.minutesUntil("14:05:00", from: now, calendar: IntentClock.seoulCalendar), 5)
        XCTAssertEqual(IntentClock.minutesUntil("14:05", from: now, calendar: IntentClock.seoulCalendar), 5)
        XCTAssertNil(IntentClock.minutesUntil("13:59:00", from: now, calendar: IntentClock.seoulCalendar))
        XCTAssertNil(IntentClock.minutesUntil("bad", from: now, calendar: IntentClock.seoulCalendar))
        XCTAssertEqual(IntentClock.shortTime("14:05:00"), "14:05")
    }

    func testUpcomingDeparturesSortsAndFiltersDirection() throws {
        let now = try referenceNow()
        let data = stop("station", [("STATION", ["13:50:00", "14:10:00"]), ("TERMINAL", ["14:03:00"])])
        let all = ShuttleIntentLogic.upcomingDepartures(in: data, direction: nil, now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(all.map(\.minutes), [3, 10])
        XCTAssertEqual(all.map(\.destination), ["TERMINAL", "STATION"])
        let directional = stop("station", [("STATION", ["14:10:00"]), ("CAMPUS", ["14:20:00"])])
        XCTAssertEqual(ShuttleIntentLogic.upcomingDepartures(in: directional, direction: .toCampus, now: now,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            calendar: IntentClock.seoulCalendar).map(\.destination), ["CAMPUS"])
        XCTAssertEqual(ShuttleIntentLogic.upcomingDepartures(in: directional, direction: .fromCampus, now: now,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            calendar: IntentClock.seoulCalendar).map(\.destination), ["STATION"])
    }

    func testSingleStopAnswerUsesFutureDestinationsOnly() throws {
        let now = try referenceNow()
        let data = stop("dormitory_o", [("CAMPUS", ["13:00:00"]), ("TERMINAL", ["14:03:00"]), ("STATION", ["14:10:00"])])
        let answer = ShuttleIntentLogic.makeAnswer(stop: .dormitory, direction: nil, location: nil, stops: [data],
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(answer.snippet.rows.count, 2)
        XCTAssertNil(answer.snippet.subtitle)
        XCTAssertEqual(answer.dialog, String(format: String(localized: "intent.shuttle.dialog.next"),
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            ShuttleStopOption.dormitory.title, ShuttleIntentLogic.destinationName(for: "TERMINAL"), "3", "14:03"))
    }

    func testOverviewUsesLocationFallbackNote() throws {
        let now = try referenceNow()
        let data = [stop("dormitory_o", [("CAMPUS", ["14:10:00"])]), stop("station", [("STATION", ["14:03:00"])])]
        let denied = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil, location: .notAuthorized, stops: data,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(denied.snippet.rows.map(\.id), ["dormitory_o", "station"])
        XCTAssertEqual(denied.snippet.subtitle, String(localized: "intent.shuttle.location.hint"))
        let unavailable = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil, location: .unavailable, stops: data,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(unavailable.snippet.subtitle, String(localized: "intent.shuttle.location.unavailable"))
    }

    func testEmptyStopsReturnNoneDialog() throws {
        let answer = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil, location: nil, stops: [],
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            now: try referenceNow(), calendar: IntentClock.seoulCalendar)
        XCTAssertTrue(answer.snippet.rows.isEmpty)
        XCTAssertEqual(answer.dialog, String(localized: "intent.shuttle.dialog.none"))
    }

    func testDistanceAndNearestStopBehavior() {
        XCTAssertEqual(ShuttleIntentLogic.distance(from: ShuttleStopOption.station.coordinate,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            to: ShuttleStopOption.station.coordinate), 0)
        let distance = ShuttleIntentLogic.distance(from: ShuttleStopOption.dormitory.coordinate,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            to: ShuttleStopOption.shuttlecock.coordinate)
        XCTAssertGreaterThan(distance, 400)
        XCTAssertLessThan(distance, 800)
        XCTAssertEqual(ShuttleIntentLogic.nearestStop(to: ShuttleStopOption.station.coordinate, direction: nil), .station)
        XCTAssertEqual(ShuttleIntentLogic.nearestStop(to: ShuttleStopOption.shuttlecockIn.coordinate, direction: nil), .shuttlecock)
        XCTAssertEqual(ShuttleIntentLogic.nearestStop(to: ShuttleStopOption.shuttlecockIn.coordinate,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            direction: .fromCampus), .shuttlecock)
        XCTAssertEqual(ShuttleIntentLogic.nearestStop(to: ShuttleStopOption.shuttlecockIn.coordinate,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            direction: .toCampus), .shuttlecockIn)
        XCTAssertNil(ShuttleIntentLogic.nearestStop(to: ShuttleGeoCoordinate(latitude: 37.5665, longitude: 126.9780), direction: nil))
    }

    func testNearestStopProducesSingleStopAnswer() throws {
        let now = try referenceNow()
        let data = [stop("station", [("CAMPUS", ["14:10:00"])]), stop("dormitory_o", [("STATION", ["14:05:00"])])]
        let answer = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            location: .coordinate(ShuttleStopOption.station.coordinate), stops: data, now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(answer.snippet.title, ShuttleStopOption.station.title)
        XCTAssertEqual(answer.snippet.rows.count, 1)
        XCTAssertEqual(answer.snippet.subtitle, String(localized: "intent.shuttle.nearest"))
    }

    func testNearestStopWithNoMatchingDirectionDoesNotFallBack() throws {
        let now = try referenceNow()
        let data = [stop("station", [("CAMPUS", ["14:10:00"])]), stop("dormitory_o", [("STATION", ["14:05:00"])])]
        let answer = ShuttleIntentLogic.makeAnswer(stop: nil, direction: .fromCampus,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            location: .coordinate(ShuttleStopOption.station.coordinate), stops: data, now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(answer.snippet.title, ShuttleStopOption.station.title)
        XCTAssertTrue(answer.snippet.rows.isEmpty)
        XCTAssertEqual(answer.dialog, String(localized: "intent.shuttle.dialog.none"))
        XCTAssertEqual(answer.snippet.subtitle,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            "\(ShuttleDirectionOption.fromCampus.title) · \(String(localized: "intent.shuttle.nearest"))")
    }

    func testNearestStopMissingFromTimetableRemainsSelected() throws {
        let now = try referenceNow()
        let answer = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
location: .coordinate(ShuttleStopOption.dormitory.coordinate), stops: [stop("station", [("CAMPUS", ["14:10:00"])])],
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(answer.snippet.title, ShuttleStopOption.dormitory.title)
        XCTAssertTrue(answer.snippet.rows.isEmpty)
        XCTAssertEqual(answer.dialog, String(localized: "intent.shuttle.dialog.none"))
        XCTAssertEqual(answer.snippet.subtitle, String(localized: "intent.shuttle.nearest"))
    }

    func testNearestStopWhenAllServiceEndedDoesNotClaimFarAway() throws {
        let now = try referenceNow()
        let stops = ShuttleStopOption.allCases.map { stop($0.rawValue, [("STATION", ["13:00:00"]), ("CAMPUS", ["13:00:00"])]) }
        let answer = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
            location: .coordinate(ShuttleStopOption.station.coordinate), stops: stops, now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(answer.snippet.title, ShuttleStopOption.station.title)
        XCTAssertTrue(answer.snippet.rows.isEmpty)
        XCTAssertEqual(answer.dialog, String(localized: "intent.shuttle.dialog.none"))
        XCTAssertEqual(answer.snippet.subtitle, String(localized: "intent.shuttle.nearest"))
        XCTAssertFalse(answer.snippet.subtitle?.contains(String(localized: "intent.shuttle.location.far")) ?? false)
    }

    func testFarLocationUsesOverviewAndFarNote() throws {
        let now = try referenceNow()
        let answer = ShuttleIntentLogic.makeAnswer(stop: nil, direction: nil,
            // swiftlint:disable:next vertical_parameter_alignment_on_call
location: .coordinate(ShuttleGeoCoordinate(latitude: 37.5665, longitude: 126.9780)), stops: [stop("station", [("CAMPUS",
            ["14:10:00"])])], now: now, calendar: IntentClock.seoulCalendar)
        XCTAssertEqual(answer.snippet.title, String(localized: "intent.shuttle.snippet.title.all"))
        XCTAssertEqual(answer.snippet.subtitle, String(localized: "intent.shuttle.location.far"))
    }
}
