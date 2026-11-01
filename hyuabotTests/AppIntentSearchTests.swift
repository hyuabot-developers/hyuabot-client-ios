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

    func testURLsForSearchRequests() {
        XCTAssertEqual(HyuabotSearchLogic.url(for: .shuttle(stop: .dormitory)).absoluteString, "hyuabot://shuttle?stop=dormitory_o")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .shuttle(stop: nil)).absoluteString, "hyuabot://shuttle")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .cafeteria(day: nil, meal: .breakfast, restaurant: nil)).absoluteString, "hyuabot://cafeteria?tab=breakfast")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .cafeteria(day: nil, meal: .lunch, restaurant: nil)).absoluteString, "hyuabot://cafeteria?tab=lunch")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .cafeteria(day: nil, meal: .dinner, restaurant: nil)).absoluteString, "hyuabot://cafeteria?tab=dinner")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .cafeteria(day: nil, meal: nil, restaurant: nil)).absoluteString, "hyuabot://cafeteria")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .subway(line: nil)).absoluteString, "hyuabot://subway")
        XCTAssertEqual(HyuabotSearchLogic.url(for: .bus(route: nil)).absoluteString, "hyuabot://bus")
        XCTAssertEqual(HyuabotSearchLogic.url(for: nil).absoluteString, "hyuabot://home")
    }
}
