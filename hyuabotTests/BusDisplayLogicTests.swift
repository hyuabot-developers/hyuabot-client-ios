//
//  BusDisplayLogicTests.swift
//  hyuabotTests
//
import XCTest
@testable import hyuabot

final class BusDisplayLogicTests: XCTestCase {
    func testMergedTimetableShowsRouteBadgeOnEveryRowAndChipsOnlyAtUnionEndpoints() throws {
        let entries = BusDisplayLogic.entries(items: [
            try item("A", "weekdays", 5, 0), try item("A", "weekdays", 8, 0),
            try item("B", "weekdays", 6, 0), try item("B", "weekdays", 0, 30)
        ], day: .weekdays, routeFilter: nil)
        XCTAssertEqual(entries.map(\.isFirst), [true, false, false, false])
        XCTAssertEqual(entries.map(\.isLast), [false, false, false, true])
        XCTAssertTrue(BusDisplayLogic.showsTimetableRouteBadge(isMerged: true))
        let folded = BusDisplayLogic.layout(entries: entries, isToday: true, nowMinutes: 480, expanded: false)
        XCTAssertGreaterThan(folded.hiddenPastCount, 0)
        XCTAssertTrue(BusDisplayLogic.showsTimetableRouteBadge(isMerged: true))
        XCTAssertFalse(BusDisplayLogic.showsTimetableRouteBadge(isMerged: false))
    }

    func testMergedTimetableBadgeDependsOnlyOnMergedState() {
        let entries = ["A", "B", "C"].map {
            BusTimetableEntry(route: $0, minutes: 300, isFirst: false, isLast: false)
        }
        XCTAssertTrue(BusDisplayLogic.showsTimetableRouteBadge(isMerged: true))
        XCTAssertFalse(BusDisplayLogic.showsTimetableRouteBadge(isMerged: false))
    }

    func testDepartureLogFoldingKeepsRecentPastAndHighlightsNextInEachColumn() {
        let columns = [["05:00:00", "13:59:00", "14:00:00", "14:59:00", "15:00:00", "15:30:00"],
                       ["05:30:00", "14:30:00", "15:10:00"], []]
        let layout = BusDisplayLogic.departureLogs(columns: columns, nowMinutes: 900, expanded: false)
        XCTAssertEqual(layout.hiddenPastCount, 3)
        XCTAssertEqual(layout.columns[0].map(\.time), ["14:00", "14:59", "15:00", "15:30"])
        XCTAssertEqual(layout.columns[0].filter(\.isNext).map(\.time), ["15:00"])
        XCTAssertEqual(layout.columns[1].filter(\.isNext).map(\.time), ["15:10"])
        XCTAssertTrue(layout.columns[0][0].isPast)
        XCTAssertFalse(layout.columns[0][2].isPast)
        XCTAssertTrue(layout.columns[2].isEmpty)
        let expanded = BusDisplayLogic.departureLogs(columns: columns, nowMinutes: 900, expanded: true)
        XCTAssertEqual(expanded.hiddenPastCount, 0)
        XCTAssertEqual(expanded.columns[0].count, 6)
    }

    func testDepartureLogsFollowServiceDayAcrossMidnightAndIgnoreInvalidTimes() {
        let layout = BusDisplayLogic.departureLogs(
            columns: [["00:30:00", "23:50:00", "invalid", "25:00:00"]], nowMinutes: 1440, expanded: true
        )
        XCTAssertEqual(layout.columns[0].map(\.time), ["23:50", "00:30", "01:00"])
        XCTAssertEqual(layout.columns[0].filter(\.isNext).map(\.time), ["00:30"])
        XCTAssertEqual(BusDisplayLogic.clockText("5:03:00"), "05:03")
        XCTAssertEqual(BusDisplayLogic.clockText("12:90:00"), "—")
        XCTAssertEqual(BusDisplayLogic.clockText(""), "—")
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int) throws -> Date {
        let components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
        return try XCTUnwrap(BusDisplayLogic.serviceCalendar.date(from: components))
    }

    private func item(_ route: String = "A", _ day: String, _ hour: Int, _ minute: Int) throws -> BusTimetableItem {
        BusTimetableItem(route: route, weekdays: day, time: try date(7, hour, minute))
    }

    func testRouteColorsAndArrivalRows() {
        XCTAssertEqual(BusDisplayLogic.routeColor("10-1"), .busGreen)
        XCTAssertEqual(BusDisplayLogic.routeColor("50"), .busGreen)
        XCTAssertEqual(BusDisplayLogic.routeColor("1"), .busRed)
        let scheduledInput = BusArrivalRowInput(
            route: "A", isRealtime: false, stops: nil, seats: nil, realtimeMinutes: nil,
            scheduledMinutes: -2, isLowFloor: true, destinationArrival: "08:30"
        )
        let scheduled = BusDisplayLogic.arrivalRow(scheduledInput)
        XCTAssertEqual(scheduled?.primary, .waitingAtOrigin)
        XCTAssertEqual(scheduled?.remaining, .minutes(0))
        XCTAssertEqual(scheduled?.seats, .unknown)
        XCTAssertEqual(
            BusDisplayLogic.arrivalRow(BusArrivalRowInput(
                route: "3102", isRealtime: true, stops: 2, seats: 5, realtimeMinutes: 7,
                scheduledMinutes: 5, isLowFloor: false, destinationArrival: nil
            )),
            BusArrivalRowModel(route: "3102", isRealtime: false, primary: .waitingAtOrigin,
                               remaining: .minutes(5), seats: .unknown, isLowFloor: false,
                               destinationArrival: nil)
        )
        let soonStops = BusDisplayLogic.arrivalRow(BusArrivalRowInput(
            route: "A", isRealtime: true, stops: 1, seats: -1, realtimeMinutes: 9,
            scheduledMinutes: nil, isLowFloor: false, destinationArrival: nil
        ))
        XCTAssertEqual(soonStops?.remaining, .soon)
        XCTAssertEqual(soonStops?.seats, .unknown)
        let soonMinutes = BusDisplayLogic.arrivalRow(BusArrivalRowInput(
            route: "A", isRealtime: true, stops: 3, seats: 0, realtimeMinutes: 1,
            scheduledMinutes: nil, isLowFloor: false, destinationArrival: nil
        ))
        XCTAssertEqual(soonMinutes?.remaining, .soon)
        XCTAssertEqual(soonMinutes?.seats, .full)
        let minutes = BusDisplayLogic.arrivalRow(BusArrivalRowInput(
            route: "A", isRealtime: true, stops: 3, seats: 3, realtimeMinutes: 7,
            scheduledMinutes: nil, isLowFloor: false, destinationArrival: nil
        ))
        XCTAssertEqual(minutes?.remaining, .minutes(7))
        XCTAssertEqual(minutes?.seats, .available(3))
        let incomplete = BusArrivalRowInput(
            route: "A", isRealtime: true, stops: nil, seats: 3, realtimeMinutes: 7,
            scheduledMinutes: nil, isLowFloor: false, destinationArrival: nil
        )
        XCTAssertNil(BusDisplayLogic.arrivalRow(incomplete))
    }

    func testDestinationETAAndMinutesOnly() throws {
        let destination = BusRealtimeSections.destinationName(for: 216_000_138)
        let row = try XCTUnwrap(BusDisplayLogic.arrivalRow(BusArrivalRowInput(
            route: "10-1", isRealtime: true, stops: 12, seats: -1, realtimeMinutes: 69,
            scheduledMinutes: nil, isLowFloor: false, destinationArrival: "10:37",
            destinationName: destination
        )))
        XCTAssertEqual(row.destinationName, destination)
        XCTAssertEqual(BusDisplayLogic.destinationETA(row), String(
            format: String(localized: "bus.realtime.eta.%@.%@"), destination, "10:37"
        ))
        for minutes in [0, 59, 60, 69, 120, 1499] {
            XCTAssertEqual(BusDisplayLogic.remainingText(.minutes(minutes)), String(
                format: String(localized: "bus.realtime.minutes.%lld"), minutes
            ))
        }
        var missingDestination = row
        missingDestination.destinationName = nil
        XCTAssertNil(BusDisplayLogic.destinationETA(missingDestination))
        XCTAssertEqual(BusRealtimeSections.destinationName(for: 216_000_378), String(localized: "home.bus.stop.convention.short"))
        XCTAssertEqual(BusRealtimeSections.destinationName(for: 216_000_048), String(localized: "bus.stop.main_gate"))
        XCTAssertEqual(BusRealtimeSections.destinationName(for: 202_000_208), String(localized: "bus.stop.suwon_station"))
        XCTAssertEqual(BusRealtimeSections.destinationName(for: 216_000_141), String(localized: "bus.stop.entrance"))
        XCTAssertEqual(BusRealtimeSections.destinationName(for: 216_000_117), String(localized: "bus.stop.ansan_park_prugio"))
        XCTAssertEqual(BusRealtimeSections.destinationName(for: 213_000_487), String(localized: "home.destination.gwangmyeong"))
    }

    func testTimetableDayTabsTodayAndServiceBoundary() throws {
        XCTAssertEqual(BusDisplayLogic.dayTabs(items: []), [.weekdays, .saturday, .sunday])
        let merged = try [item("A", "weekdays", 8, 0), item("A", "saturday", 8, 0), item("A", "sunday", 8, 0)]
        XCTAssertEqual(BusDisplayLogic.dayTabs(items: merged), [.weekdays, .weekends])
        var split = merged
        split[2] = try item("A", "sunday", 9, 0)
        XCTAssertEqual(BusDisplayLogic.dayTabs(items: split), [.weekdays, .saturday, .sunday])
        let splitTabs: [BusTimetableDay] = [.weekdays, .saturday, .sunday]
        let mergedTabs: [BusTimetableDay] = [.weekdays, .weekends]
        XCTAssertEqual(BusDisplayLogic.today(date: try date(7, 3, 59), tabs: splitTabs), .weekdays)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(7, 3, 59), tabs: mergedTabs), .weekdays)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(7, 4, 0), tabs: splitTabs), .saturday)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(7, 4, 0), tabs: mergedTabs), .weekends)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(8, 1, 0), tabs: splitTabs), .saturday)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(8, 1, 0), tabs: mergedTabs), .weekends)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(8, 4, 0), tabs: splitTabs), .sunday)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(8, 4, 0), tabs: mergedTabs), .weekends)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(9, 1, 0), tabs: splitTabs), .sunday)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(9, 1, 0), tabs: mergedTabs), .weekends)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(9, 4, 0), tabs: splitTabs), .weekdays)
        XCTAssertEqual(BusDisplayLogic.today(date: try date(9, 4, 0), tabs: mergedTabs), .weekdays)
    }

    func testMergedBoundariesAndFilteredRouteBadges() throws {
        let items = try [
            item("A", "saturday", 5, 0), item("A", "saturday", 22, 0),
            item("B", "saturday", 6, 0), item("B", "saturday", 1, 30),
            item("A", "sunday", 4, 0)
        ]
        let merged = BusDisplayLogic.entries(items: items, day: .saturday, routeFilter: nil)
        XCTAssertEqual(merged.map(\.isFirst), [true, false, false, false])
        XCTAssertEqual(merged.map(\.isLast), [false, false, false, true])
        XCTAssertTrue(BusDisplayLogic.showsTimetableRouteBadge(isMerged: true))
        let folded = BusDisplayLogic.layout(entries: merged, isToday: true, nowMinutes: 1400, expanded: false)
        XCTAssertTrue(BusDisplayLogic.showsTimetableRouteBadge(isMerged: true))
        let filtered = BusDisplayLogic.entries(items: items, day: .saturday, routeFilter: "A")
        XCTAssertEqual(filtered.map(\.isFirst), [true, false])
        XCTAssertEqual(filtered.map(\.isLast), [false, true])
        XCTAssertFalse(BusDisplayLogic.showsTimetableRouteBadge(isMerged: false))
        let single = BusDisplayLogic.entries(items: items, day: .sunday, routeFilter: nil)
        XCTAssertTrue(try XCTUnwrap(single.first).isFirst)
        XCTAssertTrue(try XCTUnwrap(single.first).isLast)
        XCTAssertTrue(BusDisplayLogic.entries(items: items, day: .weekdays, routeFilter: nil).isEmpty)
    }

    func testEntriesAndLayout() throws {
        let items = try [
            item("A", "saturday", 1, 0), item("A", "saturday", 1, 30),
            item("B", "saturday", 1, 30), item("A", "saturday", 2, 0),
            item("A", "sunday", 6, 0)
        ]
        let entries = BusDisplayLogic.entries(items: items, day: .saturday, routeFilter: nil)
        XCTAssertEqual(entries.map(\.minutes), [1500, 1530, 1530, 1560])
        XCTAssertEqual(entries[0].timeText, "01:00")
        XCTAssertTrue(entries[0].isFirst)
        XCTAssertTrue(entries[3].isLast)
        XCTAssertEqual(BusDisplayLogic.entries(items: items, day: .saturday, routeFilter: "B").map(\.route), ["B"])
        let ordinary = BusDisplayLogic.layout(entries: entries, isToday: false, nowMinutes: 1510, expanded: false)
        XCTAssertEqual(ordinary.hiddenPastCount, 0)
        XCTAssertEqual(ordinary.groups.flatMap(\.rows).count, 4)
        XCTAssertTrue(ordinary.groups.flatMap(\.rows).allSatisfy { $0.state == .upcoming })
        let compact = BusDisplayLogic.layout(entries: entries, isToday: true, nowMinutes: 1510, expanded: false)
        XCTAssertEqual(compact.hiddenPastCount, 0)
        XCTAssertEqual(compact.groups.flatMap(\.rows).first?.state, .past)
        XCTAssertEqual(compact.groups.flatMap(\.rows)[1].state, .next(minutesUntil: 20))
        let expanded = BusDisplayLogic.layout(entries: entries, isToday: true, nowMinutes: 1510, expanded: true)
        XCTAssertEqual(expanded.hiddenPastCount, 0)
        XCTAssertEqual(expanded.groups.flatMap(\.rows).count, 4)
        let allPast = BusDisplayLogic.layout(entries: entries, isToday: true, nowMinutes: 1600, expanded: false)
        XCTAssertEqual(allPast.hiddenPastCount, 3)
        XCTAssertEqual(allPast.groups.flatMap(\.rows).count, 1)
        let afterMidnight = try date(8, 1, 0)
        let afterItems = try [item("A", "saturday", 1, 30), item("A", "sunday", 6, 0)]
        XCTAssertEqual(BusDisplayLogic.today(date: afterMidnight, tabs: BusDisplayLogic.dayTabs(items: afterItems)), .saturday)
        let afterMidnightEntries = BusDisplayLogic.entries(items: afterItems, day: .saturday, routeFilter: nil)
        let next = BusDisplayLogic.layout(
            entries: afterMidnightEntries, isToday: true,
            nowMinutes: BusDisplayLogic.serviceMinutes(of: afterMidnight), expanded: false
        )
        XCTAssertEqual(next.groups.flatMap(\.rows).first?.state, .next(minutesUntil: 30))
    }
}
