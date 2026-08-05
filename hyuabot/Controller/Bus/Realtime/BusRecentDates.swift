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
}
