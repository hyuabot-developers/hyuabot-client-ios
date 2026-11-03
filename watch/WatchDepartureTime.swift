//
//  WatchDepartureTime.swift
//  hyuabot
//

import Foundation

enum WatchDepartureTime {
    /// Minutes remaining before a departure is considered imminent.
    static let imminentThresholdMinutes = 3

    /// Parses a departure time on today or tomorrow in the supplied calendar.
    static func departureDate(from time: String, now: Date, calendar: Calendar = .current) -> Date? {
        let parts = time.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2 || parts.count == 3,
              let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0..<24).contains(hour), (0..<60).contains(minute) else {
            return nil
        }
        let second = parts.count == 3 ? Int(parts[2]) : 0
        guard let second, (0..<60).contains(second) else { return nil }

        guard var departure = calendar.date(bySettingHour: hour, minute: minute, second: second, of: now) else { return nil }
        if departure < now.addingTimeInterval(-12 * 60 * 60) {
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: departure) else { return nil }
            departure = tomorrow
        }
        return departure
    }

    /// Returns the ceiling of remaining minutes, with subminute times shown as zero.
    static func minutesUntil(_ departure: Date, now: Date) -> Int {
        let seconds = departure.timeIntervalSince(now)
        return seconds < 60 ? 0 : Int((seconds / 60).rounded(.up))
    }

    /// Reports whether a departure falls within the imminent threshold.
    static func isImminent(minutes: Int) -> Bool {
        minutes <= imminentThresholdMinutes
    }

    /// Formats a date as a zero-padded 24-hour clock time.
    static func clockText(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
