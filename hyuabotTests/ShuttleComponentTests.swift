//
//  ShuttleComponentTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

@MainActor
final class ShuttleComponentTests: XCTestCase {
    func testShuttleRealtimeTitleBarIdentifiersAndHeight() {
        let titleBar = ShuttleRealtimeTitleBar()
        XCTAssertEqual(titleBar.settingsButton.accessibilityIdentifier, "shuttle.quick_settings")
        titleBar.layoutIfNeeded()
        XCTAssertEqual(titleBar.constraints.first { $0.firstAttribute == .height }?.constant, 56)
    }

    func testShuttleRealtimeHeaderIdentifiersAndPresenceState() throws {
        let header = ShuttleRealtimeListHeaderView(stopTitles: ["North", "South", "West"])
        XCTAssertEqual(header.noticeBar.accessibilityIdentifier, "shuttle.notice.bar")
        XCTAssertEqual(header.stopInfoButton.accessibilityIdentifier, "shuttle.stop_info")
        let tabs = descendants(of: header.segmentView).compactMap { $0 as? UIButton }
        XCTAssertTrue(tabs.contains { $0.accessibilityIdentifier == "viewpager.tab.0" })

        header.setPresence(text: "3 min", accessibilityLabel: "3 minutes", dotColor: .systemGreen)
        let pill = try XCTUnwrap(descendants(of: header).first { $0.accessibilityLabel == "3 minutes" })
        XCTAssertFalse(pill.isHidden)
        header.setPresence(text: nil, accessibilityLabel: nil, dotColor: nil)
        XCTAssertTrue(pill.isHidden)
    }

    func testPresencePillHugsText() throws {
        let header = ShuttleRealtimeListHeaderView(stopTitles: ["North", "South", "West"])
        header.setPresence(text: "3", accessibilityLabel: "3", dotColor: .systemGreen)
        header.frame = CGRect(x: 0, y: 0, width: 390, height: 200)
        header.setNeedsLayout()
        header.layoutIfNeeded()

        let label = try XCTUnwrap(descendants(of: header).compactMap { $0 as? UILabel }.first { $0.text == "3" })
        let pill = try XCTUnwrap(label.superview?.superview)
        XCTAssertLessThan(pill.bounds.width, 80)
        XCTAssertGreaterThan(pill.bounds.width, 0)
    }

    func testShuttleTimetableHeaderIdentifiersAndBadgeMetrics() {
        let header = ShuttleTimetableHeaderView()
        XCTAssertEqual(header.routeButton.accessibilityIdentifier, "shuttle.timetable.route")
        XCTAssertTrue(descendants(of: header.daySegment).compactMap { $0 as? UIButton }.contains {
            $0.accessibilityIdentifier == "shuttle.timetable.day.0"
        })

        let badge = BusRouteBadgeView(size: .shuttle)
        XCTAssertEqual(badge.intrinsicContentSize.height, 20, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(badge.intrinsicContentSize.width, 44)
    }

    func testCompactBusTransferRowShowsRealtimeThenLog() throws {
        let realtime = transferEntry(minutes: 3, stops: 2, source: .realtime, clockTime: nil)
        let log = transferEntry(
            minutes: nil,
            stops: nil,
            source: .arrivalLog,
            clockTime: Foundation.Date(timeIntervalSince1970: 1_794_456_000)
        )
        let view = ShuttleCompactTransferRowView(row: transferRow(timeline: [realtime, log]))
        let texts = visibleTexts(view)
        XCTAssertTrue(texts.contains(try XCTUnwrap(log.scheduledArrivalText)))
        XCTAssertTrue(texts.contains { $0.contains(minuteText(3)) })
        XCTAssertTrue(try XCTUnwrap(view.accessibilityLabel).contains(try XCTUnwrap(log.scheduledArrivalText)))
    }

    func testCompactBusTransferRowShowsLogOnly() throws {
        let first = transferEntry(
            minutes: nil, stops: nil, source: .arrivalLog,
            clockTime: Foundation.Date(timeIntervalSince1970: 1_794_456_000)
        )
        let second = transferEntry(
            minutes: nil, stops: nil, source: .arrivalLog,
            clockTime: Foundation.Date(timeIntervalSince1970: 1_794_456_600)
        )
        let view = ShuttleCompactTransferRowView(row: transferRow(timeline: [first, second]))
        let texts = visibleTexts(view)
        XCTAssertTrue(texts.contains(try XCTUnwrap(first.scheduledArrivalText)))
        XCTAssertTrue(texts.contains(try XCTUnwrap(second.scheduledArrivalText)))
        XCTAssertTrue(try XCTUnwrap(view.accessibilityLabel).contains(try XCTUnwrap(first.scheduledArrivalText)))
        XCTAssertTrue(try XCTUnwrap(view.accessibilityLabel).contains(try XCTUnwrap(second.scheduledArrivalText)))
    }

    func testCompactBusTransferRowShowsTwoRealtimeArrivals() {
        let first = transferEntry(minutes: 3, stops: 2, source: .realtime, clockTime: nil)
        let second = transferEntry(minutes: 7, stops: 4, source: .realtime, clockTime: nil)
        let view = ShuttleCompactTransferRowView(row: transferRow(timeline: [first, second]))
        let texts = visibleTexts(view)
        XCTAssertTrue(texts.contains { $0.contains(minuteText(3)) })
        XCTAssertTrue(texts.contains { $0.contains(minuteText(7)) })
    }

    func testCompactBusTransferRowHandlesEmptyTimeline() {
        let view = ShuttleCompactTransferRowView(row: transferRow(timeline: []))
        XCTAssertEqual(view.accessibilityLabel, "50")
        XCTAssertEqual(ShuttleCompactTransferRowView.rowHeight, 48)
    }

    func testCompactSubwayTransferRowStaysSingleLine() throws {
        let first = transferEntry(
            minutes: nil, stops: nil, source: .arrivalLog,
            clockTime: Foundation.Date(timeIntervalSince1970: 1_794_456_000)
        )
        let second = transferEntry(
            minutes: nil, stops: nil, source: .arrivalLog,
            clockTime: Foundation.Date(timeIntervalSince1970: 1_794_456_600)
        )
        let row = TransferRow(name: "50", targetName: "Terminal", color: .systemGreen, vehicleType: .subway, timeline: [first, second])
        let texts = visibleTexts(ShuttleCompactTransferRowView(row: row))
        XCTAssertTrue(texts.contains(try XCTUnwrap(first.scheduledArrivalText)))
        XCTAssertFalse(texts.contains(try XCTUnwrap(second.scheduledArrivalText)))
    }

    private func transferEntry(
        minutes: Int?,
        stops: Int?,
        source: TransferTimelineSource,
        clockTime: Foundation.Date?
    ) -> TransferTimelineEntry {
        TransferTimelineEntry(
            destination: "Terminal",
            minutes: minutes,
            stops: stops,
            locationLabel: nil,
            direction: -1,
            source: source,
            clockTime: clockTime,
            waitingMinutes: nil
        )
    }

    private func transferRow(timeline: [TransferTimelineEntry]) -> TransferRow {
        TransferRow(name: "50", targetName: "Terminal", color: .systemGreen, vehicleType: .bus, timeline: timeline)
    }

    private func minuteText(_ minutes: Int) -> String {
        String(format: String(localized: "home.minutes"), locale: Locale.current, minutes)
    }

    private func visibleTexts(_ view: UIView) -> [String] {
        descendants(of: view)
            .compactMap { $0 as? UILabel }
            .filter { !$0.isHidden }
            .compactMap(\.text)
            .filter { !$0.isEmpty }
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}
