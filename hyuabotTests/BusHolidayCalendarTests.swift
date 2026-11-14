//
//  BusHolidayCalendarTests.swift
//  hyuabot
//

import Foundation
import XCTest
@testable import hyuabot

@MainActor
final class BusHolidayCalendarTests: XCTestCase {
    func testSuccessCachesForDayAndReloadsNextDay() async throws {
        let recorder = FetchRecorder(result: .success(["2026-10-09"]))
        let calendar = BusHolidayCalendar { start, end in
            try await recorder.fetch(start: start, end: end)
        }
        var changeCount = 0
        let now = try instant("2026-11-14T22:00:00+09:00")

        await calendar.refreshIfNeeded(now: now) { changeCount += 1 }?.value
        XCTAssertEqual(calendar.holidays, ["2026-10-09"])
        XCTAssertEqual(changeCount, 1)
        let firstCalls = await recorder.calls
        XCTAssertEqual(firstCalls.count, 1)
        XCTAssertEqual(firstCalls.first?.0, "2026-10-09")
        XCTAssertEqual(firstCalls.first?.1, "2026-11-15")

        let sameDayTask = calendar.refreshIfNeeded(now: now.addingTimeInterval(3_600)) { changeCount += 1 }
        XCTAssertNil(sameDayTask)

        await calendar.refreshIfNeeded(now: now.addingTimeInterval(86_400)) { changeCount += 1 }?.value
        XCTAssertEqual(changeCount, 1)
        let nextDayCalls = await recorder.calls
        XCTAssertEqual(nextDayCalls.count, 2)
        XCTAssertEqual(nextDayCalls.last?.0, "2026-10-10")
        XCTAssertEqual(nextDayCalls.last?.1, "2026-11-16")
    }

    func testFailureFallsBackAndRetriesAfterInterval() async throws {
        let recorder = FetchRecorder(result: .failure(TestError.failed))
        let calendar = BusHolidayCalendar { start, end in
            try await recorder.fetch(start: start, end: end)
        }
        let now = try instant("2026-11-14T22:00:00+09:00")

        XCTAssertTrue(calendar.holidays.isEmpty)
        await calendar.refreshIfNeeded(now: now)?.value
        XCTAssertTrue(calendar.holidays.isEmpty)
        XCTAssertNil(calendar.refreshIfNeeded(now: now.addingTimeInterval(60)))
        await recorder.setResult(.success(["2026-10-09"]))
        await calendar.refreshIfNeeded(now: now.addingTimeInterval(301))?.value
        XCTAssertEqual(calendar.holidays, ["2026-10-09"])
        let nextDayCalls = await recorder.calls
        XCTAssertEqual(nextDayCalls.count, 2)
    }

    func testFailureOnNextDayKeepsLastGoodSet() async throws {
        let recorder = FetchRecorder(result: .success(["2026-10-09"]))
        let calendar = BusHolidayCalendar { start, end in
            try await recorder.fetch(start: start, end: end)
        }
        let now = try instant("2026-11-14T22:00:00+09:00")
        await calendar.refreshIfNeeded(now: now)?.value
        await recorder.setResult(.failure(TestError.failed))
        await calendar.refreshIfNeeded(now: now.addingTimeInterval(86_400))?.value
        XCTAssertEqual(calendar.holidays, ["2026-10-09"])
    }

    private func instant(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        let parsed = formatter.date(from: value)
        return try XCTUnwrap(parsed)
    }
}

private actor FetchRecorder {
    private(set) var calls: [(String, String)] = []
    private var result: Result<[String], TestError>

    init(result: Result<[String], TestError>) {
        self.result = result
    }

    func fetch(start: String, end: String) throws -> [String] {
        calls.append((start, end))
        return try result.get()
    }

    func setResult(_ result: Result<[String], TestError>) {
        self.result = result
    }
}

private enum TestError: Error {
    case failed
}
