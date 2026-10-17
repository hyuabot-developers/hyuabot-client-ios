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

    func testShuttleRealtimeEmptyCellForwardsConfiguration() {
        let cell = ShuttleRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
    }

    func testBusRealtimeEmptyCellForwardsConfiguration() {
        let cell = BusRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
    }

    func testBusTimetableEmptyCellForwardsConfiguration() {
        let cell = BusTimetableEmptyCellView(style: .default, reuseIdentifier: nil)
        assertForwardsConfiguration(cell) { cell.configure($0) }
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
            (ShuttleRealtimeEmptyCellView(style: .default, reuseIdentifier: nil), .shuttleRealtime),
            (BusRealtimeEmptyCellView(style: .default, reuseIdentifier: nil), .busRealtime),
            (BusTimetableEmptyCellView(style: .default, reuseIdentifier: nil), .busTimetable),
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
