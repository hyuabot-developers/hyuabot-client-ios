import Foundation

extension String {
    func toLocalDate() -> Foundation.Date {
        let formatter = DateFormatter().then {
            $0.calendar = Calendar(identifier: .iso8601)
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "yyyy-MM-dd"
        }
        guard let date = formatter.date(from: self) else {
            fatalError("Invalid date string: \(self)")
        }
        return date
    }
    
    func toLocalTime() -> Foundation.Date {
        guard let time = toLocalTimeOrNil() else {
            fatalError("Invalid time string: \(self)")
        }
        return time
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
        let formatter = ISO8601DateFormatter().then {
            $0.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        }
        guard let dateTime = formatter.date(from: self) else {
            fatalError("Invalid datetime string: \(self)")
        }
        return dateTime
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
