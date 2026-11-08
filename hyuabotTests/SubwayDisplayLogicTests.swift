//
//  SubwayDisplayLogicTests.swift
//  hyuabotTests
//
@testable import hyuabot
import XCTest

final class SubwayDisplayLogicTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return value
    }

    private var now: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 14, minute: 2)) ?? Date(timeIntervalSince1970: 0)
    }

    func testArrivalSoonAndSubtitleRules() {
        let soon = SubwayDisplayLogic.arrivalRow(info(minutes: 1, realtime: true))
        XCTAssertEqual(soon.minutesText, String(localized: "subway.realtime.soon"))
        XCTAssertTrue(soon.isSoon)
        let scheduled = SubwayDisplayLogic.arrivalRow(info(minutes: 1, realtime: false))
        XCTAssertEqual(scheduled.minutesText, String(format: String(localized: "subway.realtime.minutes.%lld"), 1))
        XCTAssertFalse(scheduled.isSoon)
        let statusSoon = SubwayDisplayLogic.arrivalRow(info(minutes: 5, realtime: true, status: 3))
        XCTAssertTrue(statusSoon.isSoon)
        XCTAssertEqual(statusSoon.subtitle, String(format: String(localized: "subway.realtime.status.departed.%@"), "Station"))
    }

    func testArrivalAccessibilitySuffixes() {
        let scheduled = SubwayDisplayLogic.arrivalRow(info(minutes: 3, realtime: false, last: true))
        XCTAssertTrue(scheduled.accessibilityLabel.contains(String(localized: "subway.realtime.a11y.timetable")))
        XCTAssertTrue(scheduled.accessibilityLabel.contains(String(localized: "subway.chip.last")))
        let realtime = SubwayDisplayLogic.arrivalRow(info(minutes: 3, realtime: true, status: 0))
        XCTAssertEqual(realtime.subtitle, String(format: String(localized: "subway.realtime.status.entering.%@"), "Station"))
    }

    func testPositionTextRejectsMissingValuesAndMapsStatuses() {
        XCTAssertNil(SubwayDisplayLogic.positionText(location: nil, status: 1))
        XCTAssertNil(SubwayDisplayLogic.positionText(location: "", status: 1))
        XCTAssertNil(SubwayDisplayLogic.positionText(location: "Station", status: nil))
        XCTAssertEqual(
            SubwayDisplayLogic.positionText(location: "Station", status: 1),
            String(format: String(localized: "subway.realtime.status.arrived.%@"), "Station")
        )
        XCTAssertNil(SubwayDisplayLogic.positionText(location: "Station", status: 8))
    }

    func testTransferRouteClockWaitAndDirect() {
        let second = SubwayTransferLegInfo(line: .suin, terminalName: "Destination", minutes: 19)
        let route = SubwayDisplayLogic.transferRoute(
            SubwayTransferRouteInfo(
                first: .init(line: .line4, terminalName: "Terminal", minutes: 4),
                transferStation: "Transfer",
                waitMinutes: 5,
                second: second
            ), now: now, calendar: calendar
        )
        XCTAssertEqual(
            route.second?.trailingText,
            String(format: String(localized: "subway.transfer.departure.%@"), "14:21")
        )
        XCTAssertEqual(route.waitText, String(format: String(localized: "subway.transfer.wait.dot.%lld"), 5))
        let direct = SubwayDisplayLogic.transferRoute(
            SubwayTransferRouteInfo(
                first: .init(line: .line4, terminalName: "Terminal", minutes: 0),
                transferStation: "Unused",
                waitMinutes: 0,
                second: nil
            ), now: now, calendar: calendar
        )
        XCTAssertNil(direct.second)
        XCTAssertNil(direct.transferStation)
        XCTAssertNil(direct.waitText)
        XCTAssertTrue(direct.accessibilityLabel.contains(String(localized: "subway.transfer.a11y.direct")))
    }

    func testTransferRoutePositionIsNonStrongAndFallsBackToMinutes() {
        let positioned = SubwayTransferRouteInfo(
            first: .init(line: .line4, terminalName: "Terminal", minutes: 8, location: "달월", status: 2),
            transferStation: nil, waitMinutes: nil, second: nil
        )
        let model = SubwayDisplayLogic.transferRoute(positioned, now: now, calendar: calendar)
        let departed = String(format: String(localized: "subway.realtime.status.departed.%@"), "달월")
        XCTAssertEqual(model.first.trailingText, departed)
        XCTAssertFalse(model.first.isStrong)
        XCTAssertTrue(model.accessibilityLabel.contains(String(format: String(localized: "subway.transfer.a11y.current.%@"), departed)))
        var noPosition = positioned
        noPosition = SubwayTransferRouteInfo(
            first: .init(line: .line4, terminalName: "Terminal", minutes: 8),
            transferStation: nil,
            waitMinutes: nil,
            second: nil
        )
        XCTAssertEqual(
            SubwayDisplayLogic.transferRoute(noPosition, now: now).first.trailingText,
            String(format: String(localized: "subway.minutes.after.%lld"), 8)
        )
    }

    func testSectionsAndCaps() {
        let arrivals = [info(minutes: 5, realtime: true)]
        let sections = SubwayDisplayLogic.lineSections(line: .line4, up: arrivals, down: [])
        XCTAssertEqual(sections.count, 2)
        XCTAssertFalse(sections[0].isEmpty)
        XCTAssertTrue(sections[1].isEmpty)
        XCTAssertEqual(sections[0].timetable?.heading, .up)
        let route = SubwayTransferRouteInfo(
            first: .init(line: .line4, terminalName: "Terminal", minutes: 1),
            transferStation: nil,
            waitMinutes: nil,
            second: nil
        )
        let transfers = SubwayDisplayLogic.transferSections(toIncheon: Array(repeating: route, count: 5), toHanyang: [], now: now)
        XCTAssertEqual(transfers.count, 2)
        XCTAssertEqual(transfers[0].title, String(localized: "subway.direction.transfer.up"))
        XCTAssertFalse(transfers[0].isEmpty)
        XCTAssertTrue(transfers[1].isEmpty)
        if case let .transfers(rows) = transfers[0].rows {
            XCTAssertEqual(rows.count, 4)
        } else {
            XCTFail("Expected transfer rows")
        }
        let downTransfers = SubwayDisplayLogic.transferSections(
            toIncheon: [], toHanyang: Array(repeating: route, count: 5), now: now
        )
        XCTAssertTrue(downTransfers[0].isEmpty)
        if case let .transfers(rows) = downTransfers[1].rows {
            XCTAssertEqual(rows.count, 4)
        } else {
            XCTFail("Expected transfer rows")
        }
    }

    func testServiceDayBeforeFourAMBelongsToPreviousDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)) ?? Date()
        }
        // 2026-11-07 is Saturday, 11-08 Sunday, 11-09 Monday.
        XCTAssertEqual(SubwayDayType.serviceDay(date(7, 0, 30), calendar: calendar), .weekdays)
        XCTAssertEqual(SubwayDayType.serviceDay(date(7, 5, 0), calendar: calendar), .weekends)
        XCTAssertEqual(SubwayDayType.serviceDay(date(9, 0, 30), calendar: calendar), .weekends)
        XCTAssertEqual(SubwayDayType.serviceDay(date(9, 4, 0), calendar: calendar), .weekdays)
    }

    func testSortableMinutesAndDepartures() {
        XCTAssertEqual(SubwayDisplayLogic.sortableMinutes("05:14:00"), 314)
        XCTAssertEqual(SubwayDisplayLogic.sortableMinutes("00:30:00"), 1470)
        XCTAssertNil(SubwayDisplayLogic.sortableMinutes("bad"))
        let items: [(time: String, terminalName: String)] = [("06:00", "A"), ("05:00", "B"), ("bad", "C")]
        let departures = SubwayDisplayLogic.departures(items, line: .line4)
        XCTAssertEqual(departures.map(\.terminalName), ["B", "A"])
        XCTAssertTrue(departures[0].isFirst)
        XCTAssertTrue(departures[1].isLast)
        let merged = SubwayDisplayLogic.merged([departures, SubwayDisplayLogic.departures([("05:00", "C")], line: .suin)])
        XCTAssertEqual(merged.map(\.terminalName), ["B", "C", "A"])
        XCTAssertEqual(merged.map(\.isFirst), [true, false, false])
        XCTAssertEqual(merged.map(\.isLast), [false, false, true])
        XCTAssertTrue(SubwayDisplayLogic.merged([]).isEmpty)
        let single = SubwayDisplayLogic.merged([SubwayDisplayLogic.departures([("00:30", "D")], line: .suin)])
        XCTAssertTrue(single[0].isFirst)
        XCTAssertTrue(single[0].isLast)
    }

    func testMergedTimetableLayoutMarksOnlyOverallFirstAndLast() {
        let line4 = SubwayDisplayLogic.departures([("05:00", "A"), ("23:30", "B")], line: .line4)
        let suin = SubwayDisplayLogic.departures([("05:00", "C"), ("00:30", "D")], line: .suin)
        let layout = SubwayDisplayLogic.timetableLayout(line4 + suin, nowMinutes: nil, expanded: true, merged: true)
        let rows = layout.groups.flatMap(\.rows)
        XCTAssertEqual(rows.map(\.timeText), ["05:00", "05:00", "23:30", "00:30"])
        XCTAssertEqual(rows.map(\.isFirst), [true, false, false, false])
        XCTAssertEqual(rows.map(\.isLast), [false, false, false, true])
        let collapsed = SubwayDisplayLogic.timetableLayout(line4 + suin, nowMinutes: 6 * 60, expanded: false, merged: true)
        XCTAssertEqual(collapsed.hiddenPastCount, 2)
        XCTAssertFalse(collapsed.groups.flatMap(\.rows).contains(where: \.isFirst))
        XCTAssertEqual(collapsed.groups.flatMap(\.rows).filter(\.isLast).count, 1)
    }

    func testTimetableLayoutStatesAndAfterMidnight() {
        let departures = SubwayDisplayLogic.departures([("14:00", "A"), ("14:10", "B"), ("14:30", "C")], line: .line4)
        let collapsed = SubwayDisplayLogic.timetableLayout(departures, nowMinutes: 14 * 60 + 5, expanded: false, merged: false)
        XCTAssertEqual(collapsed.hiddenPastCount, 1)
        XCTAssertTrue(collapsed.groups.first?.rows.first?.isNext == true)
        XCTAssertEqual(
            collapsed.groups.first?.rows.first?.nextText,
            String(format: String(localized: "subway.minutes.after.%lld"), 5)
        )
        let expanded = SubwayDisplayLogic.timetableLayout(departures, nowMinutes: 14 * 60 + 5, expanded: true, merged: false)
        XCTAssertEqual(expanded.hiddenPastCount, 0)
        XCTAssertTrue(expanded.groups.first?.rows.first?.isPast == true)
        let unknown = SubwayDisplayLogic.timetableLayout(departures, nowMinutes: nil, expanded: false, merged: false)
        XCTAssertEqual(unknown.hiddenPastCount, 0)
        XCTAssertFalse(unknown.groups.flatMap(\.rows).contains(where: \.isNext))
        let allPast = SubwayDisplayLogic.timetableLayout(departures, nowMinutes: 15 * 60, expanded: false, merged: false)
        XCTAssertEqual(allPast.hiddenPastCount, 2)
        let overnight = SubwayDisplayLogic.departures([("00:30", "A")], line: .suin)
        XCTAssertEqual(
            SubwayDisplayLogic.timetableLayout(overnight, nowMinutes: nil, expanded: false, merged: false)
                .groups.first?.title,
            String(format: String(localized: "subway.timetable.hour.after.midnight.%@"), "00")
        )
    }

    private func info(minutes: Int, realtime: Bool, last: Bool = false, status: Int? = nil) -> SubwayArrivalInfo {
        SubwayArrivalInfo(
            terminalName: "Terminal",
            minutes: minutes,
            isRealtime: realtime,
            isLast: last,
            status: status,
            location: status == nil ? nil : "Station"
        )
    }
}
