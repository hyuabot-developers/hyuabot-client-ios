//
//  EmptyCellViewConfigureTests.swift
//  hyuabot
//

@testable import hyuabot
import UIKit
import XCTest

/// Each *EmptyCellView forwards `configure(_:)` to its private StateView.
/// These tests check that the forwarded content reaches the rendered UIContentUnavailableView.
@MainActor
final class EmptyCellViewConfigureTests: XCTestCase {
    private let message = "다른 조건으로 검색해 보세요."

    func testShuttleRealtimeEmptyCellShowsTitleAndBody() throws {
        let cell = ShuttleRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        cell.configure(title: "운행 종료", body: "내일 첫차 08:00")
        let labels = descendants(in: cell).compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.map(\.text), ["운행 종료", "내일 첫차 08:00"])
        XCTAssertEqual(labels.map { $0.font.pointSize }, [15, 13])
        let godoBold = try XCTUnwrap(UIFont(name: "GodoB", size: 15))
        let godoMedium = try XCTUnwrap(UIFont(name: "GodoM", size: 13))
        XCTAssertEqual(labels.map(\.font.fontName), [godoBold.fontName, godoMedium.fontName])
        XCTAssertTrue(labels.allSatisfy(\.adjustsFontForContentSizeCategory))
        XCTAssertTrue(labels.allSatisfy { $0.textAlignment == .center && $0.numberOfLines == 0 })
        XCTAssertEqual(labels.last?.textColor, .secondaryLabel)
        cell.configure(title: "운행 없음", body: "평일 시간표")
        XCTAssertEqual(labels.map(\.text), ["운행 없음", "평일 시간표"])
    }

    func testShuttleEmptyTextDistinguishesNoServiceAndEndedService() {
        let weekday = ShuttleDisplayLogic.emptyText(destination: "한대앞", departureTimes: [], isWeekend: false)
        XCTAssertEqual(weekday.title, String(localized: "shuttle.realtime.empty.not_operating.title"))
        XCTAssertEqual(weekday.body, String(localized: "shuttle.realtime.empty.not_operating.body"))
        let weekend = ShuttleDisplayLogic.emptyText(destination: "한대앞", departureTimes: [], isWeekend: true)
        XCTAssertEqual(weekend.title, String(localized: "shuttle.realtime.empty.weekend.title"))
        let ended = ShuttleDisplayLogic.emptyText(
            destination: "한대앞", departureTimes: ["23:00:00", "00:30:00", "08:10:00"], isWeekend: true
        )
        XCTAssertEqual(ended.title, String(format: String(localized: "shuttle.realtime.empty.ended.title"), "한대앞"))
        XCTAssertEqual(ended.body, String(format: String(localized: "shuttle.realtime.empty.ended.body"), "08:10"))
    }

    func testShuttleEmptyTextUsesNextDayDepartures() {
        let ended = ShuttleDisplayLogic.emptyText(
            destination: "한대앞", departureTimes: ["08:00:00", "22:00:00"], isWeekend: false,
            nextDayDepartureTimes: ["10:00:00", "09:30:00"], isNextDayWeekend: true
        )
        XCTAssertEqual(ended.body, String(format: String(localized: "shuttle.realtime.empty.ended.body"), "09:30"))
        XCTAssertEqual(ended.title, String(format: String(localized: "shuttle.realtime.empty.ended.title"), "한대앞"))

        let noService = ShuttleDisplayLogic.emptyText(
            destination: "한대앞", departureTimes: ["08:00:00", "22:00:00"], isWeekend: false,
            nextDayDepartureTimes: [], isNextDayWeekend: true
        )
        XCTAssertEqual(noService.body, String(localized: "shuttle.realtime.empty.ended.body.no_service_next_day"))

        let differentSchedule = ShuttleDisplayLogic.emptyText(
            destination: "한대앞", departureTimes: ["08:00:00", "22:00:00"], isWeekend: false,
            nextDayDepartureTimes: nil, isNextDayWeekend: true
        )
        XCTAssertEqual(differentSchedule.body, String(localized: "shuttle.realtime.empty.ended.body.check_timetable"))

        let sameSchedule = ShuttleDisplayLogic.emptyText(
            destination: "한대앞", departureTimes: ["08:00:00", "22:00:00"], isWeekend: false,
            nextDayDepartureTimes: nil, isNextDayWeekend: false
        )
        XCTAssertEqual(sameSchedule.body, String(format: String(localized: "shuttle.realtime.empty.ended.body"), "08:00"))
    }

    func testNextServiceDateRollsOverAtFourAM() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) throws -> Foundation.Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
        }

        let fridayNight = try date(2026, 11, 13, 23, 30)
        let saturday = ShuttleDisplayLogic.nextServiceDate(after: fridayNight, calendar: calendar)
        XCTAssertEqual(saturday, calendar.startOfDay(for: try date(2026, 11, 14, 0, 0)))
        XCTAssertTrue(calendar.isDateInWeekend(saturday))
        XCTAssertEqual(ShuttleDisplayLogic.serviceDateString(saturday, calendar: calendar), "2026-11-14")

        let saturdayEarly = try date(2026, 11, 14, 1, 30)
        XCTAssertEqual(
            ShuttleDisplayLogic.nextServiceDate(after: saturdayEarly, calendar: calendar),
            calendar.startOfDay(for: try date(2026, 11, 14, 0, 0))
        )

        let saturdayAtFour = try date(2026, 11, 14, 4, 0)
        let sunday = ShuttleDisplayLogic.nextServiceDate(after: saturdayAtFour, calendar: calendar)
        XCTAssertEqual(sunday, calendar.startOfDay(for: try date(2026, 11, 15, 0, 0)))
        XCTAssertEqual(ShuttleDisplayLogic.serviceDateString(sunday, calendar: calendar), "2026-11-15")
    }

    func testNextDayInputsRejectsTimetableOfAnotherDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        let now = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 15, hour: 20)))
        let sundayTable = ShuttleNextDayTimetable(
            date: "2026-11-15", isWeekend: true,
            departures: ["dormitory_o": ["STATION": ["09:00:00"], "TERMINAL": ["09:10:00"]]]
        )

        for destinationKey in [String?.some("STATION"), .none] {
            let result = ShuttleRealtimeTimeTableDelegate.nextDayInputs(
                table: sundayTable, boardingStop: "dormitory_o", destinationKey: destinationKey,
                now: now, calendar: calendar
            )
            XCTAssertNil(result.departureTimes)
            XCTAssertFalse(result.isWeekend)
            let text = ShuttleDisplayLogic.emptyText(
                destination: "한대앞", departureTimes: ["08:00:00"], isWeekend: true,
                nextDayDepartureTimes: result.departureTimes, isNextDayWeekend: result.isWeekend
            )
            XCTAssertEqual(text.body, String(localized: "shuttle.realtime.empty.ended.body.check_timetable"))
        }

        let absent = ShuttleRealtimeTimeTableDelegate.nextDayInputs(
            table: nil, boardingStop: "dormitory_o", destinationKey: "STATION", now: now, calendar: calendar
        )
        XCTAssertNil(absent.departureTimes)
        XCTAssertFalse(absent.isWeekend)
    }

    func testNextDayInputsUsesMatchingTimetable() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) throws -> Foundation.Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
        }
        let saturdayTable = ShuttleNextDayTimetable(
            date: "2026-11-14", isWeekend: true,
            departures: ["dormitory_o": ["STATION": ["09:30:00"], "TERMINAL": ["09:10:00"]]]
        )

        for now in [try date(2026, 11, 13, 23, 0), try date(2026, 11, 14, 1, 30)] {
            let station = ShuttleRealtimeTimeTableDelegate.nextDayInputs(
                table: saturdayTable, boardingStop: "dormitory_o", destinationKey: "STATION", now: now, calendar: calendar
            )
            XCTAssertEqual(station.departureTimes, ["09:30:00"])
            XCTAssertTrue(station.isWeekend)

            let allDestinations = ShuttleRealtimeTimeTableDelegate.nextDayInputs(
                table: saturdayTable, boardingStop: "dormitory_o", destinationKey: nil, now: now, calendar: calendar
            )
            XCTAssertEqual(allDestinations.departureTimes?.sorted(), ["09:10:00", "09:30:00"])
            XCTAssertTrue(allDestinations.isWeekend)
        }

        let missingStop = ShuttleRealtimeTimeTableDelegate.nextDayInputs(
            table: saturdayTable, boardingStop: "station", destinationKey: nil,
            now: try date(2026, 11, 13, 23, 0), calendar: calendar
        )
        XCTAssertEqual(missingStop.departureTimes, [])
    }

    private func descendants(in view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(in: $0) }
    }

    func testContactSearchEmptyCellForwardsConfiguration() {
        let cell = ContactSearchEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
    }

    func testMapSearchEmptyCellForwardsConfiguration() {
        let cell = SearchEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
    }

    func testShuttleTimetableEmptyCellForwardsConfiguration() {
        let cell = ShuttleTimetableEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
    }

    func testSubwayRealtimeEmptyCellForwardsConfiguration() {
        let cell = SubwayRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
    }

    /// Each cell must report its own analytics screen through the StateView it hosts.
    func testEmptyCellsReportExpectedSourceScreen() {
        let cases: [(UITableViewCell, AnalyticsScreen)] = [
            (ContactSearchEmptyCellView(style: .default, reuseIdentifier: nil), .contact),
            (SearchEmptyCellView(style: .default, reuseIdentifier: nil), .map),
            (ShuttleTimetableEmptyCellView(style: .default, reuseIdentifier: nil), .shuttleTimetable),
            (SubwayRealtimeEmptyCellView(style: .default, reuseIdentifier: nil), .subwayRealtime),
        ]
        for (cell, screen) in cases {
            let stateView = cell.contentView.subviews.compactMap { $0 as? StateView }.first
            XCTAssertEqual(stateView?.sourceScreen, screen, "\(type(of: cell)) reports the wrong source screen")
        }

        let expectedRawValues: [AnalyticsScreen: String] = [
            .shuttleRealtime: "shuttle_realtime",
            .busRealtime: "bus_realtime",
            .busTimetable: "bus_timetable",
            .contact: "contact",
            .map: "map",
            .shuttleTimetable: "shuttle_timetable",
            .subwayRealtime: "subway_realtime",
        ]
        for (screen, rawValue) in expectedRawValues {
            XCTAssertEqual(screen.rawValue, rawValue, "analytics raw value for \(screen) changed")
        }
    }

    private func assertForwardsConfiguration(
        _ cell: UITableViewCell,
        configure: (StateContent) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        configure(.empty(message: message))
        cell.frame = CGRect(x: 0, y: 0, width: 390, height: 260)
        cell.layoutIfNeeded()

        let texts = unavailableViews(in: cell).compactMap {
            ($0.configuration as? UIContentUnavailableConfiguration)?.attributedText?.string
        }
        XCTAssertTrue(
            texts.contains { $0.contains(message) },
            "\(type(of: cell)) did not forward the configuration to its StateView",
            file: file,
            line: line
        )
    }

    private func unavailableViews(in view: UIView) -> [UIContentUnavailableView] {
        var found: [UIContentUnavailableView] = []
        if let unavailable = view as? UIContentUnavailableView {
            found.append(unavailable)
        }
        for subview in view.subviews {
            found.append(contentsOf: unavailableViews(in: subview))
        }
        return found
    }
}
