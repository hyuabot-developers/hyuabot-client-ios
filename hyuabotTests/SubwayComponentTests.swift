//
//  SubwayComponentTests.swift
//  hyuabotTests
//
@testable import hyuabot
import XCTest

@MainActor
final class SubwayComponentTests: XCTestCase {
    func testBadgeSizesAndLongLabel() {
        let regular = SubwayLineBadgeView(size: .regular)
        regular.configure(.line(.line4))
        XCTAssertEqual(fit(regular).height, 24, accuracy: 1)
        XCTAssertEqual(fit(regular).width, 24, accuracy: 1)
        let large = SubwayLineBadgeView(size: .large)
        large.configure(.line(.line4))
        XCTAssertEqual(fit(large).height, 28, accuracy: 1)
        XCTAssertEqual(fit(large).width, 28, accuracy: 1)
        let suin = SubwayLineBadgeView(size: .regular)
        suin.configure(.line(.suin))
        XCTAssertEqual(fit(suin).height, 24, accuracy: 1)
        XCTAssertGreaterThan(fit(suin).width, 24)
    }

    func testSegmentHeightAndAccessibilityIdentifier() throws {
        let view = SubwaySegmentView(buttonIdentifierPrefix: "viewpager.tab")
        view.configure(items: [item("1"), item("2"), item("3")], selected: 0)
        XCTAssertEqual(fit(view).height, 44, accuracy: 1)
        XCTAssertEqual(try XCTUnwrap(view.button(at: 2)).accessibilityIdentifier, "viewpager.tab.2")
    }

    func testArrivalSubtitleHeight() {
        let row = SubwayArrivalRowView()
        row.configure(arrival(subtitle: "곧 도착"), showsSeparator: false)
        XCTAssertEqual(fit(row).height, 68, accuracy: 1)
    }

    func testSectionCardEmptyAndFourArrivalHeights() {
        let empty = SubwaySectionCardView()
        empty.configure(section(rows: []))
        XCTAssertGreaterThan(fit(empty).height, 48)
        let four = SubwaySectionCardView()
        four.configure(section(rows: Array(repeating: arrival(subtitle: "곧 도착"), count: 4)))
        XCTAssertEqual(fit(four).height, 48 + 1 + 4 * 68, accuracy: 1)
    }

    func testCompactBarRevealAndAccessibility() {
        XCTAssertEqual(SubwayCompactBarView.revealProgress(contentOffsetY: 36, adjustedTopInset: 0), 0, accuracy: 0.001)
        XCTAssertEqual(SubwayCompactBarView.revealProgress(contentOffsetY: 44, adjustedTopInset: 0), 0.5, accuracy: 0.001)
        XCTAssertEqual(SubwayCompactBarView.revealProgress(contentOffsetY: 52, adjustedTopInset: 0), 1, accuracy: 0.001)
        XCTAssertEqual(SubwayCompactBarView.revealProgress(contentOffsetY: -47, adjustedTopInset: 47), 0, accuracy: 0.001)
        XCTAssertEqual(SubwayCompactBarView.revealProgress(contentOffsetY: -3, adjustedTopInset: 47), 0.5, accuracy: 0.001)
        let bar = SubwayCompactBarView(maxTitleWidth: nil)
        bar.setRevealProgress(0.4)
        XCTAssertEqual(bar.alpha, 0.4, accuracy: 0.001)
        XCTAssertTrue(bar.accessibilityElementsHidden)
        bar.setRevealProgress(1)
        XCTAssertFalse(bar.accessibilityElementsHidden)
    }

    private func fit(_ view: UIView) -> CGSize {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        return view.systemLayoutSizeFitting(
            CGSize(width: 358, height: 0), withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }

    private func item(_ title: String) -> SubwaySegmentView.Item {
        .init(title: title, dotColors: [SubwayRouteLine.line4.color], count: nil)
    }

    private func arrival(subtitle: String?) -> SubwayArrivalRowModel {
        .init(
            destination: "인천",
            minutesText: "3분",
            subtitle: subtitle,
            isRealtime: true,
            isSoon: false,
            isLast: false,
            accessibilityLabel: "인천 3분"
        )
    }

    private func section(rows: [SubwayArrivalRowModel]) -> SubwaySectionContent {
        .init(
            badge: .line(.line4),
            title: "인천 방면",
            timetable: nil,
            rows: .arrivals(rows),
            emptyMessage: "도착 정보가 없습니다."
        )
    }
}
