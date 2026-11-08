//
//  CafeteriaDisplayLogicTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class CafeteriaDisplayLogicTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? .distantPast
    }

    private func menu(_ type: String, _ food: String, _ price: String = "") -> CafeteriaMenuSource {
        CafeteriaMenuSource(type: type, food: food, price: price)
    }

    func testMenuRowParsesTagMainSidesAndKoreanFood() {
        let row = CafeteriaDisplayLogic.menuRow(
            food: "[천원의 아침밥] 고추참치김밥/과채데이, 쌀밥, 야채샐러드*드레싱",
            price: "",
            korean: true
        )
        XCTAssertEqual(row.tag, "천원의 아침밥")
        XCTAssertEqual(row.main, "고추참치김밥/과채데이")
        XCTAssertEqual(row.sides, "쌀밥 · 야채샐러드*드레싱")

        let otherTag = CafeteriaDisplayLogic.menuRow(food: "[특식] 돈까스, 쌀밥", price: "", korean: true)
        XCTAssertNil(otherTag.tag)
        XCTAssertEqual(otherTag.main, "돈까스")

        let koreanRow = CafeteriaDisplayLogic.menuRow(
            food: "닭곰탕&소면사리 Chicken Gomtang & Thin Noodles, 언양식불고기",
            price: "",
            korean: true
        )
        XCTAssertEqual(koreanRow.main, "닭곰탕&소면사리")
        XCTAssertEqual(koreanRow.sides, "언양식불고기")
        XCTAssertNil(koreanRow.tag)

        let englishRow = CafeteriaDisplayLogic.menuRow(
            food: "닭곰탕&소면사리 Chicken Gomtang & Thin Noodles, 언양식불고기",
            price: "",
            korean: false
        )
        XCTAssertEqual(englishRow.main, "닭곰탕&소면사리 Chicken Gomtang & Thin Noodles")
        XCTAssertEqual(englishRow.sides, "언양식불고기")
    }

    func testPriceTextTrimsAndFormatsPrice() {
        let expected = String(format: String(localized: "cafeteria.price.format"), "6,500")
        XCTAssertEqual(CafeteriaDisplayLogic.priceText("6,500"), expected)
        XCTAssertEqual(CafeteriaDisplayLogic.priceText(" 6,500원 "), expected)
        XCTAssertNil(CafeteriaDisplayLogic.priceText(""))
    }

    func testTimeRangeTextFormatsRangeAndRejectsUnknownTimes() {
        XCTAssertEqual(CafeteriaDisplayLogic.timeRangeText("07:40~09:00"), "07:40–09:00")
        XCTAssertEqual(CafeteriaDisplayLogic.timeRangeText("07:40 ~ 09:00"), "07:40–09:00")
        XCTAssertNil(CafeteriaDisplayLogic.timeRangeText(nil))
        XCTAssertNil(CafeteriaDisplayLogic.timeRangeText("운영시간 미정"))
    }

    func testCardStatusAndOpenThresholds() {
        struct Case {
            let hour: Int
            let minute: Int
            let expected: CafeteriaCardStatus
        }
        let cases: [Case] = [
            Case(hour: 11, minute: 29, expected: .beforeOpen),
            Case(hour: 11, minute: 30, expected: .open),
            Case(hour: 12, minute: 59, expected: .open),
            Case(hour: 13, minute: 0, expected: .closingSoon),
            Case(hour: 13, minute: 30, expected: .closingSoon),
            Case(hour: 13, minute: 31, expected: .closed)
        ]
        for testCase in cases {
            let (hour, minute, expected) = (testCase.hour, testCase.minute, testCase.expected)
            let now = makeDate(year: 2026, month: 11, day: 11, hour: hour, minute: minute)
            XCTAssertEqual(
                CafeteriaDisplayLogic.cardStatus(runningTime: "11:30~13:30", now: now, calendar: calendar),
                expected
            )
        }
        XCTAssertNil(CafeteriaDisplayLogic.cardStatus(runningTime: nil, now: makeDate(year: 2026, month: 11, day: 11), calendar: calendar))
        XCTAssertTrue(CafeteriaDisplayLogic.isOpen(
            runningTime: "11:30~13:30",
            now: makeDate(year: 2026, month: 11, day: 11, hour: 11, minute: 30),
            calendar: calendar
        ))
        XCTAssertTrue(CafeteriaDisplayLogic.isOpen(
            runningTime: "11:30~13:30",
            now: makeDate(year: 2026, month: 11, day: 11, hour: 13, minute: 30),
            calendar: calendar
        ))
        XCTAssertFalse(CafeteriaDisplayLogic.isOpen(
            runningTime: "11:30~13:30",
            now: makeDate(year: 2026, month: 11, day: 11, hour: 13, minute: 31),
            calendar: calendar
        ))
    }

    func testSourcesCountsAndCardsAreMealSpecificAndSorted() {
        let sources = [
            CafeteriaSource(
                seq: 13,
                runningTimes: [nil, "11:30~13:30", nil],
                menus: [menu("조식", "아침"), menu("중식", "점심 13"), menu("석식", "저녁")]
            ),
            CafeteriaSource(seq: 11, runningTimes: [nil, "11:30~13:30", nil], menus: [menu("중식", "점심 11"), menu("조식", "아침 11")]),
            CafeteriaSource(seq: 12, runningTimes: [nil, "11:30~13:30", nil], menus: [menu("중식", "점심 12"), menu("조식", "아침 12")])
        ]
        XCTAssertEqual(CafeteriaDisplayLogic.sources(sources, for: .lunch).map(\.seq), [11, 12, 13])
        XCTAssertEqual(CafeteriaDisplayLogic.counts(from: sources), [.breakfast: 3, .lunch: 3, .dinner: 1])
        let cards = CafeteriaDisplayLogic.cards(
            from: sources,
            meal: .lunch,
            showsStatus: false,
            now: makeDate(year: 2026, month: 11, day: 11),
            calendar: calendar,
            korean: true
        )
        XCTAssertTrue(cards.allSatisfy { $0.status == nil })
        XCTAssertTrue(cards.allSatisfy { $0.rows.count == 1 && $0.rows[0].main.hasPrefix("점심") })
    }

    func testEmptyStateUsesAvailableMealAsAlternative() {
        XCTAssertEqual(
            CafeteriaDisplayLogic.emptyState(selected: .lunch, counts: [.lunch: 0, .breakfast: 2]),
            .noMenusForMeal(alternative: .breakfast)
        )
        XCTAssertEqual(CafeteriaDisplayLogic.emptyState(selected: .lunch, counts: [:]), .noMenusForDay)
        XCTAssertNil(CafeteriaDisplayLogic.emptyState(selected: .lunch, counts: [.lunch: 1]))
        XCTAssertEqual(
            CafeteriaDisplayLogic.emptyState(selected: .dinner, counts: [.lunch: 1, .breakfast: 1, .dinner: 0]),
            .noMenusForMeal(alternative: .lunch)
        )
    }

    func testWeekDaysStartMondayAndMarkTodayAndSelection() {
        let days = CafeteriaDisplayLogic.weekDays(
            selected: makeDate(year: 2026, month: 11, day: 11),
            today: makeDate(year: 2026, month: 11, day: 9),
            calendar: calendar
        )
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.map(\.day), Array(9 ... 15))
        XCTAssertEqual(days.first?.weekday, 2)
        XCTAssertEqual(days.last?.weekday, 1)
        XCTAssertEqual(days.filter(\.isToday).map(\.day), [9])
        XCTAssertEqual(days.filter(\.isSelected).map(\.day), [11])

        let sunday = CafeteriaDisplayLogic.weekDays(
            selected: makeDate(year: 2026, month: 11, day: 15),
            today: makeDate(year: 2026, month: 11, day: 9),
            calendar: calendar
        )
        XCTAssertEqual(sunday.map(\.day), Array(9 ... 15))
    }

    func testShareTextIncludesCafeteriaNameAndPrice() throws {
        XCTAssertNil(CafeteriaDisplayLogic.shareText(sources: [], meal: .lunch, date: makeDate(year: 2026, month: 11, day: 11)))
        let source = CafeteriaSource(
            seq: 13,
            runningTimes: [nil, "11:30~13:30", nil],
            menus: [menu("중식", "김치찌개", "6,500")]
        )
        let date = makeDate(year: 2026, month: 11, day: 11)
        let text = CafeteriaDisplayLogic.shareText(sources: [source], meal: .lunch, date: date)
        let unwrapped = try XCTUnwrap(text)
        XCTAssertTrue(unwrapped.contains(CafeteriaDisplayLogic.cafeteriaName(seq: 13)))
        XCTAssertTrue(unwrapped.contains("6,500원"))
    }
}
