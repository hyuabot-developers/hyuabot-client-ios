//
//  AppIntentCafeteriaTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AppIntentCafeteriaTests: XCTestCase {
    func testCurrentMealAtSeoulBoundaries() throws {
        let calendar = IntentClock.seoulCalendar
        for (hour, expected) in [(9, CafeteriaMealOption.breakfast), (10, .lunch), (14, .lunch), (15, .dinner), (21, .dinner)] {
            let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: hour)))
            XCTAssertEqual(CafeteriaMealOption.current(at: date, calendar: calendar), expected)
        }
    }

    func testRowsFilterMealAndSortByCafeteria() {
        let cafeterias = [makeCafeteria(seq: 2), makeCafeteria(seq: 1)]
        let rows = CafeteriaIntentLogic.rows(for: .lunch, restaurant: nil, cafeterias: cafeterias)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows.map(\.title), [CafeteriaIntentLogic.cafeteriaName(seq: 1), CafeteriaIntentLogic.cafeteriaName(seq: 2)])
        XCTAssertEqual(rows.map(\.detail), ["밥, 국", "밥, 국"])
    }

    func testRowsFilterSelectedRestaurant() {
        let rows = CafeteriaIntentLogic.rows(
            for: .lunch, restaurant: .studentUnion, cafeterias: [makeCafeteria(seq: 2), makeCafeteria(seq: 1)]
        )
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].id, "1-0")
    }

    func testNoRestaurantAnswer() {
        let answer = CafeteriaIntentLogic.makeAnswer(meal: .lunch, day: .today, restaurant: nil, cafeterias: [])
        XCTAssertTrue(answer.snippet.rows.isEmpty)
        XCTAssertNil(answer.snippet.subtitle)
        let expected = String(
            format: String(localized: "intent.cafeteria.dialog.none"),
            CafeteriaDayOption.today.title,
            CafeteriaMealOption.lunch.title
        )
        XCTAssertEqual(answer.dialog, expected)
    }

    func testRestaurantAnswer() {
        let answer = CafeteriaIntentLogic.makeAnswer(meal: .breakfast, day: .tomorrow, restaurant: .student, cafeterias: [])
        XCTAssertEqual(answer.snippet.subtitle, CafeteriaRestaurantOption.student.title)
        let expected = String(
            format: String(localized: "intent.cafeteria.dialog.none.restaurant"),
            CafeteriaDayOption.tomorrow.title,
            CafeteriaMealOption.breakfast.title,
            CafeteriaRestaurantOption.student.title
        )
        XCTAssertEqual(answer.dialog, expected)
    }

    func testCampusSelection() {
        XCTAssertEqual(CafeteriaIntentLogic.campusID(for: .staff, storedCampusID: 1), 2)
        XCTAssertEqual(CafeteriaIntentLogic.campusID(for: .studentUnion, storedCampusID: 2), 1)
        XCTAssertEqual(CafeteriaIntentLogic.campusID(for: nil, storedCampusID: 0), 2)
        XCTAssertEqual(CafeteriaIntentLogic.campusID(for: nil, storedCampusID: 1), 1)
    }

    func testRestaurantOptionsAndNames() {
        XCTAssertEqual(CafeteriaRestaurantOption.allCases.map(\.seq), [1, 2, 4, 6, 7, 8, 11, 12, 13, 14, 15])
        for restaurant in CafeteriaRestaurantOption.allCases {
            XCTAssertEqual(restaurant.title, CafeteriaIntentLogic.cafeteriaName(seq: restaurant.seq))
        }
    }

    private func makeCafeteria(seq: Int) -> CafeteriaMenus {
        CafeteriaMenus(seq: seq, menus: [
            CafeteriaMenuEntry(type: "중식", food: "밥\n국 ", price: "5000원"),
            CafeteriaMenuEntry(type: "석식", food: "저녁", price: "6000원"),
        ])
    }
}
