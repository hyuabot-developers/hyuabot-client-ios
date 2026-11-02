//
//  AppIntentOpenEntityTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

private actor IntentFetchCounter {
    private(set) var value = 0

    func increment() { value += 1 }
}

final class AppIntentOpenEntityTests: XCTestCase {
    func testOpenURLsMapEntitiesToExistingDeepLinks() {
        let shuttleAnswer = IntentAnswer(dialog: "", snippet: IntentSnippetContent(title: "", subtitle: nil, rows: [], emptyMessage: ""))
        let shuttle = ShuttleArrivalEntity(stop: .station, answer: shuttleAnswer)
        XCTAssertEqual(OpenEntityLogic.url(for: shuttle), HyuabotSearchLogic.url(for: .shuttle(stop: .station)))

        let subway = SubwayArrivalEntity(line: .line4, answer: shuttleAnswer)
        XCTAssertEqual(OpenEntityLogic.url(for: subway), HyuabotSearchLogic.url(for: .subway(line: .line4)))

        let bus = BusArrivalEntity(route: .route3102, answer: shuttleAnswer)
        XCTAssertEqual(OpenEntityLogic.url(for: bus), HyuabotSearchLogic.url(for: .bus(route: .route3102)))

        let now = Date(timeIntervalSince1970: 0)
        let tomorrow = HyuabotSearchLogic.tomorrowDate(from: now)
        let date = IntentClock.dateString(from: tomorrow, calendar: IntentClock.seoulCalendar)
        let cafeteria = CafeteriaMenuEntity(
            id: "\(date)|1|lunch", date: date, restaurantSeq: 1,
            restaurantName: "", meal: .lunch, menuSummary: ""
        )
        XCTAssertEqual(
            OpenEntityLogic.url(for: cafeteria, now: now),
            HyuabotSearchLogic.url(for: .cafeteria(day: .tomorrow, meal: .lunch, restaurant: nil))
        )
    }

    func testSuggestedEntityLoaderFetchesOnceForAllOptions() async {
        let counter = IntentFetchCounter()
        let entities = await TransitEntityLoader.loadUsingSharedAnswer(
            ShuttleStopOption.allCases,
            fetch: {
                await counter.increment()
                return IntentAnswer(dialog: "shared", snippet: IntentSnippetContent(title: "", subtitle: nil, rows: [], emptyMessage: ""))
            },
            make: { stop, answer in ShuttleArrivalEntity(stop: stop, answer: answer) }
        )

        let fetchCount = await counter.value
        XCTAssertEqual(fetchCount, 1)
        XCTAssertEqual(entities.map(\.id), ShuttleStopOption.allCases.map(\.rawValue))
    }
}
