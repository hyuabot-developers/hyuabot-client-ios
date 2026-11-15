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

    func testCalendarEventBarColorsUseCategoryColorsUnlessDimmed() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let standard = SettingsStyle.Color.calendarEventBarColors(categoryID: 2, dimmed: false)
        XCTAssertEqual(standard.fill.resolvedColor(with: light), SettingsStyle.Color.calendarCategoryFill(2).resolvedColor(with: light))
        XCTAssertEqual(standard.text.resolvedColor(with: light), SettingsStyle.Color.calendarCategoryStrong(2).resolvedColor(with: light))

        let dimmed = SettingsStyle.Color.calendarEventBarColors(categoryID: 2, dimmed: true)
        XCTAssertEqual(dimmed.fill.resolvedColor(with: light), SettingsStyle.Color.calendarDimmedBarFill.resolvedColor(with: light))
        XCTAssertEqual(dimmed.text.resolvedColor(with: light), SettingsStyle.Color.calendarDimmedBarText.resolvedColor(with: light))
    }

    func testCalendarEventBarColorsMeetContrast() {
        for categoryID in 1...4 {
            for dimmed in [false, true] {
                for style in [UIUserInterfaceStyle.light, .dark] {
                    let traits = UITraitCollection(userInterfaceStyle: style)
                    let colors = SettingsStyle.Color.calendarEventBarColors(categoryID: categoryID, dimmed: dimmed)
                    let contrast = contrastRatio(colors.text, colors.fill, traits: traits)
                    XCTAssertGreaterThanOrEqual(
                        contrast, 4.5,
                        "Category \(categoryID), dimmed \(dimmed), style \(style) contrast was \(contrast)"
                    )
                }
            }
        }
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

    private func contrastRatio(_ first: UIColor, _ second: UIColor, traits: UITraitCollection) -> CGFloat {
        let firstLuminance = relativeLuminance(first.resolvedColor(with: traits))
        let secondLuminance = relativeLuminance(second.resolvedColor(with: traits))
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        let components = [red, green, blue].map { component -> CGFloat in
            component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * components[0] + 0.7152 * components[1] + 0.0722 * components[2]
    }
}
