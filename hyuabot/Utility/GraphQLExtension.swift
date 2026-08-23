import Foundation

private enum GraphQLDateFormatters {
    nonisolated(unsafe) static let localDate: DateFormatter = makeFormatter(dateFormat: "yyyy-MM-dd")
    nonisolated(unsafe) static let localTime: DateFormatter = makeFormatter(dateFormat: "HH:mm:ss")

    nonisolated(unsafe) static let zonedFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let zoned: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func makeFormatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = dateFormat
        return formatter
    }
}

extension String {
    func toLocalDate() -> Foundation.Date {
        toLocalDateOrNil() ?? Date.now
    }

    func toLocalDateOrNil() -> Foundation.Date? {
        GraphQLDateFormatters.localDate.date(from: self)
    }

    func toLocalTime() -> Foundation.Date {
        toLocalTimeOrNil() ?? Date.now
    }

    func toLocalTimeOrNil() -> Foundation.Date? {
        // The API may serialize LocalTime with fractional seconds (for example,
        // realtime destination ETAs). LocalTime is second-precision for the UI,
        // so discard the fractional part before parsing it.
        let normalizedTime = String(split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)[0])
        guard let time = GraphQLDateFormatters.localTime.date(from: normalizedTime) else { return nil }
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date.now)
        var merged = DateComponents()
        merged.year = todayComponents.year
        merged.month = todayComponents.month
        merged.day = todayComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        return calendar.date(from: merged)
    }

    func toZonedDateTime() -> Foundation.Date {
        toZonedDateTimeOrNil() ?? Date.now
    }

    func toZonedDateTimeOrNil() -> Foundation.Date? {
        if let date = GraphQLDateFormatters.zonedFractional.date(from: self) {
            return date
        }
        return GraphQLDateFormatters.zoned.date(from: self)
    }
}

extension Foundation.Date {
    func toLocalDateString() -> String {
        GraphQLDateFormatters.localDate.string(from: self)
    }

    func toLocalTimeString() -> String {
        GraphQLDateFormatters.localTime.string(from: self)
    }

    func toZonedDateTimeString() -> String {
        GraphQLDateFormatters.zonedFractional.string(from: self)
    }

    /// Seconds since the start of the current bus service day, which rolls over at 04:00
    /// local time. Times earlier than 04:00 belong to the previous day's service window
    /// and are shifted by 24h so before/after comparisons work across the boundary.
    var busServiceSeconds: Int {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
        return seconds < 4 * 3600 ? seconds + 86400 : seconds
    }
}
