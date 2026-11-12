//
//  ShuttleDisplayLogicTests.swift
//  hyuabotTests
//
@testable import hyuabot
import XCTest

final class ShuttleDisplayLogicTests: XCTestCase {
    private struct RouteCase {
        let stop: String
        let destination: String?
        let tag: String
        let expected: ShuttleDisplayLogic.RouteChipKind
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
        return calendar
    }

    private let outbound: [ShuttleDisplayLogic.StopTime] = [
        .init(stop: "dormitory_o", time: "08:00:00"),
        .init(stop: "shuttlecock_o", time: "08:05:00"),
        .init(stop: "station", time: "08:15:00")
    ]

    private let circular: [ShuttleDisplayLogic.StopTime] = [
        .init(stop: "station", time: "08:15:00"),
        .init(stop: "terminal", time: "08:20:00"),
        .init(stop: "jungang_stn", time: "08:30:00"),
        .init(stop: "shuttlecock_i", time: "08:40:00"),
        .init(stop: "dormitory_i", time: "08:45:00")
    ]

    private func date(day: Int = 14, hour: Int, minute: Int = 0) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)))
    }

    func testRowTimesShowOnlyChosenValue() throws {
        let now = try date(hour: 8, minute: 30)
        let departure = now.addingTimeInterval(5 * 60)
        let remaining = ShuttleDisplayLogic.rowTimes(departure: departure, now: now, showsRemainingTime: true, calendar: calendar)
        XCTAssertEqual(remaining.trailing, String(format: String(localized: "shuttle.realtime.duration.format.%lld"), 5))
        XCTAssertFalse(remaining.isSoon)
        let clock = ShuttleDisplayLogic.rowTimes(departure: departure, now: now, showsRemainingTime: false, calendar: calendar)
        XCTAssertEqual(clock.trailing, "08:35")
        let soon = ShuttleDisplayLogic.rowTimes(
            departure: now.addingTimeInterval(60), now: now, showsRemainingTime: true, calendar: calendar
        )
        XCTAssertTrue(soon.isSoon)
        XCTAssertEqual(soon.trailing, String(localized: "shuttle.realtime.departing_soon"))
    }

    func testMinutesUntilTruncatesAndClamps() throws {
        let now = try date(hour: 8)
        XCTAssertEqual(ShuttleDisplayLogic.minutesUntil(now.addingTimeInterval(-120), now: now), 0)
        XCTAssertEqual(ShuttleDisplayLogic.minutesUntil(now.addingTimeInterval(-1), now: now), 0)
        XCTAssertEqual(ShuttleDisplayLogic.minutesUntil(now.addingTimeInterval(119.9), now: now), 1)
        XCTAssertEqual(ShuttleDisplayLogic.minutesUntil(now.addingTimeInterval(120), now: now), 2)
    }

    func testServiceTimeParsing() {
        XCTAssertEqual(ShuttleDisplayLogic.serviceMinutes(hour: 0, minute: 30), 1470)
        XCTAssertEqual(ShuttleDisplayLogic.serviceMinutes(time: "08:05:00"), 485)
        XCTAssertEqual(ShuttleDisplayLogic.serviceMinutes(time: "08:05"), 485)
        XCTAssertEqual(ShuttleDisplayLogic.serviceMinutes(time: "24:30:00"), 1470)
        XCTAssertEqual(ShuttleDisplayLogic.clock(time: "08:05:00"), "08:05")
        XCTAssertEqual(ShuttleDisplayLogic.clock(time: "24:30"), "24:30")
        for time in ["bad", "", "08", "08:", "08::00", "48:00", "08:60", "08:05:x", "08:05:60", "08:05:00:00"] {
            XCTAssertNil(ShuttleDisplayLogic.serviceMinutes(time: time), time)
            XCTAssertNil(ShuttleDisplayLogic.clock(time: time), time)
        }
    }

    func testDirectOutboundArrival() {
        XCTAssertEqual(
            ShuttleDisplayLogic.arrival(destinationKey: "STATION", boardingTime: "08:05:00", stops: outbound),
            .init(stop: "station", clock: "08:15")
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.destinationRowText(destinationKey: "STATION", boardingTime: "08:05:00", stops: outbound),
            String(
                format: String(localized: "shuttle.realtime.arrives_at_stop.%@.%@"),
                String(localized: "shuttle.destination.shorten.station"), "08:15"
            )
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.timetableArrivalText(destinationKey: "STATION", boardingTime: "08:05:00", stops: outbound),
            "\(String(localized: "shuttle.destination.shorten.station")) 08:15"
        )
    }

    func testCircularArrivalOrder() {
        XCTAssertEqual(
            ShuttleDisplayLogic.orderArrivals(boardingStopID: "shuttlecock_o", boardingTime: "08:05:00", stops: circular),
            [
                .init(stop: "station", clock: "08:15"),
                .init(stop: "terminal", clock: "08:20"),
                .init(stop: "jungang_stn", clock: "08:30")
            ]
        )
        let names = [
            "\(String(localized: "shuttle.destination.shorten.station")) 08:15",
            "\(String(localized: "shuttle.destination.shorten.terminal")) 08:20",
            "\(String(localized: "shuttle.destination.shorten.jungang_station")) 08:30"
        ].joined(separator: " · ")
        XCTAssertEqual(
            ShuttleDisplayLogic.orderRowText(boardingStopID: "shuttlecock_o", boardingTime: "08:05:00", stops: circular),
            String(format: String(localized: "shuttle.realtime.arrives_at.%@"), names)
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.arrival(destinationKey: "TERMINAL", boardingTime: "08:05:00", stops: circular),
            .init(stop: "terminal", clock: "08:20")
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.arrival(destinationKey: "JUNGANG", boardingTime: "08:05:00", stops: circular),
            .init(stop: "jungang_stn", clock: "08:30")
        )
    }

    func testInboundArrival() {
        XCTAssertEqual(
            ShuttleDisplayLogic.arrival(destinationKey: "CAMPUS", boardingTime: "08:15:00", stops: circular),
            .init(stop: "dormitory_i", clock: "08:45")
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.orderArrivals(boardingStopID: "station", boardingTime: "08:15:00", stops: circular),
            [
                .init(stop: "terminal", clock: "08:20"),
                .init(stop: "jungang_stn", clock: "08:30"),
                .init(stop: "dormitory_i", clock: "08:45")
            ]
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.destinationRowText(destinationKey: "CAMPUS", boardingTime: "08:15:00", stops: circular),
            String(
                format: String(localized: "shuttle.realtime.arrives_at_stop.%@.%@"),
                String(localized: "shuttle.destination.shorten.campus"), "08:45"
            )
        )
    }

    func testMissingAndEarlierArrivals() {
        XCTAssertNil(ShuttleDisplayLogic.arrival(destinationKey: "JUNGANG", boardingTime: "08:05:00", stops: outbound))
        XCTAssertNil(ShuttleDisplayLogic.destinationRowText(destinationKey: "JUNGANG", boardingTime: "08:05:00", stops: outbound))
        XCTAssertNil(ShuttleDisplayLogic.timetableArrivalText(destinationKey: nil, boardingTime: "08:05:00", stops: circular))
        XCTAssertNil(ShuttleDisplayLogic.timetableArrivalText(destinationKey: "JUNGANG", boardingTime: "08:05:00", stops: outbound))
        XCTAssertNil(ShuttleDisplayLogic.arrival(destinationKey: "STATION", boardingTime: "08:20:00", stops: circular))
        XCTAssertNil(ShuttleDisplayLogic.arrival(destinationKey: "STATION", boardingTime: "08:15:00", stops: circular))
        XCTAssertNil(ShuttleDisplayLogic.arrival(destinationKey: "UNKNOWN", boardingTime: "08:05:00", stops: circular))
        XCTAssertNil(ShuttleDisplayLogic.arrival(destinationKey: "CAMPUS", boardingTime: "bad", stops: circular))
        XCTAssertTrue(ShuttleDisplayLogic.orderArrivals(boardingStopID: "station", boardingTime: "bad", stops: circular).isEmpty)
        XCTAssertNil(ShuttleDisplayLogic.orderRowText(boardingStopID: "station", boardingTime: "09:00:00", stops: circular))
    }

    func testArrivalSortingDeduplicationAndInvalidStops() {
        let stops: [ShuttleDisplayLogic.StopTime] = [
            .init(stop: "station", time: "08:25:00"), .init(stop: "station", time: "08:00:00"),
            .init(stop: "terminal", time: "bad"), .init(stop: "station", time: "08:15:00")
        ]
        XCTAssertEqual(
            ShuttleDisplayLogic.arrival(destinationKey: "STATION", boardingTime: "08:05:00", stops: stops),
            .init(stop: "station", clock: "08:15")
        )
        XCTAssertEqual(
            ShuttleDisplayLogic.orderArrivals(boardingStopID: "station", boardingTime: "08:05:00", stops: stops),
            [.init(stop: "station", clock: "08:15")]
        )
        let unknown = [ShuttleDisplayLogic.StopTime(stop: "unknown", time: "08:45:00")]
        XCTAssertNil(ShuttleDisplayLogic.stopShortName("unknown"))
        XCTAssertNil(ShuttleDisplayLogic.destinationRowText(destinationKey: "CAMPUS", boardingTime: "08:05:00", stops: unknown))
        XCTAssertNil(ShuttleDisplayLogic.timetableArrivalText(destinationKey: "CAMPUS", boardingTime: "08:05:00", stops: unknown))
        XCTAssertNil(ShuttleDisplayLogic.orderRowText(boardingStopID: "station", boardingTime: "08:05:00", stops: unknown))
    }

    func testRouteChipRules() {
        let cases: [RouteCase] = [
            .init(stop: "dormitory_o", destination: nil, tag: "DH", expected: .direct),
            .init(stop: "dormitory_o", destination: nil, tag: "DY", expected: .terminal),
            .init(stop: "dormitory_o", destination: nil, tag: "DJ", expected: .jungang),
            .init(stop: "station", destination: nil, tag: "C", expected: .circular),
            .init(stop: "dormitory_o", destination: "STATION", tag: "DJ", expected: .direct),
            .init(stop: "dormitory_o", destination: "TERMINAL", tag: "DY", expected: .direct),
            .init(stop: "dormitory_o", destination: "JUNGANG", tag: "DJ", expected: .jungang),
            .init(stop: "station", destination: "CAMPUS", tag: "DJ", expected: .jungang),
            .init(stop: "station", destination: "TERMINAL", tag: "DH", expected: .circular),
            .init(stop: "terminal", destination: "CAMPUS", tag: "DY", expected: .direct),
            .init(stop: "terminal", destination: "CAMPUS", tag: "C", expected: .circular),
            .init(stop: "station", destination: nil, tag: "X", expected: .fallback),
            .init(stop: "station", destination: "CAMPUS", tag: "X", expected: .fallback),
            .init(stop: "station", destination: "JUNGANG", tag: "C", expected: .circular)
        ]
        for routeCase in cases {
            XCTAssertEqual(
                ShuttleDisplayLogic.routeChipKind(stopID: routeCase.stop, destinationKey: routeCase.destination, routeTag: routeCase.tag),
                routeCase.expected
            )
        }
    }

    func testDestinationAndStopMappings() {
        XCTAssertEqual(ShuttleDisplayLogic.destinationKey(stopID: "station", section: 0), "CAMPUS")
        XCTAssertEqual(ShuttleDisplayLogic.destinationKey(stopID: "dormitory_o", section: 2), "JUNGANG")
        XCTAssertNil(ShuttleDisplayLogic.destinationKey(stopID: "terminal", section: 1))
        XCTAssertNil(ShuttleDisplayLogic.destinationKey(stopID: "station", section: -1))
        XCTAssertNil(ShuttleDisplayLogic.destinationKey(stopID: "unknown", section: 0))
        let route = ShuttleDisplayLogic.timetableRoute(start: "shuttle.stop.station", end: "shuttle.destination.shorten.campus")
        XCTAssertEqual(route.stopID, "station")
        XCTAssertEqual(route.destinationKey, "CAMPUS")
        XCTAssertEqual(ShuttleDisplayLogic.stopKey(.dormiotryOut), "dormitory_o")
        XCTAssertEqual(ShuttleDisplayLogic.stopKey(.shuttlecockOut), "shuttlecock_o")
        XCTAssertEqual(ShuttleDisplayLogic.stopKey(.station), "station")
        XCTAssertEqual(ShuttleDisplayLogic.stopKey(.terminal), "terminal")
        XCTAssertEqual(ShuttleDisplayLogic.stopKey(.jungangStation), "jungang_stn")
        XCTAssertEqual(ShuttleDisplayLogic.stopKey(.shuttlecockIn), "shuttlecock_i")
    }
}

extension ShuttleDisplayLogicTests {
    func testTimetableStatesAndHourSections() {
        XCTAssertEqual(ShuttleDisplayLogic.timetableStates(departureMinutes: [480, 500, 520], nowMinutes: 500), [.past, .next, .upcoming])
        XCTAssertEqual(ShuttleDisplayLogic.timetableStates(departureMinutes: [480, 500], nowMinutes: nil), [.upcoming, .upcoming])
        XCTAssertEqual(
            ShuttleDisplayLogic.hourSections(departureMinutes: [480, 490, 545, 1470]),
            [.init(hour: 8, rows: 0 ..< 2), .init(hour: 9, rows: 2 ..< 3), .init(hour: 0, rows: 3 ..< 4)]
        )
        XCTAssertEqual(ShuttleDisplayLogic.hourSections(departureMinutes: []), [])
    }

    func testServiceDayBoundary() throws {
        let saturdayMorning = try date(hour: 10)
        XCTAssertTrue(ShuttleDisplayLogic.isServiceDayMatch(
            isWeekdays: false, selectedDate: nil, now: saturdayMorning, calendar: calendar
        ))
        XCTAssertFalse(ShuttleDisplayLogic.isServiceDayMatch(
            isWeekdays: true, selectedDate: nil, now: saturdayMorning, calendar: calendar
        ))
        XCTAssertTrue(try ShuttleDisplayLogic.isServiceDayMatch(
            isWeekdays: true, selectedDate: nil, now: date(hour: 2), calendar: calendar
        ))
        XCTAssertFalse(try ShuttleDisplayLogic.isServiceDayMatch(
            isWeekdays: false, selectedDate: date(day: 13, hour: 10), now: saturdayMorning, calendar: calendar
        ))
        XCTAssertTrue(ShuttleDisplayLogic.isServiceDayMatch(
            isWeekdays: false, selectedDate: saturdayMorning, now: saturdayMorning, calendar: calendar
        ))
    }

    func testFoldedProjectionAndIndexMapping() {
        let projection = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: [480, 490, 545, 600, 610], nowMinutes: 545, scrollNowMinutes: 544, showsPastRows: false
        )
        XCTAssertEqual(projection.hiddenPastCount, 2)
        XCTAssertEqual(projection.sections.map(\.hour), [9, 10])
        XCTAssertEqual(projection.sections.map(\.itemIndices), [[2], [3, 4]])
        XCTAssertEqual(projection.states, [.past, .past, .next, .upcoming, .upcoming])
        XCTAssertEqual(projection.itemIndex(at: IndexPath(row: 1, section: 1)), 4)
        XCTAssertNil(projection.indexPath(ofItem: 0))
        XCTAssertEqual(projection.indexPath(ofItem: 3), IndexPath(row: 0, section: 1))
        XCTAssertEqual(projection.scrollTargetItem, 2)
        XCTAssertNil(projection.itemIndex(at: IndexPath(row: 0, section: 2)))
        XCTAssertNil(projection.itemIndex(at: IndexPath(row: 2, section: 1)))
        XCTAssertNil(projection.itemIndex(at: IndexPath(row: -1, section: 0)))
        XCTAssertNil(projection.itemIndex(at: IndexPath(row: 0, section: -1)))
        XCTAssertNil(projection.indexPath(ofItem: -1))
        XCTAssertNil(projection.indexPath(ofItem: 5))
        assertRoundTrip(projection)
    }

    func testUnfoldedProjection() {
        let projection = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: [480, 490, 545, 600, 610], nowMinutes: 545, scrollNowMinutes: 545, showsPastRows: true
        )
        XCTAssertEqual(projection.hiddenPastCount, 0)
        XCTAssertEqual(projection.sections.map(\.hour), [8, 9, 10])
        XCTAssertEqual(projection.sections.map(\.itemIndices), [[0, 1], [2], [3, 4]])
        XCTAssertEqual(projection.scrollTargetItem, 3)
        assertRoundTrip(projection)
    }

    func testAllPastProjectionKeepsEveryRow() {
        let projection = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: [480, 490, 545, 600, 610], nowMinutes: 700, scrollNowMinutes: 700, showsPastRows: false
        )
        XCTAssertEqual(projection.hiddenPastCount, 0)
        XCTAssertEqual(projection.states, Array(repeating: .past, count: 5))
        XCTAssertEqual(projection.sections.flatMap(\.itemIndices), [0, 1, 2, 3, 4])
        XCTAssertEqual(projection.scrollTargetItem, 0)
        assertRoundTrip(projection)
    }

    func testEmptyProjection() {
        let projection = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: [], nowMinutes: nil, scrollNowMinutes: 0, showsPastRows: false
        )
        XCTAssertTrue(projection.sections.isEmpty)
        XCTAssertTrue(projection.states.isEmpty)
        XCTAssertEqual(projection.hiddenPastCount, 0)
        XCTAssertNil(projection.scrollTargetItem)
        XCTAssertNil(projection.itemIndex(at: IndexPath(row: 0, section: 0)))
        XCTAssertNil(projection.indexPath(ofItem: 0))
    }

    func testNilNowProjectionAndHiddenScrollTarget() {
        let projection = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: [480, 490, 545, 600, 610], nowMinutes: nil, scrollNowMinutes: 544, showsPastRows: false
        )
        XCTAssertEqual(projection.hiddenPastCount, 0)
        XCTAssertEqual(projection.states, Array(repeating: .upcoming, count: 5))
        XCTAssertEqual(projection.sections.flatMap(\.itemIndices), [0, 1, 2, 3, 4])
        XCTAssertEqual(projection.scrollTargetItem, 2)
        assertRoundTrip(projection)
        let hiddenTarget = ShuttleDisplayLogic.timetableProjection(
            departureMinutes: [480, 490, 545, 600, 610], nowMinutes: 545, scrollNowMinutes: 479, showsPastRows: false
        )
        XCTAssertEqual(hiddenTarget.scrollTargetItem, 2)
    }

    private func assertRoundTrip(
        _ projection: ShuttleDisplayLogic.TimetableProjection,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for item in projection.sections.flatMap(\.itemIndices) {
            guard let indexPath = projection.indexPath(ofItem: item) else {
                XCTFail("Missing displayed item \(item)", file: file, line: line)
                continue
            }
            XCTAssertEqual(projection.itemIndex(at: indexPath), item, file: file, line: line)
        }
    }

    func testAlternativeDisplayModeKeepsLegacyStoredValues() {
        XCTAssertEqual(ShuttleAlternativeDisplayMode(rawValue: 1), .always)
        XCTAssertEqual(ShuttleAlternativeDisplayMode(rawValue: 2), .hidden)
        XCTAssertNil(ShuttleAlternativeDisplayMode(rawValue: 0))
    }
}
