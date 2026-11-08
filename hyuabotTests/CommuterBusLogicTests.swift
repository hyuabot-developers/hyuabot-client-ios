//
//  CommuterBusLogicTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class CommuterBusLogicTests: XCTestCase {
    private let routes = CommuterDesignRoutes.all
    private func context(
        _ date: Date,
        _ minute: Int,
        period: String? = "semester",
        holiday: String? = nil,
        next: Date? = nil,
        location: ShuttleGeoCoordinate? = nil,
        end: Date? = nil
    ) -> CommuterServiceContext {
        CommuterServiceContext(
            date: date,
            nowMinutes: minute,
            periodType: period,
            periodEndDay: end,
            holidayType: holiday,
            nextRunDay: next,
            userLocation: location
        )
    }

    private func stopIndex(_ model: CommuterScreenModel, _ index: Int) -> CommuterStopRow? {
        model.rows.compactMap {
            if case let .stop(row) = $0 {
                row
            } else {
                nil
            }
        }.first { $0.index == index }
    }

    func testStandardDesignScenario() throws {
        let model = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 9), 398, location: .init(
                latitude: 37.5162,
                longitude: 127.0998
            )),
            selection: .auto
        )
        XCTAssertEqual(model.selectedDirection, .toCampus)
        XCTAssertEqual(model.selectedRouteName, "4")
        XCTAssertTrue(stopIndex(model, 3)?.isNear == true)
        XCTAssertEqual(model.rows.first, try .stop(XCTUnwrap(stopIndex(model, 0))))
        XCTAssertEqual(model.rows[1], .bus)
        XCTAssertFalse(model.rows.contains {
            if case .fold = $0 {
                true
            } else {
                false
            }
        })
        XCTAssertTrue(model.rows.contains {
            if case .gap(minutes: 57, traveled: _) = $0 {
                true
            } else {
                false
            }
        })
        XCTAssertEqual(model.summary?.phase, .running)
        XCTAssertEqual(model.summary?.durationMinutes, 115)
    }

    func testNoLocationFoldsToCurrentRoute() {
        let model = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 9), 420),
            selection: .auto
        )
        XCTAssertEqual(model.selectedRouteName, "4")
        XCTAssertEqual(model.rows.first, .fold(hiddenCount: 7))
        let bus = model.rows.firstIndex(of: .bus)
        XCTAssertEqual(stopIndex(model, 8).map { model.rows.firstIndex(of: .stop($0)) }, bus.map { $0 - 1 })
    }

    func testRouteFiveNearest() {
        let model = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 9), 439, location: .init(
                latitude: 37.3270,
                longitude: 127.1092
            )),
            selection: .auto
        )
        XCTAssertEqual(model.selectedRouteName, "5")
        XCTAssertTrue(stopIndex(model, 4)?.isNear == true)
        XCTAssertEqual(
            model.rows.firstIndex(of: .bus),
            model.rows.firstIndex(where: {
                if case let .stop(row) = $0 {
                    row.index == 1
                } else {
                    false
                }
            }).map { $0 + 1 }
        )
    }

    func testPartialFromRoute() {
        let model = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 9), 1045),
            selection: .auto
        )
        XCTAssertEqual(model.selectedDirection, .fromCampus)
        XCTAssertEqual(model.selectedRouteName, "D")
        XCTAssertEqual(model.summary?.phase, .beforeRun)
        XCTAssertEqual(
            model.summary?.durationMinutes,
            nil
        )
        XCTAssertTrue(model.summary?.isPartial == true)
        XCTAssertFalse(model.rows.contains {
            if case .bus = $0 {
                true
            } else if case .gap = $0 {
                true
            } else {
                false
            }
        })
    }

    func testWeekendAndVacationNotice() {
        let weekend = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 7), 620, next: CommuterBusLogic.day(
                year: 2026,
                month: 11,
                day: 9
            )),
            selection: .auto
        )
        XCTAssertEqual(weekend.summary?.phase, .off)
        XCTAssertEqual(
            weekend.offNotice,
            CommuterOffNotice(reason: .weekend, nextRunDay: CommuterBusLogic.day(year: 2026, month: 11, day: 9))
        )
        let vacation = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(
                CommuterBusLogic.day(year: 2026, month: 12, day: 28),
                420,
                period: "vacation_session",
                next: CommuterBusLogic.day(
                    year: 2027,
                    month: 3,
                    day: 2
                )
            ),
            selection: .auto
        )
        XCTAssertEqual(vacation.offNotice?.reason, .vacationSession)
        XCTAssertEqual(vacation.subtitle, .weekdaysOnly)
    }

    func testSelectionReset() {
        let serviceContext = context(CommuterBusLogic.day(year: 2026, month: 11, day: 9), 398)
        XCTAssertTrue(CommuterBusLogic.makeModel(
            routes: routes,
            context: serviceContext,
            selection: CommuterSelection(direction: .fromCampus, routeName: "D", expanded: false)
        ).showsResetToNearest)
        XCTAssertFalse(CommuterBusLogic.makeModel(routes: routes, context: serviceContext, selection: .auto).showsResetToNearest)
    }

    func testDateHelpersAndCoordinateSentinel() {
        XCTAssertEqual(
            CommuterBusLogic.periodBoundaryDay("2026-12-22T08:59:59.000+09:00"),
            CommuterBusLogic.day(year: 2026, month: 12, day: 21)
        )
        XCTAssertEqual(
            CommuterBusLogic.periodBoundaryDay("2026-09-01T09:00:00.000+09:00"),
            CommuterBusLogic.day(year: 2026, month: 9, day: 1)
        )
        XCTAssertEqual(CommuterBusLogic.minutes("07:33:00"), 453)
        XCTAssertFalse(CommuterStop(time: nil, name: "x", detail: "", latitude: 0, longitude: 127.1).hasCoordinate)
        XCTAssertTrue(CommuterStop(time: nil, name: "x", detail: "", latitude: 37.3, longitude: 0).hasCoordinate)
        XCTAssertEqual(routes[2].stops.count, 14)
        XCTAssertTrue(routes[2].stops.dropFirst().allSatisfy { !$0.hasCoordinate })
        XCTAssertEqual(routes.map(\.stops.count), [17, 13, 14])
    }

    func testClockUsesSeoulDayBoundary() throws {
        let sunday = CommuterBusLogic.day(year: 2026, month: 11, day: 8)
        let monday = CommuterBusLogic.day(year: 2026, month: 11, day: 9)
        XCTAssertEqual(CommuterBusLogic.clockAction(contextDate: sunday.addingTimeInterval(1439 * 60), now: monday), .reloadContext)
        XCTAssertEqual(
            CommuterBusLogic.clockAction(contextDate: sunday.addingTimeInterval(600 * 60), now: sunday.addingTimeInterval(605 * 60)),
            .tick(nowMinutes: 605)
        )
        let utcNow = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-08T15:00:00Z"))
        XCTAssertEqual(CommuterBusLogic.clockAction(contextDate: sunday, now: utcNow), .reloadContext)
    }

    func testWeekendContextReloadRestoresRunningService() {
        let sunday = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 8), 600, holiday: "weekends"),
            selection: .auto
        )
        XCTAssertEqual(sunday.offNotice?.reason, .weekend)
        XCTAssertEqual(sunday.summary?.phase, .off)
        let monday = CommuterBusLogic.makeModel(
            routes: routes,
            context: context(CommuterBusLogic.day(year: 2026, month: 11, day: 9), 420),
            selection: .auto
        )
        XCTAssertNil(monday.offNotice)
        XCTAssertEqual(monday.summary?.phase, .running)
    }
}
