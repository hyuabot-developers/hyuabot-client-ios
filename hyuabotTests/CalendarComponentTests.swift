//
//  CalendarComponentTests.swift
//  hyuabot
//
@testable import hyuabot
import XCTest

@MainActor
final class CalendarComponentTests: XCTestCase {
    func testCalendarCategoryTokensResolveAndCycle() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let strongOne = SettingsStyle.Color.calendarCategoryStrong(1).resolvedColor(with: light)
        let strongFive = SettingsStyle.Color.calendarCategoryStrong(5).resolvedColor(with: light)
        XCTAssertEqual(strongOne, strongFive)

        let fill = SettingsStyle.Color.calendarCategoryFill(4).resolvedColor(with: light)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(fill.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        XCTAssertEqual(red, 0xF3 / 255, accuracy: 0.01)
        XCTAssertEqual(green, 0xE8 / 255, accuracy: 0.01)
        XCTAssertEqual(blue, 0xFF / 255, accuracy: 0.01)
    }

    func testCalendarHeaderAccessibilityAndFilterSelection() {
        let today = CalendarTodayPillView()
        XCTAssertEqual(today.accessibilityIdentifier, "calendar.today_button")
        XCTAssertEqual(today.accessibilityLabel, String(localized: "calendar.today.accessibility"))
        XCTAssertEqual(today.intrinsicContentSize.height, 44)

        let filter = CalendarCategoryFilterView()
        let items = [CalendarCategoryItem(id: 1, name: "Academic"), CalendarCategoryItem(id: 2, name: "Social")]
        filter.configure(items: items, hidden: [2])
        let chip = descendants(of: filter).compactMap { $0 as? UIControl }
            .first { $0.accessibilityIdentifier == "calendar.category_chip.1" }
        XCTAssertNotNil(chip)
        XCTAssertTrue(chip?.accessibilityTraits.contains(.selected) == true)
        let hiddenChip = descendants(of: filter).compactMap { $0 as? UIControl }
            .first { $0.accessibilityIdentifier == "calendar.category_chip.2" }
        XCTAssertFalse(hiddenChip?.accessibilityTraits.contains(.selected) == true)
        var toggledID: Int?
        filter.onToggle = { toggledID = $0 }
        chip?.sendActions(for: .touchUpInside)
        XCTAssertEqual(toggledID, 1)
        XCTAssertEqual(filter.intrinsicContentSize.height, 44)
    }

    func testCalendarPanelAndDayCellPresentConfiguredAccessibility() {
        let header = CalendarPanelHeaderView()
        header.configure(title: "x", count: nil, showsClear: false)
        XCTAssertEqual(header.clearButton.accessibilityIdentifier, "calendar.clear_selection")
        XCTAssertTrue(header.clearButton.isHidden)
        header.configure(title: "x", count: 2, showsClear: true)
        XCTAssertFalse(header.clearButton.isHidden)

        let hint = CalendarHintLabel()
        XCTAssertEqual(hint.numberOfLines, 1)

        let cell = CalendarGridCell(frame: .zero)
        cell.configure(CalendarDayConfiguration(
            day: 24, weekdayIndex: 2, isCurrentMonth: true, isToday: false,
            isSelected: true, showsTopBorder: true, accessibilityText: "x"
        ))
        XCTAssertEqual(cell.accessibilityLabel, "x")
        XCTAssertTrue(cell.accessibilityTraits.contains(.selected))
        XCTAssertEqual(CalendarGridCell.rowHeight, 71)
    }

    func testCalendarLocalizationKeysResolveAndFormatCounts() {
        let keys = ["calendar.today", "calendar.today.accessibility", "calendar.previous_month.accessibility",
                    "calendar.next_month.accessibility", "calendar.filter.accessibility", "calendar.clear_selection",
                    "calendar.count", "calendar.loading", "calendar.empty.selected.title",
                    "calendar.empty.selected.caption", "calendar.empty.upcoming.caption",
                    "calendar.empty.hidden.caption", "calendar.swipe.hint", "calendar.day.events_count",
                    "calendar.day.no_events"]
        for key in keys {
            XCTAssertNotEqual(String(localized: String.LocalizationValue(key)), key, "Missing localization: \(key)")
        }
    }

    private func descendants(of view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(descendants(of:))
    }

    private func labels(in view: UIView) -> [UILabel] {
        descendants(of: view).compactMap { $0 as? UILabel }
    }
}
