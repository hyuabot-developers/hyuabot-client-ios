//
//  BusRecentDates.swift
//  hyuabot
//

import Foundation

/// Picks recent calendar dates that share today's weekday "type" (weekdays / Saturday / Sunday),
/// so departure-log based ETA estimates use logs from comparable service schedules.
enum BusRecentDates {
    static func sameWeekdayType(
        count: Int,
        from date: Date = .now,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [String] {
        var cal = calendar
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "yyyy-MM-dd"
        }
        let dayInterval: TimeInterval = 60 * 60 * 24
        // Buckets match the app's existing convention: "weekdays" (Mon-Fri), "saturday", "sunday" —
        // Sat/Sun run different schedules, so they must not be pooled together.
        let todayWeekday = cal.component(.weekday, from: date)
        let isWeekendBucket = todayWeekday == 1 || todayWeekday == 7

        var results: [String] = []
        var cursor = date
        while results.count < count {
            let weekday = cal.component(.weekday, from: cursor)
            let matchesBucket = isWeekendBucket ? weekday == todayWeekday : (weekday != 1 && weekday != 7)
            if matchesBucket {
                results.append(formatter.string(from: cursor))
            }
            cursor = cursor.addingTimeInterval(isWeekendBucket ? -dayInterval * 7 : -dayInterval)
        }
        return results
    }

    enum BusDayType: Equatable {
        case weekdays
        case saturday
        case sunday
    }

    private static func seoul(_ calendar: Calendar) -> Calendar {
        var cal = calendar
        cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return cal
    }

    private static func dateFormatter(_ cal: Calendar) -> DateFormatter {
        DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = cal.timeZone
            $0.dateFormat = "yyyy-MM-dd"
        }
    }

    private static func adding(days: Int, to date: Date, _ cal: Calendar) -> Date {
        cal.date(byAdding: .day, value: days, to: date)
            ?? date.addingTimeInterval(TimeInterval(days) * 86_400)
    }

    /// Public holidays run the Sunday timetable (same rule as the backend's resolveWeekday);
    /// an empty set means plain weekday/Saturday/Sunday classification when holiday data is unavailable.
    static func dayType(
        of date: Date,
        holidays: Set<String> = [],
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> BusDayType {
        let cal = seoul(calendar)
        if !holidays.isEmpty && holidays.contains(dateFormatter(cal).string(from: date)) {
            return .sunday
        }
        switch cal.component(.weekday, from: date) {
        case 7: return .saturday
        case 1: return .sunday
        default: return .weekdays
        }
    }

    static func recentDates(
        of type: BusDayType,
        from start: Date,
        count: Int,
        holidays: Set<String> = [],
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [Date] {
        let cal = seoul(calendar)
        let day0 = cal.startOfDay(for: start)
        var result: [Date] = []
        guard count > 0 else { return result }
        for offset in 0..<35 {
            let date = adding(days: -offset, to: day0, cal)
            if dayType(of: date, holidays: holidays, calendar: calendar) == type {
                result.append(date)
                if result.count == count { break }
            }
        }
        return result
    }

    static func logRequestDates(
        count: Int = 4,
        now: Date = .now,
        holidays: Set<String> = [],
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [String] {
        let cal = seoul(calendar)
        let formatter = dateFormatter(cal)
        let today = cal.startOfDay(for: now)
        var ordered: [Date] = []
        if cal.component(.hour, from: now) >= 4 {
            let dates = recentDates(
                of: dayType(of: today, holidays: holidays, calendar: calendar),
                from: today, count: count, holidays: holidays, calendar: calendar
            )
            for date in dates {
                ordered.append(date)
                ordered.append(adding(days: 1, to: date, cal))
            }
        } else {
            let previous = adding(days: -1, to: today, cal)
            let eveningDates = recentDates(
                of: dayType(of: previous, holidays: holidays, calendar: calendar),
                from: previous, count: count, holidays: holidays, calendar: calendar
            )
            let todayDates = recentDates(
                of: dayType(of: today, holidays: holidays, calendar: calendar),
                from: today, count: count, holidays: holidays, calendar: calendar
            )
            for index in 0..<max(eveningDates.count, todayDates.count) {
                if index < eveningDates.count { ordered.append(adding(days: 1, to: eveningDates[index], cal)) }
                if index < todayDates.count { ordered.append(todayDates[index]) }
            }
        }
        var seen = Set<String>()
        return ordered.map { formatter.string(from: $0) }.filter { seen.insert($0).inserted }
    }

    static func isLogInCurrentServiceDayType(
        logDate: String,
        logHour: Int,
        now: Date = .now,
        holidays: Set<String> = [],
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Bool {
        let cal = seoul(calendar)
        guard let parsed = dateFormatter(cal).date(from: logDate) else { return false }
        let today = cal.startOfDay(for: now)
        let currentServiceDay = cal.component(.hour, from: now) < 4
            ? adding(days: -1, to: today, cal)
            : today
        if logHour >= 4 {
            return dayType(of: parsed, holidays: holidays, calendar: calendar)
                == dayType(of: today, holidays: holidays, calendar: calendar)
        }
        return dayType(of: adding(days: -1, to: parsed, cal), holidays: holidays, calendar: calendar)
            == dayType(of: currentServiceDay, holidays: holidays, calendar: calendar)
    }
}
