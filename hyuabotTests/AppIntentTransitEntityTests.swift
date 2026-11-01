//
//  AppIntentTransitEntityTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AppIntentTransitEntityTests: XCTestCase {
    func testMatcherNormalizesWhitespaceAndFindsContainedCandidates() {
        XCTAssertTrue(TransitEntityMatcher.matches("", candidates: ["4호선"]))
        XCTAssertTrue(TransitEntityMatcher.matches(" \n ", candidates: ["4호선"]))
        XCTAssertTrue(TransitEntityMatcher.matches("  Line 4 ", candidates: ["line4"]))
        XCTAssertTrue(TransitEntityMatcher.matches("4호선 언제 와", candidates: ["4호선"]))
        XCTAssertFalse(TransitEntityMatcher.matches("xyz", candidates: ["4호선"]))
    }

    func testSubwayOptionsMatch() {
        XCTAssertEqual(SubwayArrivalEntityQuery.lines(matching: "4호선"), [.line4])
        XCTAssertEqual(SubwayArrivalEntityQuery.lines(matching: "수인분당"), [.suinBundang])
    }

    func testBusOptionsMatch() {
        XCTAssertEqual(BusArrivalEntityQuery.routes(matching: "3102"), [.route3102])
        XCTAssertEqual(BusArrivalEntityQuery.routes(matching: "9090"), [.route9090])
    }

    func testShuttleOptionsMatch() {
        XCTAssertTrue(ShuttleArrivalEntityQuery.stops(matching: ShuttleStopOption.dormitory.title).contains(.dormitory))
        XCTAssertTrue(ShuttleArrivalEntityQuery.stops(matching: "shuttlecock_o").contains(.shuttlecock))
    }

    func testEntitiesUseStableIdentifiersAndAnswerSummary() {
        let answer = IntentAnswer(
            dialog: "d",
            snippet: IntentSnippetContent(title: "t", subtitle: nil, rows: [], emptyMessage: "e")
        )
        let shuttle = ShuttleArrivalEntity(stop: .station, answer: answer)
        XCTAssertEqual(shuttle.id, "station")
        XCTAssertEqual(shuttle.name, ShuttleStopOption.station.title)
        XCTAssertEqual(shuttle.summary, "d")
        let subway = SubwayArrivalEntity(line: .line4, answer: answer)
        XCTAssertEqual(subway.id, "K449")
        XCTAssertEqual(subway.name, SubwayLineOption.line4.title)
        XCTAssertEqual(subway.summary, "d")
        let bus = BusArrivalEntity(route: .route3102, answer: answer)
        XCTAssertEqual(bus.id, "3102")
        XCTAssertEqual(bus.name, BusRouteOption.route3102.title)
        XCTAssertEqual(bus.summary, "d")
    }

    func testLoaderPreservesOptionOrder() async {
        let loaded = await TransitEntityLoader.load([3, 1, 2]) { "\($0)" }
        XCTAssertEqual(loaded, ["3", "1", "2"])
    }
}
