//
//  AppIntentTransitTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AppIntentTransitTests: XCTestCase {
    private var subwayEntries: [SubwayArrivalEntry] {
        [
            .init(stationID: "K449", direction: "up", minutes: 5, terminalName: "A", isRealtime: true),
            .init(stationID: "K449", direction: "up", minutes: 2, terminalName: "B", isRealtime: true),
            .init(stationID: "K449", direction: "up", minutes: 9, terminalName: "C", isRealtime: false),
            .init(stationID: "K449", direction: "down", minutes: 3, terminalName: "D", isRealtime: true),
            .init(stationID: "K251", direction: "up", minutes: 4, terminalName: "E", isRealtime: true)
        ]
    }

    func testSubwayRowsAndAnswer() {
        let rows = SubwayIntentLogic.rows(lines: [.line4], direction: nil, entries: subwayEntries, perDirection: 2)
        XCTAssertEqual(rows.map(\.id), ["K449-up-0", "K449-up-1", "K449-down-0"])
        XCTAssertTrue(rows[0].detail.hasSuffix(IntentText.minutesLater(2)))
        let answer = SubwayIntentLogic.makeAnswer(line: nil, direction: nil, entries: subwayEntries)
        XCTAssertEqual(answer.snippet.rows.map(\.id), ["K449-up-0", "K449-up-1", "K449-down-0", "K251-up-0"])
        XCTAssertTrue(answer.dialog.contains("2"))
        let down = SubwayIntentLogic.makeAnswer(line: .line4, direction: .down, entries: subwayEntries)
        XCTAssertEqual(down.snippet.rows.map(\.id), ["K449-down-0"])
        XCTAssertEqual(down.snippet.subtitle, SubwayDirectionOption.down.title)
        XCTAssertTrue(down.dialog.contains("3"))
    }

    func testSubwayEmptyAnswer() {
        let answer = SubwayIntentLogic.makeAnswer(line: .suinBundang, direction: nil, entries: [])
        XCTAssertTrue(answer.snippet.rows.isEmpty)
        XCTAssertEqual(answer.dialog, String(localized: "intent.subway.dialog.none"))
    }

    func testBusRowsAndDialog() {
        let entries = [7, 3, 12].map {
            BusArrivalEntry(routeID: 1, routeName: "10-1", stopID: 216_000_379, minutes: $0, stops: nil, isRealtime: true, time: nil)
        }
            + [BusArrivalEntry(routeID: 1, routeName: "10-1", stopID: 216_000_379, minutes: nil, stops: nil, isRealtime: false, time: nil)]
        let rows = BusIntentLogic.rows(entries: entries, perRoute: 2)
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows[0].detail.hasPrefix(IntentText.minutesLater(3)))
        let scheduledEntry = BusArrivalEntry(
            routeID: 1, routeName: "10-1", stopID: 1, minutes: nil, stops: nil, isRealtime: false, time: "14:05:00"
        )
        let scheduled = BusIntentLogic.makeAnswer(route: nil, entries: [scheduledEntry])
        XCTAssertEqual(scheduled.dialog, String(format: String(localized: "intent.bus.dialog.scheduled"), "10-1", "14:05"))
    }

    func testBusScheduledDialogUsesEarliestTime() {
        let entries = [
            BusArrivalEntry(
                routeID: 1,
                routeName: "3102",
                stopID: 1,
                minutes: nil,
                stops: nil,
                isRealtime: false,
                time: "14:30:00"
            ),
            BusArrivalEntry(
                routeID: 2,
                routeName: "10-1",
                stopID: 2,
                minutes: nil,
                stops: nil,
                isRealtime: false,
                time: "14:05:00"
            )
        ]
        let answer = BusIntentLogic.makeAnswer(route: nil, entries: entries)
        XCTAssertEqual(
            answer.dialog,
            String(format: String(localized: "intent.bus.dialog.scheduled"), "10-1", "14:05")
        )
    }

    func testBusFilterAndDefaults() {
        XCTAssertEqual(BusRouteOption.route3101.routeStops.count, 3)
        XCTAssertEqual(BusRouteOption.route10Dash1.routeStops, [BusIntentRouteStop(route: 216_000_068, stop: 216_000_379)])
        XCTAssertEqual(BusRouteOption.defaultRouteStops.count, 7)
        XCTAssertEqual(BusRouteOption.defaultRouteStops.first, BusIntentRouteStop(route: 216_000_068, stop: 216_000_379))
        let entries = [
            BusArrivalEntry(routeID: 1, routeName: "10-1", stopID: 1, minutes: 3, stops: nil, isRealtime: true, time: nil),
            BusArrivalEntry(routeID: 2, routeName: "3102", stopID: 2, minutes: 8, stops: nil, isRealtime: true, time: nil)
        ]
        let answer = BusIntentLogic.makeAnswer(route: .route3102, entries: entries)
        XCTAssertEqual(answer.dialog, String(format: String(localized: "intent.bus.dialog.next"), "3102", "8"))
        XCTAssertEqual(answer.snippet.rows.count, 1)
        XCTAssertTrue(answer.snippet.rows[0].title.hasPrefix("3102"))
        XCTAssertEqual(answer.snippet.title, BusRouteOption.route3102.title)
        let empty = BusIntentLogic.makeAnswer(route: nil, entries: [])
        XCTAssertEqual(empty.dialog, String(localized: "intent.bus.dialog.none"))
        XCTAssertTrue(empty.snippet.rows.isEmpty)
    }
}
