//
//  CafeteriaDisplayLogic.swift
//  hyuabot
//

import Api
import Foundation

/// Pure presentation logic shared by cafeteria screens.
enum CafeteriaMeal: Int, CaseIterable, Equatable {
    case breakfast = 0
    case lunch = 1
    case dinner = 2

    var typeKeyword: String {
        switch self {
        case .breakfast: "조식"
        case .lunch: "중식"
        case .dinner: "석식"
        }
    }

    var title: String {
        switch self {
        case .breakfast: String(localized: "cafeteria.tab.breakfast")
        case .lunch: String(localized: "cafeteria.tab.lunch")
        case .dinner: String(localized: "cafeteria.tab.dinner")
        }
    }
}

enum CafeteriaCardStatus: Equatable {
    case beforeOpen, open, closingSoon, closed

    var title: String {
        switch self {
        case .beforeOpen: String(localized: "cafeteria.status.soon")
        case .open: String(localized: "cafeteria.status.open")
        case .closingSoon: String(localized: "cafeteria.status.closing.soon")
        case .closed: String(localized: "cafeteria.status.closed")
        }
    }
}

struct CafeteriaMenuSource: Equatable {
    let type: String
    let food: String
    let price: String
}

struct CafeteriaSource: Equatable {
    let seq: Int
    let runningTimes: [String?]
    let menus: [CafeteriaMenuSource]

    init(seq: Int, runningTimes: [String?], menus: [CafeteriaMenuSource]) {
        self.seq = seq
        self.runningTimes = Array(runningTimes.prefix(3)) + Array(repeating: nil, count: max(0, 3 - runningTimes.count))
        self.menus = menus
    }

    init(_ item: CafeteriaPageQuery.Data.Cafeterium) {
        self.init(
            seq: item.seq,
            runningTimes: [item.runningTime.breakfast, item.runningTime.lunch, item.runningTime.dinner],
            menus: item.menus.map { CafeteriaMenuSource(type: $0.type, food: $0.food, price: $0.price) }
        )
    }

    func runningTime(for meal: CafeteriaMeal) -> String? {
        runningTimes[meal.rawValue]
    }
}

struct CafeteriaMenuRowModel: Equatable {
    let tag: String?
    let main: String
    let sides: String?
    let price: String?
}

struct CafeteriaCardModel: Equatable {
    let seq: Int
    let name: String
    let timeText: String?
    let status: CafeteriaCardStatus?
    let rows: [CafeteriaMenuRowModel]
}

struct CafeteriaWeekDay: Equatable {
    let date: Foundation.Date
    let day: Int
    let weekday: Int
    let isToday: Bool
    let isSelected: Bool
}

enum CafeteriaEmptyState: Equatable {
    case noMenusForDay
    case noMenusForMeal(alternative: CafeteriaMeal)
}

enum CafeteriaDisplayLogic {
    static let isKoreanApp = (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
    private static let hangulRegex = try? NSRegularExpression(pattern: "\\p{Hangul}")

    static func localizedFood(_ food: String, korean: Bool = isKoreanApp) -> String {
        let cleaned = food.replacingOccurrences(of: "\"", with: "")
        guard korean else { return cleaned }
        let tokens = cleaned.components(separatedBy: .whitespaces)
        let filtered = tokens.filter { token in
            hangulRegex?.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)) != nil
        }
        let result = filtered.joined(separator: " ")
        return result.isEmpty ? cleaned : result
    }

    static func cafeteriaName(seq: Int) -> String {
        switch seq {
        case 4: String(localized: "cafeteria.title.4")
        case 6: String(localized: "cafeteria.title.6")
        case 7: String(localized: "cafeteria.title.7")
        case 8: String(localized: "cafeteria.title.8")
        case 11: String(localized: "cafeteria.title.11")
        case 12: String(localized: "cafeteria.title.12")
        case 13: String(localized: "cafeteria.title.13")
        case 14: String(localized: "cafeteria.title.14")
        case 15: String(localized: "cafeteria.title.15")
        case 2: String(localized: "cafeteria.title.2")
        default: String(localized: "cafeteria.title.1")
        }
    }

    static func priceText(_ price: String) -> String? {
        let value = price.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        let number = value.replacingOccurrences(of: "원", with: "")
        return String(format: String(localized: "cafeteria.price.format"), number)
    }

    static func menuRow(food: String, price: String, korean: Bool = isKoreanApp) -> CafeteriaMenuRowModel {
        let trimmed = food.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^\s*(?:\[([^\]]+)\]|<([^>]+)>|([\w가-힣]+\)))\s*"#
        var tag: String?
        var content = trimmed
        if let regex = try? NSRegularExpression(pattern: pattern), let match = regex.firstMatch(
            in: trimmed,
            range: NSRange(trimmed.startIndex..., in: trimmed)
        ) {
            for index in 1 ..< match.numberOfRanges {
                if let valueRange = Range(match.range(at: index), in: trimmed) {
                    let candidate = String(trimmed[valueRange])
                    tag = candidate.contains("천원의 아침밥") ? candidate : nil
                    break
                }
            }
            if let range = Range(match.range, in: trimmed) {
                content.removeSubrange(range)
            }
        }
        let parts = content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return CafeteriaMenuRowModel(
            tag: tag,
            main: localizedFood(parts.first ?? content, korean: korean),
            sides: parts.dropFirst().isEmpty ? nil : parts.dropFirst().map { localizedFood($0, korean: korean) }.joined(separator: " · "),
            price: priceText(price)
        )
    }

    static func minutesRange(_ runningTime: String?) -> (start: Int, end: Int)? {
        guard let runningTime else { return nil }
        let matches = runningTime.matches(of: /\d{1,2}:\d{2}/).compactMap { value -> Int? in
            let parts = value.output.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2, parts[0] < 24, parts[1] < 60 else { return nil }
            return parts[0] * 60 + parts[1]
        }
        guard matches.count >= 2, matches[1] >= matches[0] else { return nil }
        return (matches[0], matches[1])
    }

    static func timeRangeText(_ runningTime: String?) -> String? {
        guard let range = minutesRange(runningTime) else { return nil }
        return "\(formatTime(range.start))–\(formatTime(range.end))"
    }

    static func cardStatus(runningTime: String?, now: Foundation.Date, calendar: Calendar = .current) -> CafeteriaCardStatus? {
        guard let range = minutesRange(runningTime) else { return nil }
        let current = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        if current < range.start {
            return .beforeOpen
        }
        if current > range.end {
            return .closed
        }
        return range.end - current <= 30 ? .closingSoon : .open
    }

    static func isOpen(runningTime: String?, now: Foundation.Date, calendar: Calendar = .current) -> Bool {
        guard let range = minutesRange(runningTime) else { return false }
        let current = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return current >= range.start && current <= range.end
    }

    static func sources(_ sources: [CafeteriaSource], for meal: CafeteriaMeal) -> [CafeteriaSource] {
        sources.filter { source in source.menus.contains { $0.type.contains(meal.typeKeyword) } }.sorted { $0.seq < $1.seq }
    }

    static func counts(from sources: [CafeteriaSource]) -> [CafeteriaMeal: Int] {
        Dictionary(uniqueKeysWithValues: CafeteriaMeal.allCases.map { ($0, self.sources(sources, for: $0).count) })
    }

    static func cards(
        from sources: [CafeteriaSource],
        meal: CafeteriaMeal,
        showsStatus: Bool,
        now: Foundation.Date,
        calendar: Calendar = .current,
        korean: Bool = isKoreanApp
    ) -> [CafeteriaCardModel] {
        self.sources(sources, for: meal).map { source in
            let time = source.runningTime(for: meal)
            return CafeteriaCardModel(
                seq: source.seq,
                name: cafeteriaName(seq: source.seq),
                timeText: time.flatMap(timeRangeText),
                status: showsStatus ? cardStatus(runningTime: time, now: now, calendar: calendar) : nil,
                rows: source.menus
                    .filter { $0.type.contains(meal.typeKeyword) }
                    .map { menuRow(food: $0.food, price: $0.price, korean: korean) }
            )
        }
    }

    static func emptyState(selected meal: CafeteriaMeal, counts: [CafeteriaMeal: Int]) -> CafeteriaEmptyState? {
        guard counts[meal, default: 0] == 0 else { return nil }
        let alternative = CafeteriaMeal.allCases
            .filter { $0 != meal && counts[$0, default: 0] > 0 }
            .min { abs($0.rawValue - meal.rawValue) < abs($1.rawValue - meal.rawValue) }
        if let alternative {
            return .noMenusForMeal(alternative: alternative)
        }
        return .noMenusForDay
    }

    static func weekDays(selected: Foundation.Date, today: Foundation.Date, calendar: Calendar = .current) -> [CafeteriaWeekDay] {
        let selectedDay = calendar.startOfDay(for: selected)
        let todayDay = calendar.startOfDay(for: today)
        let weekday = calendar.component(.weekday, from: selectedDay)
        let daysSinceMonday = (weekday + 5) % 7
        let start = calendar.date(byAdding: .day, value: -daysSinceMonday, to: selectedDay) ?? selectedDay
        return (0 ..< 7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return CafeteriaWeekDay(
                date: date,
                day: calendar.component(.day, from: date),
                weekday: calendar.component(.weekday, from: date),
                isToday: date == todayDay,
                isSelected: date == selectedDay
            )
        }
    }

    static func shareText(sources: [CafeteriaSource], meal: CafeteriaMeal, date: Foundation.Date) -> String? {
        let entries = self.sources(sources, for: meal).compactMap { source -> String? in
            var seen = Set<String>()
            let names = source.menus.filter { $0.type.contains(meal.typeKeyword) }.compactMap { menu -> String? in
                let clean = menu.food.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let name = clean.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? ""
                guard !name.isEmpty, seen.insert(name).inserted else { return nil }
                return name + (priceText(menu.price).map { " (\($0))" } ?? "")
            }
            guard !names.isEmpty else { return nil }
            return "\(cafeteriaName(seq: source.seq))\n" + names.joined(separator: "\n")
        }
        guard !entries.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "yyyy.MM.dd"
        return "\(formatter.string(from: date)) \(meal.title)\n\n" + entries.joined(separator: "\n\n")
    }

    private static func formatTime(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
