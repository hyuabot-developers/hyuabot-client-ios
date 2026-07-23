import Foundation

extension String {
    func toLocalDate() -> Foundation.Date {
        toLocalDateOrNil() ?? Date.now
    }

    func toLocalDateOrNil() -> Foundation.Date? {
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "yyyy-MM-dd"
        }
        return formatter.date(from: self)
    }

    func toLocalTime() -> Foundation.Date {
        toLocalTimeOrNil() ?? Date.now
    }

    func toLocalTimeOrNil() -> Foundation.Date? {
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "HH:mm:ss"
        }
        guard let time = formatter.date(from: self) else { return nil }
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
        let formatOptions: [ISO8601DateFormatter.Options] = [
            [.withInternetDateTime, .withFractionalSeconds],
            [.withInternetDateTime]
        ]
        for options in formatOptions {
            let formatter = ISO8601DateFormatter().then {
                $0.formatOptions = options
            }
            if let date = formatter.date(from: self) {
                return date
            }
        }
        return nil
    }
}

extension Foundation.Date {
    func toLocalDateString() -> String {
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "yyyy-MM-dd"
        }
        return formatter.string(from: self)
    }

    func toLocalTimeString() -> String {
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "HH:mm:ss"
        }
        return formatter.string(from: self)
    }

    func toZonedDateTimeString() -> String {
        let formatter = ISO8601DateFormatter().then {
            $0.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        }
        return formatter.string(from: self)
    }
}
