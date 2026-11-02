//
//  IntentModels.swift
//  hyuabot
//

import Foundation

struct IntentSnippetRow: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let badge: String?
    let isRealtime: Bool
}

struct IntentSnippetContent: Hashable, Sendable {
    let title: String
    let subtitle: String?
    let rows: [IntentSnippetRow]
    let emptyMessage: String
}

struct IntentAnswer: Hashable, Sendable {
    let dialog: String
    let snippet: IntentSnippetContent

    static func failure(title: String) -> IntentAnswer {
        let message = String(localized: "intent.common.error")
        return IntentAnswer(dialog: message, snippet: IntentSnippetContent(title: title, subtitle: nil, rows: [], emptyMessage: message))
    }
}

enum IntentClock {
    static var seoulCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }

    static func timeString(from date: Date, calendar: Calendar) -> String {
        formatter(format: "HH:mm", calendar: calendar).string(from: date)
    }

    static func dateString(from date: Date, calendar: Calendar) -> String {
        formatter(format: "yyyy-MM-dd", calendar: calendar).string(from: date)
    }

    static func shortTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        if parts.count < 2 { return time }
        return "\(parts[0]):\(parts[1])"
    }

    static func minutesUntil(_ time: String, from now: Date, calendar: Calendar) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let diff = hour * 60 + minute - ((nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0))
        return diff >= 0 ? diff : nil
    }

    private static func formatter(format: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.calendar = calendar
        formatter.dateFormat = format
        return formatter
    }
}

enum IntentText {
    static func minutesLater(_ minutes: Int) -> String {
        String(format: String(localized: "intent.common.minutes.later"), "\(minutes)")
    }

    static var realtimeBadge: String { String(localized: "intent.common.realtime") }
    static var scheduledBadge: String { String(localized: "intent.common.scheduled") }
}
