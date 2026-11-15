//
//  BusRecentDatesTests.swift
//  hyuabot
//

import XCTest
@testable import hyuabot

final class BusRecentDatesTests: XCTestCase {
    private struct RequestCase {
        let day: String
        let hour: Int
        let holidays: Set<String>
        let expected: [String]
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return value
    }

    private let holidays: Set<String> = ["2026-10-03", "2026-10-05", "2026-10-09"]

    private func date(_ value: String, hour: Int = 22) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try XCTUnwrap(formatter.date(from: "\(value) \(String(format: "%02d", hour)):00"))
    }

    private func strings(_ values: [Date]) -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return values.map(formatter.string(from:))
    }

    func testDayTypeAndHolidayFallback() throws {
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-11-14")), .saturday)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-11-15")), .sunday)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-11-13")), .weekdays)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-10-09"), holidays: holidays), .sunday)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-10-03"), holidays: holidays), .sunday)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-10-10"), holidays: holidays), .saturday)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-10-08"), holidays: holidays), .weekdays)
        XCTAssertEqual(BusRecentDates.dayType(of: try date("2026-10-09")), .weekdays)
    }

    func testRecentDatesMatchLegacyClassification() throws {
        let cases: [(String, BusRecentDates.BusDayType)] = [
            ("2026-11-14", .saturday),
            ("2026-11-15", .sunday),
            ("2026-11-11", .weekdays)
        ]
        for (day, type) in cases {
            let start = try date(day)
            XCTAssertEqual(
                strings(BusRecentDates.recentDates(of: type, from: start, count: 4)),
                BusRecentDates.sameWeekdayType(count: 4, from: start)
            )
        }
    }

    func testLogRequestDateListsWithoutHolidays() throws {
        let cases: [RequestCase] = [
            RequestCase(day: "2026-11-14", hour: 22, holidays: [], expected: [
                "2026-11-14", "2026-11-15", "2026-11-07", "2026-11-08",
                "2026-10-31", "2026-11-01", "2026-10-24", "2026-10-25"
            ]),
            RequestCase(day: "2026-11-08", hour: 22, holidays: [], expected: [
                "2026-11-08", "2026-11-09", "2026-11-01", "2026-11-02",
                "2026-10-25", "2026-10-26", "2026-10-18", "2026-10-19"
            ]),
            RequestCase(day: "2026-11-11", hour: 22, holidays: [], expected: [
                "2026-11-11", "2026-11-12", "2026-11-10", "2026-11-09", "2026-11-06", "2026-11-07"
            ]),
            RequestCase(day: "2026-11-09", hour: 0, holidays: [], expected: [
                "2026-11-09", "2026-11-02", "2026-11-06", "2026-10-26", "2026-11-05", "2026-10-19", "2026-11-04"
            ]),
            RequestCase(day: "2026-11-10", hour: 0, holidays: [], expected: [
                "2026-11-10", "2026-11-07", "2026-11-09", "2026-11-06", "2026-11-05"
            ]),
            RequestCase(day: "2026-11-14", hour: 0, holidays: [], expected: [
                "2026-11-14", "2026-11-13", "2026-11-07", "2026-11-12", "2026-10-31", "2026-11-11", "2026-10-24"
            ]),
            RequestCase(day: "2026-11-15", hour: 0, holidays: [], expected: [
                "2026-11-15", "2026-11-08", "2026-11-01", "2026-10-25"
            ])
        ]
        for item in cases {
            XCTAssertEqual(
                BusRecentDates.logRequestDates(now: try date(item.day, hour: item.hour), calendar: calendar),
                item.expected
            )
        }
    }

    func testLogRequestDatesWithHolidays() throws {
        let cases: [RequestCase] = [
            RequestCase(day: "2026-10-09", hour: 22, holidays: holidays, expected: [
                "2026-10-09", "2026-10-10", "2026-10-05", "2026-10-06", "2026-10-04", "2026-10-03"
            ]),
            RequestCase(day: "2026-10-09", hour: 22, holidays: [], expected: [
                "2026-10-09", "2026-10-10", "2026-10-08", "2026-10-07", "2026-10-06"
            ]),
            RequestCase(day: "2026-10-11", hour: 22, holidays: holidays, expected: [
                "2026-10-11", "2026-10-12", "2026-10-09", "2026-10-10", "2026-10-05", "2026-10-06", "2026-10-04"
            ]),
            RequestCase(day: "2026-10-08", hour: 22, holidays: holidays, expected: [
                "2026-10-08", "2026-10-09", "2026-10-07", "2026-10-06", "2026-10-02", "2026-10-03"
            ]),
            RequestCase(day: "2026-10-10", hour: 0, holidays: holidays, expected: [
                "2026-10-10", "2026-10-06", "2026-09-26", "2026-10-05", "2026-09-19", "2026-10-04", "2026-09-12"
            ])
        ]
        for item in cases {
            XCTAssertEqual(
                BusRecentDates.logRequestDates(
                    now: try date(item.day, hour: item.hour), holidays: item.holidays, calendar: calendar
                ),
                item.expected
            )
        }
    }

    func testCurrentServiceDayType() throws {
        func matches(_ date: String, _ hour: Int, _ now: String, _ nowHour: Int = 22,
                     _ holidays: Set<String> = []) throws -> Bool {
            BusRecentDates.isLogInCurrentServiceDayType(
                logDate: date,
                logHour: hour,
                now: try self.date(now, hour: nowHour),
                holidays: holidays,
                calendar: calendar
            )
        }
        XCTAssertTrue(try matches("2026-11-07", 23, "2026-11-14"))
        XCTAssertFalse(try matches("2026-11-07", 0, "2026-11-14"))
        XCTAssertTrue(try matches("2026-11-08", 0, "2026-11-14"))
        XCTAssertFalse(try matches("2026-11-08", 23, "2026-11-14"))
        XCTAssertFalse(try matches("bad", 1, "2026-11-14"))
        XCTAssertTrue(try matches("2026-11-02", 1, "2026-11-09", 0))
        XCTAssertFalse(try matches("2026-11-06", 1, "2026-11-09", 0))
        XCTAssertTrue(try matches("2026-11-07", 1, "2026-11-11"))
        XCTAssertFalse(try matches("2026-11-09", 1, "2026-11-11"))
        XCTAssertTrue(try matches("2026-10-10", 1, "2026-10-09", 22, holidays))
        XCTAssertFalse(try matches("2026-10-09", 1, "2026-10-09", 22, holidays))
        XCTAssertTrue(try matches("2026-10-04", 23, "2026-10-09", 22, holidays))
        XCTAssertTrue(try matches("2026-10-05", 23, "2026-10-09", 22, holidays))
        XCTAssertFalse(try matches("2026-10-02", 23, "2026-10-09", 22, holidays))
        XCTAssertTrue(try matches("2026-10-02", 23, "2026-10-09", 22))
        XCTAssertFalse(try matches("2026-10-04", 23, "2026-10-09", 22))
        XCTAssertTrue(try matches("2026-10-09", 1, "2026-10-09", 22))
        XCTAssertTrue(try matches("2026-10-09", 1, "2026-10-08", 22, holidays))
        XCTAssertFalse(try matches("2026-10-09", 23, "2026-10-08", 22, holidays))
        XCTAssertFalse(try matches("2026-10-06", 1, "2026-10-08", 22, holidays))
        XCTAssertTrue(try matches("2026-10-07", 1, "2026-10-08", 22, holidays))
        XCTAssertTrue(try matches("2026-10-10", 1, "2026-10-10", 0, holidays))
        XCTAssertTrue(try matches("2026-10-05", 2, "2026-10-10", 0, holidays))
        XCTAssertTrue(try matches("2026-10-06", 1, "2026-10-10", 0, holidays))
        XCTAssertFalse(try matches("2026-09-26", 1, "2026-10-10", 0, holidays))
        XCTAssertTrue(try matches("2026-09-26", 9, "2026-10-10", 0, holidays))
    }
}
