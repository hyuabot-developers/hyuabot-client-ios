//
//  SubwayTimetableComponentTests.swift
//  hyuabotTests
//
@testable import hyuabot
import XCTest

@MainActor
final class SubwayTimetableComponentTests: XCTestCase {
    func testRowCellUsesFortyFourPointHeight() {
        let cell = SubwayTimetableRowCell(style: .default, reuseIdentifier: nil)
        cell.configure(row(), merged: true)
        let size = cell.contentView.systemLayoutSizeFitting(
            CGSize(width: 390, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        XCTAssertEqual(size.height, 44)
    }

    func testHourHeaderHeights() {
        let group = SubwayTimetableHourGroup(hour: 8, title: "08:00", accessibilityLabel: "08:00", rows: [])
        let first = SubwayTimetableHourHeaderView(reuseIdentifier: nil)
        first.configure(group, isFirst: true, roundsTop: true)
        let following = SubwayTimetableHourHeaderView(reuseIdentifier: nil)
        following.configure(group, isFirst: false, roundsTop: false)
        XCTAssertEqual(first.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 32)
        XCTAssertEqual(following.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height, 26)
    }

    func testMergedDownHeaderHasLegend() {
        let down = header(line: .line4, heading: .down)
        let up = header(line: .line4, heading: .up)
        let width = CGFloat(390)
        let downHeight = down.systemLayoutSizeFitting(CGSize(width: width, height: 0)).height
        let upHeight = up.systemLayoutSizeFitting(CGSize(width: width, height: 0)).height
        XCTAssertGreaterThan(downHeight, upHeight)
    }

    func testFooterReservesSpaceForCardAndFootnote() {
        let footer = SubwayTimetableCardFooterView()
        footer.configure(showsCard: true, showsFootnote: true)
        XCTAssertGreaterThan(footer.fittingHeight(width: 390), 60)
    }

    func testHiddenPastCountAddsHeaderHeight() {
        let normal = header(line: .line4, heading: .up, hiddenPastCount: 0)
        let folded = header(line: .line4, heading: .up, hiddenPastCount: 3)
        let size = CGSize(width: 390, height: 0)
        XCTAssertGreaterThan(folded.systemLayoutSizeFitting(size).height, normal.systemLayoutSizeFitting(size).height)
    }

    private func header(line: SubwayLine, heading: SubwayHeadingEnum, hiddenPastCount: Int = 0) -> SubwayTimetableHeaderView {
        let view = SubwayTimetableHeaderView()
        view.configure(
            line: line,
            heading: heading,
            day: .weekdays,
            weekdayCount: nil,
            weekendCount: nil,
            isLoading: false,
            hiddenPastCount: hiddenPastCount
        )
        return view
    }

    private func row() -> SubwayTimetableRowModel {
        SubwayTimetableRowModel(
            timeText: "08:00",
            destination: "Seoul",
            line: .line4,
            isPast: false,
            isNext: false,
            nextText: nil,
            isFirst: false,
            isLast: false,
            accessibilityLabel: "08:00 Seoul"
        )
    }
}
