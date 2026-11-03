//
//  WatchDepartureTimeTests.swift
//  hyuabot
//

import XCTest

final class WatchDepartureTimeTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        if let zone = TimeZone(identifier: "Asia/Seoul") { value.timeZone = zone }
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    func testParsesTimesTodayAndTomorrow() {
        let now = date(2026, 11, 3, 10, 9)
        XCTAssertEqual(WatchDepartureTime.departureDate(from: "10:12:00", now: now, calendar: calendar), date(2026, 11, 3, 10, 12))
        XCTAssertEqual(WatchDepartureTime.departureDate(from: "10:12", now: now, calendar: calendar), date(2026, 11, 3, 10, 12))
        XCTAssertNil(WatchDepartureTime.departureDate(from: "abc", now: now, calendar: calendar))
        XCTAssertNil(WatchDepartureTime.departureDate(from: "25:00:00", now: now, calendar: calendar))
        XCTAssertNil(WatchDepartureTime.departureDate(from: "10", now: now, calendar: calendar))
        let late = date(2026, 11, 3, 23, 50)
        let tomorrow = WatchDepartureTime.departureDate(from: "00:10:00", now: late, calendar: calendar)
        XCTAssertEqual(tomorrow, date(2026, 11, 4, 0, 10))
        XCTAssertEqual(WatchDepartureTime.minutesUntil(tomorrow ?? late, now: late), 20)
    }

    func testMinutesUntilRoundsUpAndClampsPastTimes() {
        let now = date(2026, 11, 3, 10, 0)
        XCTAssertEqual(WatchDepartureTime.minutesUntil(now.addingTimeInterval(59), now: now), 0)
        XCTAssertEqual(WatchDepartureTime.minutesUntil(now.addingTimeInterval(-1), now: now), 0)
        XCTAssertEqual(WatchDepartureTime.minutesUntil(now.addingTimeInterval(60), now: now), 1)
        XCTAssertEqual(WatchDepartureTime.minutesUntil(now.addingTimeInterval(61), now: now), 2)
        XCTAssertEqual(WatchDepartureTime.minutesUntil(now.addingTimeInterval(180), now: now), 3)
        XCTAssertEqual(WatchDepartureTime.minutesUntil(now.addingTimeInterval(181), now: now), 4)
    }

    func testImminentThresholdAndClockFormatting() {
        XCTAssertTrue(WatchDepartureTime.isImminent(minutes: 0))
        XCTAssertTrue(WatchDepartureTime.isImminent(minutes: 3))
        XCTAssertFalse(WatchDepartureTime.isImminent(minutes: 4))
        XCTAssertEqual(WatchDepartureTime.clockText(date(2026, 11, 3, 9, 5), calendar: calendar), "09:05")
    }
}
