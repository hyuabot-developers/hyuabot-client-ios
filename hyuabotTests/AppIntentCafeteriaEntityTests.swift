//
//  AppIntentCafeteriaEntityTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AppIntentCafeteriaEntityTests: XCTestCase {
    func testIdentifierRoundTripAndInvalidValues() {
        let key = CafeteriaMenuEntityKey(date: "2026-11-02", seq: 12, meal: .lunch)
        XCTAssertEqual(CafeteriaMenuEntityLogic.identifier(for: key), "2026-11-02|12|lunch")
        XCTAssertEqual(CafeteriaMenuEntityLogic.key(from: "2026-11-02|12|lunch"), key)
        XCTAssertNil(CafeteriaMenuEntityLogic.key(from: "bad"))
        XCTAssertNil(CafeteriaMenuEntityLogic.key(from: "2026-11-02|x|lunch"))
        XCTAssertNil(CafeteriaMenuEntityLogic.key(from: "2026-11-02|12|brunch"))
    }

    func testEntitiesAreSortedByRestaurantThenMealAndSkipEmptyMeals() {
        let entities = CafeteriaMenuEntityLogic.entities(
            date: "2026-11-02",
            cafeterias: [makeCafeteria(seq: 12, lunch: "밥\n국", dinner: "면"), makeCafeteria(seq: 1, lunch: "밥")]
        )
        XCTAssertEqual(entities.map(\.id), ["2026-11-02|1|lunch", "2026-11-02|12|lunch", "2026-11-02|12|dinner"])
        XCTAssertEqual(entities[1].menuSummary, "밥, 국")
        XCTAssertFalse(entities.contains { $0.meal == .breakfast })
    }

    func testEntityFilterHandlesFoodAndWhitespace() {
        let entities = CafeteriaMenuEntityLogic.entities(
            date: "2026-11-02", cafeterias: [makeCafeteria(seq: 12, lunch: "밥", dinner: "면")]
        )
        XCTAssertEqual(CafeteriaMenuEntityLogic.filter(entities, matching: "  \n "), entities)
        XCTAssertEqual(CafeteriaMenuEntityLogic.filter(entities, matching: "면").map(\.meal), [.dinner])
        XCTAssertEqual(CafeteriaMenuEntityLogic.filter(entities, matching: "학 생 식 당").count, 2)
        XCTAssertEqual(CafeteriaMenuEntityLogic.filter(entities, matching: "없는메뉴"), [])
    }

    func testCampusMappingDatesAndRefreshInterval() throws {
        XCTAssertEqual(CafeteriaMenuEntityLogic.campusID(forSeq: 1), 1)
        XCTAssertEqual(CafeteriaMenuEntityLogic.campusID(forSeq: 8), 1)
        XCTAssertEqual(CafeteriaMenuEntityLogic.campusID(forSeq: 11), 2)
        XCTAssertEqual(CafeteriaMenuEntityLogic.campusID(forSeq: 15), 2)

        let calendar = IntentClock.seoulCalendar
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 23, minute: 30)))
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexDates(now: date, calendar: calendar), ["2026-11-01", "2026-11-02"])
        XCTAssertTrue(CafeteriaMenuEntityLogic.shouldRefresh(lastCompleted: nil, now: date, inFlight: false))
        XCTAssertFalse(CafeteriaMenuEntityLogic.shouldRefresh(lastCompleted: date, now: date.addingTimeInterval(600), inFlight: false))
        XCTAssertTrue(CafeteriaMenuEntityLogic.shouldRefresh(lastCompleted: date, now: date.addingTimeInterval(1800), inFlight: false))
        XCTAssertFalse(CafeteriaMenuEntityLogic.shouldRefresh(lastCompleted: nil, now: date, inFlight: true))
    }

    func testRefreshCompletionAdvancesOnlyAfterClearOrReplaceWithoutIndexError() throws {
        let now = try XCTUnwrap(IntentClock.seoulCalendar.date(from: DateComponents(year: 2026, month: 11, day: 2)))
        let previous = now.addingTimeInterval(-3600)
        XCTAssertEqual(
            CafeteriaMenuEntityLogic.completedRefreshDate(lastCompleted: previous, now: now, action: .keep, indexError: false),
            previous
        )
        XCTAssertEqual(
            CafeteriaMenuEntityLogic.completedRefreshDate(lastCompleted: previous, now: now, action: .replace([]), indexError: false),
            now
        )
        XCTAssertEqual(
            CafeteriaMenuEntityLogic.completedRefreshDate(lastCompleted: previous, now: now, action: .clear, indexError: false),
            now
        )
        XCTAssertEqual(
            CafeteriaMenuEntityLogic.completedRefreshDate(lastCompleted: previous, now: now, action: .replace([]), indexError: true),
            previous
        )
        XCTAssertNil(CafeteriaMenuEntityLogic.completedRefreshDate(lastCompleted: nil, now: now, action: .keep, indexError: false))
    }

    func testSnapshotPolicyKeepsPartialFailuresAndHandlesCompleteResults() {
        let firstMenus = [makeCafeteria(seq: 1, lunch: "밥")]
        let partial = CafeteriaMenuEntityLogic.snapshot(fetches: [
            CafeteriaMenuFetch(date: "2026-11-02", menus: firstMenus),
            CafeteriaMenuFetch(date: "2026-11-02", menus: nil),
        ])
        XCTAssertFalse(partial.isComplete)
        XCTAssertEqual(partial.entities.count, 1)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: partial), .keep)

        let empty = CafeteriaMenuEntityLogic.snapshot(fetches: [
            CafeteriaMenuFetch(date: "2026-11-02", menus: []),
            CafeteriaMenuFetch(date: "2026-11-03", menus: []),
        ])
        XCTAssertTrue(empty.isComplete)
        XCTAssertTrue(empty.entities.isEmpty)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: empty), .clear)

        let complete = CafeteriaMenuEntityLogic.snapshot(fetches: [
            CafeteriaMenuFetch(date: "2026-11-02", menus: firstMenus),
            CafeteriaMenuFetch(date: "2026-11-03", menus: firstMenus),
        ])
        XCTAssertTrue(complete.isComplete)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: complete), .replace(complete.entities))
        XCTAssertEqual(complete.entities.map(\.date), ["2026-11-02", "2026-11-03"])

        let noFetches = CafeteriaMenuEntityLogic.snapshot(fetches: [])
        XCTAssertFalse(noFetches.isComplete)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: noFetches), .keep)
    }

    func testApolloResponseClassificationRejectsFailuresAndAcceptsEmptySuccess() throws {
        XCTAssertThrowsError(try CafeteriaMenuEntityLogic.validatedMenus(mappedMenus: nil, graphQLErrorCount: 1)) {
            XCTAssertEqual($0 as? CafeteriaMenuFetchError, .graphQLErrors)
        }
        XCTAssertThrowsError(
            try CafeteriaMenuEntityLogic.validatedMenus(mappedMenus: [makeCafeteria()], graphQLErrorCount: 1)
        ) {
            XCTAssertEqual($0 as? CafeteriaMenuFetchError, .graphQLErrors)
        }
        XCTAssertThrowsError(try CafeteriaMenuEntityLogic.validatedMenus(mappedMenus: nil, graphQLErrorCount: 0)) {
            XCTAssertEqual($0 as? CafeteriaMenuFetchError, .missingData)
        }
        XCTAssertEqual(try CafeteriaMenuEntityLogic.validatedMenus(mappedMenus: [], graphQLErrorCount: 0), [])
    }

    func testFailedApolloResponsesKeepExistingIndex() {
        let fetches = [
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: nil, graphQLErrorCount: 1),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: [makeCafeteria()], graphQLErrorCount: 1),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-03", mappedMenus: nil, graphQLErrorCount: 0),
        ]
        let snapshot = CafeteriaMenuEntityLogic.snapshot(fetches: fetches)
        XCTAssertFalse(snapshot.isComplete)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: snapshot), .keep)
    }

    func testEmptySuccessfulFetchesClearIndex() {
        let fetches = [
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: [], graphQLErrorCount: 0),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-03", mappedMenus: [], graphQLErrorCount: 0),
        ]
        let snapshot = CafeteriaMenuEntityLogic.snapshot(fetches: fetches)
        XCTAssertTrue(snapshot.isComplete)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: snapshot), .clear)
    }

    func testApolloFailureBoundaryDrivesIndexPolicy() {
        let erroredAndEmptySuccess = CafeteriaMenuEntityLogic.snapshot(fetches: [
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: nil, graphQLErrorCount: 1),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-03", mappedMenus: [], graphQLErrorCount: 0),
        ])
        XCTAssertFalse(erroredAndEmptySuccess.isComplete)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: erroredAndEmptySuccess), .keep)

        let failures = CafeteriaMenuEntityLogic.snapshot(fetches: [
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: nil, graphQLErrorCount: 1),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: [makeCafeteria()], graphQLErrorCount: 1),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-03", mappedMenus: nil, graphQLErrorCount: 0),
        ])
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: failures), .keep)

        let emptySuccess = CafeteriaMenuEntityLogic.snapshot(fetches: [
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-02", mappedMenus: [], graphQLErrorCount: 0),
            CafeteriaMenuEntityLogic.fetch(date: "2026-11-03", mappedMenus: [], graphQLErrorCount: 0),
        ])
        XCTAssertTrue(emptySuccess.isComplete)
        XCTAssertEqual(CafeteriaMenuEntityLogic.indexAction(for: emptySuccess), .clear)
    }

    private func makeCafeteria(seq: Int = 1, lunch: String? = nil, dinner: String? = nil) -> CafeteriaMenus {
        var menus: [CafeteriaMenuEntry] = []
        if let lunch { menus.append(CafeteriaMenuEntry(type: "중식", food: lunch, price: "5000")) }
        if let dinner { menus.append(CafeteriaMenuEntry(type: "석식", food: dinner, price: "5000")) }
        return CafeteriaMenus(seq: seq, menus: menus)
    }
}
