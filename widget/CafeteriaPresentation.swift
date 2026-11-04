//
//  CafeteriaPresentation.swift
//  hyuabot
//

import Foundation

enum MealType {
    case breakfast, lunch, dinner, closed

    var title: String {
        switch self {
        case .breakfast: String(localized: "meal.breakfast")
        case .lunch: String(localized: "meal.lunch")
        case .dinner: String(localized: "meal.dinner")
        case .closed: String(localized: "meal.closed")
        }
    }

    var typeString: String {
        switch self {
        case .breakfast, .closed: "조식"
        case .lunch: "중식"
        case .dinner: "석식"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.stars.fill"
        case .closed: "moon.zzz.fill"
        }
    }
}

struct CafeteriaMenuRow: Identifiable {
    let id = UUID()
    let food: String
    let price: String
}

struct CafeteriaMenuItem: Identifiable {
    let id = UUID()
    let cafeteriaName: String
    let menus: [CafeteriaMenuRow]
    let runningTime: String?
}

enum CafeteriaRunningStatus: Equatable {
    case open(closing: String)
    case closingSoon(closing: String)
    case upcoming(opening: String)
    case closed
    case unknown(raw: String)
}

enum CafeteriaStatusStyle { case compact, full, column }
enum MealSegmentState { case done, current, upcoming }

enum CafeteriaLayoutMetrics {
    static let nameRowHeight: CGFloat = 18
    static let statusRowHeight: CGFloat = 14
    static let menuRowHeight: CGFloat = 14.5
    static let menuSpacing: CGFloat = 3
    static let statusGap: CGFloat = 4
    static let blockGap: CGFloat = 17
    static let footerHeight: CGFloat = 18
    static let compactMenuLimit = 1
    static let xlMaxColumns = 5
}

enum CafeteriaPresentation {
    static func status(runningTime: String?, now: Date, isNextDay: Bool) -> CafeteriaRunningStatus? {
        guard let runningTime else { return nil }
        let trimmed = runningTime.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let range = parseRange(trimmed) else { return .unknown(raw: trimmed) }
        let opening = timeString(range.start)
        let closing = timeString(range.end)
        if isNextDay {
            return .upcoming(opening: opening)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let nowMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if nowMinutes < range.start {
            return .upcoming(opening: opening)
        }
        if nowMinutes >= range.end {
            return .closed
        }
        if nowMinutes >= range.end - 30 {
            return .closingSoon(closing: closing)
        }
        return .open(closing: closing)
    }

    static func label(for status: CafeteriaRunningStatus, style: CafeteriaStatusStyle) -> String {
        switch status {
        case let .open(closing):
            if style == .compact {
                return "~\(closing)"
            }
            let key = style == .column ? "cafeteria.status.until.format" : "cafeteria.status.open.format"
            return String(format: String(localized: String.LocalizationValue(key)), closing)
        case let .closingSoon(closing):
            if style == .compact {
                return "~\(closing)"
            }
            return String(format: String(localized: "cafeteria.status.soon.format"), closing)
        case let .upcoming(opening):
            return String(format: String(localized: "cafeteria.status.upcoming.format"), opening)
        case .closed:
            return String(localized: "cafeteria.status.closed")
        case let .unknown(raw): return raw
        }
    }

    static func sortedForDisplay(_ items: [CafeteriaMenuItem], now: Date, isNextDay: Bool) -> [CafeteriaMenuItem] {
        items.enumerated().sorted { lhs, rhs in
            let leftRank = rank(status(runningTime: lhs.element.runningTime, now: now, isNextDay: isNextDay))
            let rightRank = rank(status(runningTime: rhs.element.runningTime, now: now, isNextDay: isNextDay))
            return leftRank == rightRank ? lhs.offset < rhs.offset : leftRank < rightRank
        }.map(\.element)
    }

    static func blockHeight(menuCount: Int) -> CGFloat {
        CafeteriaLayoutMetrics
            .nameRowHeight + CGFloat(menuCount) * (CafeteriaLayoutMetrics.menuSpacing + CafeteriaLayoutMetrics.menuRowHeight)
    }

    static func fittingCount(of items: [CafeteriaMenuItem], availableHeight: CGFloat) -> Int {
        let count = countFitting(items, height: availableHeight)
        return count == items.count ? count : countFitting(items, height: availableHeight - CafeteriaLayoutMetrics.footerHeight)
    }

    static func columnHeight(menuCount: Int) -> CGFloat {
        CafeteriaLayoutMetrics.nameRowHeight + CafeteriaLayoutMetrics.menuSpacing + CafeteriaLayoutMetrics
            .statusRowHeight + CafeteriaLayoutMetrics
            .statusGap + CGFloat(menuCount) * (CafeteriaLayoutMetrics.menuSpacing + CafeteriaLayoutMetrics.menuRowHeight)
    }

    static func fittingColumns(of items: [CafeteriaMenuItem], availableHeight: CGFloat, maxColumns: Int) -> [CafeteriaMenuItem] {
        let picked = pick(items, height: availableHeight, maxColumns: maxColumns)
        return picked.count == items.count ? picked : pick(
            items,
            height: availableHeight - CafeteriaLayoutMetrics.footerHeight,
            maxColumns: maxColumns
        )
    }

    static func timelineDates(for items: [CafeteriaMenuItem], from start: Date, until end: Date, isNextDay: Bool) -> [Date] {
        guard !isNextDay, end > start else { return [start] }
        var dates = [start]
        for item in items {
            guard let range = parseRange(item.runningTime ?? ""), range.end > range.start else { continue }
            dates += [range.start, range.end - 30, range.end].compactMap {
                guard let instant = date(for: $0, on: start), instant > start, instant < end else { return nil }
                return instant
            }
        }
        return Array(Set(dates)).sorted()
    }

    static func mealSegments(for meal: MealType) -> [MealSegmentState] {
        switch meal {
        case .breakfast, .closed: [.current, .upcoming, .upcoming]
        case .lunch: [.done, .current, .upcoming]
        case .dinner: [.done, .done, .current]
        }
    }

    static func formattedPrice(_ raw: String) -> String {
        let cleaned = raw.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, cleaned.allSatisfy(\.isNumber), let number = Int(cleaned) else { return raw }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: number)) ?? raw
    }

    private static func countFitting(_ items: [CafeteriaMenuItem], height: CGFloat) -> Int {
        var used: CGFloat = 0
        for (index, item) in items.enumerated() {
            let proposed = used + (index == 0 ? 0 : CafeteriaLayoutMetrics.blockGap) + blockHeight(menuCount: item.menus.count)
            guard proposed <= height else { return index }
            used = proposed
        }
        return items.count
    }

    private static func pick(_ items: [CafeteriaMenuItem], height: CGFloat, maxColumns: Int) -> [CafeteriaMenuItem] {
        var result: [CafeteriaMenuItem] = []
        for item in items where result.count < maxColumns {
            if columnHeight(menuCount: item.menus.count) <= height {
                result.append(item)
            }
        }
        return result
    }

    private static func rank(_ status: CafeteriaRunningStatus?) -> Int {
        switch status {
        case .upcoming: 1
        case .closed: 2
        default: 0
        }
    }

    private static func parseRange(_ raw: String) -> (start: Int, end: Int)? {
        let separator = raw.contains("~") ? "~" : "-"
        let parts = raw.components(separatedBy: separator).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let start = parseTime(parts[0]), let end = parseTime(parts[1]) else { return nil }
        return (start, end)
    }

    private static func parseTime(_ raw: String) -> Int? {
        let parts = raw.split(separator: ":")
        guard parts.count == 2, parts[0].count == 1 || parts[0].count == 2, parts[1].count == 2,
              let hour = Int(parts[0]), let minute = Int(parts[1]), (0 ... 23).contains(hour),
              (0 ... 59).contains(minute) else { return nil }
        return hour * 60 + minute
    }

    private static func timeString(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private static func date(for minutes: Int, on day: Date) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
        return calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day)
    }
}
