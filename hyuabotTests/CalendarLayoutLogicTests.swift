//
//  CalendarLayoutLogicTests.swift
//  hyuabot
//

import XCTest
@testable import hyuabot

final class CalendarLayoutLogicTests: XCTestCase {
    private let weekDays = [
        "2026-11-22", "2026-11-23", "2026-11-24", "2026-11-25",
        "2026-11-26", "2026-11-27", "2026-11-28"
    ]

    private func span(_ id: Int, _ start: String, _ end: String, category: Int = 1) -> CalendarSpan {
        CalendarSpan(id: id, start: start, end: end, categoryID: category)
    }

    func testWeekLayoutSingleSpan() {
        let layout = CalendarLayoutLogic.weekLayout(
            weekDays: weekDays, monthKey: "2026-11", spans: [span(1, "2026-11-24", "2026-11-26")]
        )
        XCTAssertEqual(layout.bars, [CalendarBarSegment(
            spanID: 1, categoryID: 1, slot: 0, startCol: 2, endCol: 4,
            roundLeft: true, roundRight: true, showsLabel: true, dimmed: false
        )])
        XCTAssertEqual(layout.totals, [0, 0, 1, 1, 1, 0, 0])
        XCTAssertTrue(layout.overflow.isEmpty)
    }

    func testWeekLayoutContinuesFromPreviousWeek() {
        let layout = CalendarLayoutLogic.weekLayout(
            weekDays: weekDays, monthKey: "2026-11", spans: [span(1, "2026-11-20", "2026-11-23")]
        )
        XCTAssertEqual(layout.bars.first?.startCol, 0)
        XCTAssertEqual(layout.bars.first?.roundLeft, false)
        XCTAssertEqual(layout.bars.first?.roundRight, true)
    }

    func testWeekLayoutThreeOverlapOverflow() {
        let spans = (1...3).map { span($0, "2026-11-25", "2026-11-25") }
        let layout = CalendarLayoutLogic.weekLayout(weekDays: weekDays, monthKey: "2026-11", spans: spans)
        XCTAssertEqual(layout.bars, [CalendarBarSegment(
            spanID: 1, categoryID: 1, slot: 0, startCol: 3, endCol: 3,
            roundLeft: true, roundRight: true, showsLabel: true, dimmed: false
        )])
        XCTAssertEqual(layout.totals[3], 3)
        XCTAssertEqual(layout.overflow, [3: 2])
    }

    func testWeekLayoutSplitsSlotOne() {
        let spans = [
            span(1, "2026-11-22", "2026-11-28"), span(2, "2026-11-22", "2026-11-27"),
            span(3, "2026-11-25", "2026-11-25"), span(4, "2026-11-25", "2026-11-25")
        ]
        let layout = CalendarLayoutLogic.weekLayout(weekDays: weekDays, monthKey: "2026-11", spans: spans)
        XCTAssertEqual(layout.bars, [
            CalendarBarSegment(spanID: 1, categoryID: 1, slot: 0, startCol: 0, endCol: 6,
                               roundLeft: true, roundRight: true, showsLabel: true, dimmed: false),
            CalendarBarSegment(spanID: 2, categoryID: 1, slot: 1, startCol: 0, endCol: 2,
                               roundLeft: true, roundRight: true, showsLabel: true, dimmed: false),
            CalendarBarSegment(spanID: 2, categoryID: 1, slot: 1, startCol: 4, endCol: 5,
                               roundLeft: true, roundRight: true, showsLabel: false, dimmed: false)
        ])
        XCTAssertEqual(layout.totals[3], 4)
        XCTAssertEqual(layout.overflow, [3: 3])
    }

    func testWeekLayoutDimsOtherMonth() {
        let days = ["2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-29", "2026-10-30", "2026-10-31"]
        let layout = CalendarLayoutLogic.weekLayout(
            weekDays: days, monthKey: "2026-11", spans: [span(1, "2026-10-26", "2026-10-27")]
        )
        XCTAssertEqual(layout.bars.first?.dimmed, true)
    }

    func testMonthHasEvents() {
        let spans = [span(1, "2026-10-31", "2026-11-01"), span(2, "2026-12-01", "2026-12-02")]
        XCTAssertTrue(CalendarLayoutLogic.monthHasEvents(monthKey: "2026-11", spans: spans))
        XCTAssertFalse(CalendarLayoutLogic.monthHasEvents(monthKey: "2026-09", spans: spans))
    }

    func testPanelSpanIDs() {
        let spans = [span(3, "2026-11-03", "2026-11-05"), span(1, "2026-11-01", "2026-11-04")]
            + (0..<5).map { span($0 + 4, "2026-11-\($0 + 6)", "2026-11-\($0 + 6)") }
        XCTAssertEqual(CalendarLayoutLogic.panelSpanIDs(spans: spans, selectedDay: "2026-11-03", today: "2026-11-01"), [1, 3])
        XCTAssertEqual(CalendarLayoutLogic.panelSpanIDs(spans: spans, selectedDay: nil, today: "2026-11-01").count, 5)
    }

    func testToggledHidden() {
        XCTAssertEqual(CalendarLayoutLogic.toggledHidden([], toggling: 1, allIDs: [1, 2]), [1])
        XCTAssertEqual(CalendarLayoutLogic.toggledHidden([1], toggling: 1, allIDs: [1, 2]), [])
        XCTAssertEqual(CalendarLayoutLogic.toggledHidden([1], toggling: 2, allIDs: [1, 2]), [1])
    }

    func testCategoryItems() {
        XCTAssertEqual(
            CalendarLayoutLogic.categoryItems([(id: 3, name: "셋"), (id: 1, name: "하나"), (id: 3, name: "중복")]),
            [CalendarCategoryItem(id: 1, name: "하나"), CalendarCategoryItem(id: 3, name: "셋")]
        )
    }

    func testMetaText() {
        let locale = Locale(identifier: "ko_KR")
        XCTAssertEqual(
            CalendarLayoutLogic.metaText(
                categoryName: "학사", start: "2026-11-24", end: "2026-11-24", locale: locale
            ),
            "학사 · 11.24 (화)"
        )
        XCTAssertEqual(
            CalendarLayoutLogic.metaText(
                categoryName: "학사", start: "2026-11-24", end: "2026-11-26", locale: locale
            ),
            "학사 · 11.24 (화) – 11.26 (목)"
        )
    }
}
