//
//  AppIntentSearchTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AppIntentSearchTests: XCTestCase {
    func testRoutesSearchTerms() {
        XCTAssertEqual(HyuabotSearchLogic.request(for: "셔틀 언제 와"), .shuttle(stop: nil))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "3102 버스"), .bus(route: .route3102))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "3100N"), .bus(route: .route3100N))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "버스 언제 와"), .bus(route: nil))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "4호선 도착"), .subway(line: .line4))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "수인분당 지하철"), .subway(line: .suinBundang))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "내일 조식 뭐야"), .cafeteria(day: .tomorrow, meal: .breakfast, restaurant: nil))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "오늘 학식"), .cafeteria(day: .today, meal: nil, restaurant: nil))
        XCTAssertEqual(HyuabotSearchLogic.request(for: "lunch menu"), .cafeteria(day: nil, meal: .lunch, restaurant: nil))
        XCTAssertEqual(HyuabotSearchLogic.request(for: ShuttleStopOption.dormitory.title + " 셔틀"), .shuttle(stop: .dormitory))
        XCTAssertEqual(HyuabotSearchLogic.request(for: ShuttleStopOption.shuttlecockIn.title + " 셔틀"), .shuttle(stop: .shuttlecockIn))
        XCTAssertEqual(HyuabotSearchLogic.request(for: ShuttleStopOption.shuttlecock.title + " 셔틀"), .shuttle(stop: .shuttlecock))
        XCTAssertNil(HyuabotSearchLogic.request(for: "날씨"))
    }

    func testNoResultAnswerIncludesTermAndEmptyRows() {
        let answer = HyuabotSearchLogic.noResultAnswer(for: "날씨")
        XCTAssertTrue(answer.dialog.contains("날씨"))
        XCTAssertTrue(answer.snippet.rows.isEmpty)
    }
}
