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

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}
