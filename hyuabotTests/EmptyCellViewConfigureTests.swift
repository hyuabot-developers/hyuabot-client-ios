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

    func testShuttleRealtimeEmptyCellShowsTitleAndBody() {
        let cell = ShuttleRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        cell.configure(title: "운행 종료", body: "내일 첫차 08:00")
        let labels = descendants(in: cell).compactMap { $0 as? UILabel }
        XCTAssertEqual(labels.map(\.text), ["운행 종료", "내일 첫차 08:00"])
        XCTAssertEqual(labels.map { $0.font.pointSize }, [15, 13])
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
