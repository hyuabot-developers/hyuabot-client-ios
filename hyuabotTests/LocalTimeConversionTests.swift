//
//  LocalTimeConversionTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class LocalTimeConversionTests: XCTestCase {
    func testCurrentMinuteArrivalKeepsSeconds() throws {
        let reference = Date(timeIntervalSince1970: 1_794_456_000)
        let base = try XCTUnwrap("12:00:00".toLocalTimeOrNil(on: reference))
        let now = base.addingTimeInterval(10)
        let arrival = try XCTUnwrap("12:00:50".toLocalTimeOrNil(on: now))

        XCTAssertEqual(arrival.timeIntervalSince(now), 40, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(arrival, now)
        XCTAssertEqual(ShuttleDisplayLogic.minutesUntil(arrival, now: now), 0)
    }

    func testPastTimeInSameMinuteIsBeforeNow() throws {
        let reference = Date(timeIntervalSince1970: 1_794_456_000)
        let base = try XCTUnwrap("12:00:00".toLocalTimeOrNil(on: reference))
        let now = base.addingTimeInterval(10)

        XCTAssertLessThan(try XCTUnwrap("12:00:00".toLocalTimeOrNil(on: now)), now)
    }

    func testFractionalSecondsAreDropped() throws {
        let reference = Date(timeIntervalSince1970: 1_794_456_000)
        let base = try XCTUnwrap("12:00:00".toLocalTimeOrNil(on: reference))
        let now = base.addingTimeInterval(10)

        XCTAssertEqual(
            try XCTUnwrap("12:00:50.750".toLocalTimeOrNil(on: now)),
            try XCTUnwrap("12:00:50".toLocalTimeOrNil(on: now))
        )
    }

    func testInvalidTimeReturnsNil() {
        let reference = Date(timeIntervalSince1970: 1_794_456_000)

        XCTAssertNil("bad".toLocalTimeOrNil(on: reference))
    }

    func testUsesDayOfNow() throws {
        let reference = Date(timeIntervalSince1970: 1_794_456_000)
        let later = reference.addingTimeInterval(3 * 86_400)
        let referenceTime = try XCTUnwrap("12:00:00".toLocalTimeOrNil(on: reference))
        let laterTime = try XCTUnwrap("12:00:00".toLocalTimeOrNil(on: later))

        XCTAssertEqual(laterTime.timeIntervalSince(referenceTime), 3 * 86_400, accuracy: 3_600)
    }
}
