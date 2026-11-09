//
//  InquiryChatModel.swift
//  hyuabot
//

import UIKit

enum InquiryQuickReply: String, CaseIterable, Equatable {
    case lostItem
    case timetable

    var question: String {
        switch self {
        case .lostItem: String(localized: "inquiry.quick.lostItem.question")
        case .timetable: String(localized: "inquiry.quick.timetable.question")
        }
    }

    var detail: String {
        switch self {
        case .lostItem: String(localized: "inquiry.quick.lostItem.description")
        case .timetable: String(localized: "inquiry.quick.timetable.description")
        }
    }

    var chipTitle: String {
        switch self {
        case .lostItem: String(localized: "inquiry.quick.lostItem.chip")
        case .timetable: String(localized: "inquiry.quick.timetable.chip")
        }
    }

    var iconName: String {
        switch self {
        case .lostItem: "bag"
        case .timetable: "clock"
        }
    }
}

struct InquiryChatRow: Equatable {
    enum Kind: Equatable {
        case date(String)
        case system(String)
        case user(body: String, time: String, isRead: Bool)
        case admin(body: String, time: String, showsSenderLabel: Bool)
    }

    let kind: Kind
    let topSpacing: CGFloat
}

struct InquiryConversationContent: Equatable {
    var showsWelcome: Bool
    var showsQuickList: Bool
    var chatRows: [InquiryChatRow]
    var answer: InquiryQuickReply?
    var showsError: Bool
    var showsChips: Bool
}

enum InquiryChatModel {
    static func messageDate(from raw: String) -> Date? {
        ISO8601DateFormatter().date(from: String(raw.split(separator: "[", maxSplits: 1).first ?? ""))
    }

    static func rows(
        from messages: [InquiryMessageDTO],
        now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> [InquiryChatRow] {
        var rows: [InquiryChatRow] = []
        var previousMessageDate: Date?
        for message in messages {
            let date = messageDate(from: message.createdAt) ?? now
            if shouldAddDateRow(date, previousDate: previousMessageDate, calendar: calendar) {
                rows.append(InquiryChatRow(kind: .date(dateTitle(date, now: now, calendar: calendar, locale: locale)),
                                           topSpacing: rows.isEmpty ? 0 : 24))
            }
            rows.append(messageRow(message, date: date, previous: rows.last, calendar: calendar, locale: locale))
            previousMessageDate = date
        }
        return rows
    }

    private static func shouldAddDateRow(_ date: Date, previousDate: Date?, calendar: Calendar) -> Bool {
        guard let previousDate else { return true }
        return !calendar.isDate(date, inSameDayAs: previousDate)
    }

    static func content(
        messages: [InquiryMessageDTO],
        loadFailed: Bool,
        selected: InquiryQuickReply?,
        now: Date = .now,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> InquiryConversationContent {
        let chatRows = rows(from: messages, now: now, calendar: calendar, locale: locale)
        let hasMessages = !chatRows.isEmpty
        return InquiryConversationContent(
            showsWelcome: !hasMessages,
            showsQuickList: !hasMessages && selected == nil,
            chatRows: chatRows,
            answer: selected,
            showsError: loadFailed,
            showsChips: hasMessages || selected != nil
        )
    }

    private static func messageRow(
        _ message: InquiryMessageDTO,
        date: Date,
        previous: InquiryChatRow?,
        calendar: Calendar,
        locale: Locale
    ) -> InquiryChatRow {
        let time = timeTitle(date, calendar: calendar, locale: locale)
        let sameSender = previous.map { row in
            switch (row.kind, message.senderType) {
            case (.user, "USER"), (.admin, "ADMIN"): true
            default: false
            }
        } ?? false
        let spacing: CGFloat = sameSender ? 8 : 16
        switch message.senderType {
        case "USER":
            return InquiryChatRow(
                kind: .user(body: message.body, time: time, isRead: message.readAt != nil),
                topSpacing: spacing
            )
        case "ADMIN":
            return InquiryChatRow(
                kind: .admin(body: message.body, time: time, showsSenderLabel: !sameSender),
                topSpacing: spacing
            )
        default: return InquiryChatRow(kind: .system(message.body), topSpacing: spacing)
        }
    }

    private static func dateTitle(_ date: Date, now: Date, calendar: Calendar, locale: Locale) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "inquiry.date.today") }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return formatter.string(from: date)
    }

    private static func timeTitle(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
