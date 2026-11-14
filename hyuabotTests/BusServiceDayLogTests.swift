//
//  BusServiceDayLogTests.swift
//  hyuabot
//

@testable import hyuabot
import XCTest

final class BusServiceDayLogTests: XCTestCase {
    private func seoulCalendar() throws -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        return cal
    }

    private func instant(_ cal: Calendar, _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) throws -> Date {
        try XCTUnwrap(cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
    }

    private func visibleLogs(
        _ logs: [(date: String, time: String)],
        now: Date,
        holidays: Set<String> = [],
        intervals: [(weekday: String, minutes: Int)] = []
    ) throws -> [String] {
        let cal = try seoulCalendar()
        let candidates: [(date: Date, serviceDate: Date)] = try logs.compactMap { log in
            let parts = log.time.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2,
                  BusRecentDates.isLogInCurrentServiceDayType(
                    logDate: log.date, logHour: parts[0], now: now, holidays: holidays, calendar: cal
                  ) else { return nil }
            let time = try XCTUnwrap(cal.date(
                bySettingHour: parts[0], minute: parts[1], second: 0, of: now
            ))
            guard let serviceDate = BusLogMerging.realtimeServiceDate(for: time, now: now, calendar: cal) else {
                return nil
            }
            return (time, serviceDate)
        }
        let dispatchMinutes = BusLogMerging.realtimeDispatchMinutes(
            intervals: intervals, logDerivedMinutes: nil, now: now, holidays: holidays, calendar: cal
        )
        let selected = BusLogMerging.realtimeTabLogs(
            candidates: candidates, serviceDate: { $0.serviceDate }, dispatchMinutes: dispatchMinutes,
            lastLiveArrival: nil, now: now
        )
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = cal.timeZone
        formatter.dateFormat = "MM-dd HH:mm"
        return selected.map { formatter.string(from: $0.serviceDate) }
    }

    func test3100NSaturdayNightDoesNotShowFridayServiceTail() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 11, 14, 22, 0)
        let logs: [(String, String)] = [("2026-11-12", "23:59"), ("2026-11-13", "01:02"), ("2026-11-07", "00:02"), ("2026-11-07", "01:02")]
        XCTAssertEqual(try visibleLogs(logs, now: now), [])
    }

    func test3102SaturdayEveningAndAfterMidnightTail() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 11, 14, 22, 0)
        let logs: [(String, String)] = [
            ("2026-11-07", "22:30"), ("2026-11-07", "23:10"), ("2026-11-08", "00:20"),
            ("2026-11-08", "01:00"), ("2026-11-07", "00:40"), ("2026-11-08", "23:30")
        ]
        XCTAssertEqual(try visibleLogs(logs, now: now), ["11-14 22:30", "11-14 23:10", "11-15 00:20", "11-15 01:00"])
    }

    func testSundayEvening() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 11, 15, 22, 0)
        let logs: [(String, String)] = [("2026-11-08", "23:00"), ("2026-11-08", "00:30"), ("2026-11-09", "00:30")]
        XCTAssertEqual(try visibleLogs(logs, now: now), ["11-15 23:00", "11-16 00:30"])
    }

    func testWeekdayEvening() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 11, 11, 22, 0)
        let logs: [(String, String)] = [("2026-11-10", "23:00"), ("2026-11-13", "00:40"), ("2026-11-09", "00:50"), ("2026-11-07", "01:30")]
        XCTAssertEqual(try visibleLogs(logs, now: now), ["11-11 23:00", "11-12 00:40", "11-12 01:30"])
    }

    func testAfterMidnightMonday() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 11, 9, 0, 30)
        let logs: [(String, String)] = [("2026-11-02", "01:00"), ("2026-11-06", "01:20"), ("2026-11-02", "05:30")]
        XCTAssertEqual(try visibleLogs(logs, now: now), ["11-09 01:00", "11-09 05:30"])
    }

    func testAfterMidnightSaturday3100N() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 11, 14, 0, 30)
        XCTAssertEqual(try visibleLogs([("2026-11-07", "01:02")], now: now), ["11-14 01:02"])
    }

    func testHangulDayAndFallbackWithoutHolidayData() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 10, 9, 22, 0)
        let holidays: Set<String> = ["2026-10-03", "2026-10-05", "2026-10-09"]
        let logs: [(String, String)] = [("2026-10-02", "23:59"), ("2026-10-03", "01:02"), ("2026-10-04", "23:10"), ("2026-10-05", "00:20")]
        XCTAssertEqual(try visibleLogs(logs, now: now, holidays: holidays), ["10-09 23:10", "10-10 00:20"])
        XCTAssertEqual(try visibleLogs(logs, now: now), ["10-09 23:59", "10-10 01:02"])
    }

    func testHolidayEve() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 10, 8, 22, 0)
        let holidays: Set<String> = ["2026-10-03", "2026-10-05", "2026-10-09"]
        let logs: [(String, String)] = [("2026-10-07", "23:30"), ("2026-10-08", "00:40"), ("2026-10-06", "00:50"), ("2026-10-04", "23:00")]
        XCTAssertEqual(try visibleLogs(logs, now: now, holidays: holidays), ["10-08 23:30", "10-09 00:40"])
    }

    func testDayAfterHoliday() throws {
        let cal = try seoulCalendar()
        let now = try instant(cal, 2026, 10, 10, 0, 30)
        let holidays: Set<String> = ["2026-10-03", "2026-10-05", "2026-10-09"]
        let logs: [(String, String)] = [("2026-10-05", "01:00"), ("2026-10-03", "01:20"), ("2026-09-26", "07:00")]
        XCTAssertEqual(try visibleLogs(logs, now: now, holidays: holidays), ["10-10 01:00", "10-10 07:00"])
    }

    func testHangulDayUsesSundayDispatchIntervalAndTail() throws {
        let cal = try seoulCalendar()
        let holidays: Set<String> = ["2026-10-03", "2026-10-05", "2026-10-09"]
        let intervals: [(weekday: String, minutes: Int)] = [("weekdays", 60), ("saturday", 40), ("sunday", 20)]
        let evening = try instant(cal, 2026, 10, 9, 22, 0)
        XCTAssertEqual(BusLogMerging.realtimeDispatchWeekday(now: evening, holidays: holidays, calendar: cal), "sunday")
        XCTAssertEqual(
            BusLogMerging.realtimeDispatchMinutes(
                intervals: intervals, logDerivedMinutes: nil, now: evening, holidays: holidays, calendar: cal
            ),
            20
        )
        let eveningLogs: [(String, String)] = [("2026-10-04", "22:30"), ("2026-10-04", "23:00"), ("2026-10-05", "00:20")]
        XCTAssertEqual(
            try visibleLogs(eveningLogs, now: evening, holidays: holidays, intervals: intervals),
            ["10-09 22:30", "10-09 23:00", "10-10 00:20"]
        )

        let afterMidnight = try instant(cal, 2026, 10, 10, 0, 30)
        XCTAssertEqual(BusLogMerging.realtimeDispatchWeekday(now: afterMidnight, holidays: holidays, calendar: cal), "sunday")
        XCTAssertEqual(
            BusLogMerging.realtimeDispatchMinutes(
                intervals: intervals, logDerivedMinutes: nil, now: afterMidnight, holidays: holidays, calendar: cal
            ),
            20
        )
        let afterMidnightLogs: [(String, String)] = [("2026-10-05", "00:50"), ("2026-10-05", "01:20")]
        XCTAssertEqual(
            try visibleLogs(afterMidnightLogs, now: afterMidnight, holidays: holidays, intervals: intervals),
            ["10-10 00:50", "10-10 01:20"]
        )
        XCTAssertEqual(BusLogMerging.realtimeDispatchWeekday(now: evening, holidays: [], calendar: cal), "weekdays")
        XCTAssertEqual(
            BusLogMerging.realtimeDispatchMinutes(
                intervals: intervals, logDerivedMinutes: nil, now: evening, holidays: [], calendar: cal
            ),
            60
        )
    }

    func testDispatchWeekdayAndMinuteFallbacks() throws {
        let cal = try seoulCalendar()
        let cases: [(Date, String)] = [
            (try instant(cal, 2026, 11, 14, 22, 0), "saturday"),
            (try instant(cal, 2026, 11, 15, 10, 0), "sunday"),
            (try instant(cal, 2026, 11, 11, 22, 0), "weekdays"),
            (try instant(cal, 2026, 11, 14, 0, 30), "weekdays"),
            (try instant(cal, 2026, 11, 16, 0, 30), "sunday")
        ]
        for (now, expected) in cases {
            XCTAssertEqual(BusLogMerging.realtimeDispatchWeekday(now: now, holidays: [], calendar: cal), expected)
        }
        let sunday = try instant(cal, 2026, 11, 15, 10, 0)
        XCTAssertEqual(
            BusLogMerging.realtimeDispatchMinutes(
                intervals: [], logDerivedMinutes: 25, now: sunday, holidays: [], calendar: cal
            ),
            25
        )
        XCTAssertEqual(
            BusLogMerging.realtimeDispatchMinutes(
                intervals: [], logDerivedMinutes: nil, now: sunday, holidays: [], calendar: cal
            ),
            0
        )
        XCTAssertEqual(
            BusLogMerging.realtimeDispatchMinutes(
                intervals: [("weekdays", 60)], logDerivedMinutes: 25, now: sunday, holidays: [], calendar: cal
            ),
            25
        )
    }

    func testRequestDatesAgreeWithServiceDayFilter() throws {
        let cal = try seoulCalendar()
        let cases: [(Date, Set<String>)] = [
            (try instant(cal, 2026, 11, 14, 22, 0), []),
            (try instant(cal, 2026, 10, 9, 22, 0), ["2026-10-03", "2026-10-05", "2026-10-09"])
        ]
        for (now, holidays) in cases {
            let dates = BusRecentDates.logRequestDates(now: now, holidays: holidays, calendar: cal)
            for date in dates {
                XCTAssertTrue(
                    BusRecentDates.isLogInCurrentServiceDayType(logDate: date, logHour: 23, now: now, holidays: holidays, calendar: cal) ||
                    BusRecentDates.isLogInCurrentServiceDayType(logDate: date, logHour: 1, now: now, holidays: holidays, calendar: cal),
                    "Request date \(date) should match evening or overnight service type"
                )
            }
        }
    }
}
