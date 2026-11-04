import Api
import Apollo
import AppIntents
import SwiftUI
import WidgetKit

private let appGroupID = "group.net.jaram.hyuabot"

// MARK: - Models

extension MealType {
    var deepLinkURL: URL {
        switch self {
        case .breakfast, .closed:
            URL(string: "hyuabot://cafeteria?tab=breakfast")!
        case .lunch:
            URL(string: "hyuabot://cafeteria?tab=lunch")!
        case .dinner:
            URL(string: "hyuabot://cafeteria?tab=dinner")!
        }
    }
}

struct CafeteriaEntry: TimelineEntry {
    let date: Foundation.Date
    let mealType: MealType
    let items: [CafeteriaMenuItem]
    let menuDate: Foundation.Date
    var loadFailed: Bool = false
    var isNextDay: Bool { mealType == .closed }
}

// MARK: - Helpers

private func currentMealType(for date: Foundation.Date = .now) -> MealType {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case ..<10: return .breakfast
    case 10 ..< 15: return .lunch
    case 15 ..< 20: return .dinner
    default: return .closed
    }
}

private func cafeteriaMenuDate(for date: Foundation.Date, mealType: MealType) -> Foundation.Date {
    guard mealType == .closed else { return date }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
    return calendar.date(byAdding: .day, value: 1, to: date) ?? date
}

private func cafeteriaDisplayName(for seq: Int) -> String {
    let key = switch seq {
    case 1: "cafeteria.title.1"
    case 2: "cafeteria.title.2"
    case 4: "cafeteria.title.4"
    case 6: "cafeteria.title.6"
    case 7: "cafeteria.title.7"
    case 8: "cafeteria.title.8"
    case 11: "cafeteria.title.11"
    case 12: "cafeteria.title.12"
    case 13: "cafeteria.title.13"
    case 14: "cafeteria.title.14"
    case 15: "cafeteria.title.15"
    default: "cafeteria.default"
    }
    return String(localized: LocalizedStringResource(stringLiteral: key))
}

private func nextMealTransition(after date: Foundation.Date) -> Foundation.Date {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: date)
    switch hour {
    case ..<10:
        return cal.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
    case 10 ..< 15:
        return cal.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
    case 15 ..< 20:
        return cal.date(bySettingHour: 20, minute: 0, second: 0, of: date)!
    default:
        let tomorrow = cal.date(byAdding: .day, value: 1, to: date)!
        return cal.startOfDay(for: tomorrow)
    }
}

// MARK: - Provider

struct CafeteriaProvider: TimelineProvider {
    func placeholder(in context: Context) -> CafeteriaEntry {
        CafeteriaEntry(
            date: .now,
            mealType: .lunch,
            items: [
                CafeteriaMenuItem(cafeteriaName: "학생식당", menus: [
                    CafeteriaMenuRow(food: "된장찌개", price: "2000"),
                    CafeteriaMenuRow(food: "돈까스", price: "4000"),
                    CafeteriaMenuRow(food: "잡채", price: "1500")
                ], runningTime: "11:00~13:30"),
                CafeteriaMenuItem(cafeteriaName: "창업보육센터", menus: [
                    CafeteriaMenuRow(food: "뼈다귀탕", price: "5500"),
                    CafeteriaMenuRow(food: "볶음밥", price: "3000"),
                    CafeteriaMenuRow(food: "미역국", price: "2000")
                ], runningTime: "11:30~13:30"),
                CafeteriaMenuItem(cafeteriaName: "창의인재관식당", menus: [
                    CafeteriaMenuRow(food: "닭갈비", price: "6000"),
                    CafeteriaMenuRow(food: "쌀국수", price: "4500")
                ], runningTime: "11:30~13:00")
            ],
            menuDate: .now
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CafeteriaEntry) -> Void) {
#if DEBUG
        if let name = WidgetQAFixture.selected(prefix: "cafeteria") {
            if name == "cafeteria-placeholder" {
                completion(placeholder(in: context))
                return
            }
            if let entry = WidgetQAFixture.cafeteriaEntry(named: name) {
                completion(entry)
                return
            }
        }
#endif
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let completion = WidgetCompletion(completion)
        Task {
            let entry = await fetchEntry(for: .now)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CafeteriaEntry>) -> Void) {
        let completion = WidgetCompletion(completion)
#if DEBUG
        if let name = WidgetQAFixture.selected(prefix: "cafeteria") {
            if name == "cafeteria-placeholder" {
                let placeholderEntry = placeholder(in: context)
                Task {
                    await WidgetQAFixture.holdForPlaceholderCapture()
                    completion(Timeline(entries: [placeholderEntry], policy: .never))
                }
                return
            }
            if let entry = WidgetQAFixture.cafeteriaEntry(named: name) {
                completion(Timeline(entries: [entry], policy: .never))
                return
            }
        }
#endif
        Task {
            let now = Foundation.Date.now
            let entry = await fetchEntry(for: now)
            let nextUpdate = nextMealTransition(after: now)
            let dates = CafeteriaPresentation.timelineDates(
                for: entry.items,
                from: now,
                until: nextUpdate,
                isNextDay: entry.isNextDay
            )
            let entries = dates.map { date in
                CafeteriaEntry(
                    date: date,
                    mealType: entry.mealType,
                    items: entry.items,
                    menuDate: entry.menuDate,
                    loadFailed: entry.loadFailed
                )
            }
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry(for date: Foundation.Date) async -> CafeteriaEntry {
        let storedCampusID = UserDefaults(suiteName: appGroupID)?.integer(forKey: "campusID") ?? 0
        let campusID = storedCampusID == 0 ? 2 : storedCampusID
        let mealType = currentMealType(for: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let menuDate = cafeteriaMenuDate(for: date, mealType: mealType)
        let dateString = dateFormatter.string(from: menuDate)

        do {
            let response = try await WidgetNetwork.shared.fetch(query: CafeteriaPageQuery(date: dateString, campusID: Int32(campusID)))

            guard let cafeteria = response.data?.cafeteria else {
                return CafeteriaEntry(date: date, mealType: mealType, items: [], menuDate: menuDate, loadFailed: true)
            }

            let typeStr = mealType.typeString
            let isKorean = (Locale.current.language.languageCode?.identifier ?? "ko").hasPrefix("ko")
            let hangulRegex = try! NSRegularExpression(pattern: "\\p{Hangul}")
            func localizedFood(_ food: String) -> String {
                let cleaned = food.replacingOccurrences(of: "\"", with: "")
                guard isKorean else { return cleaned }
                let tokens = cleaned.components(separatedBy: .whitespaces)
                let filtered = tokens.filter { token in
                    hangulRegex.firstMatch(in: token, range: NSRange(token.startIndex..., in: token)) != nil
                }
                let result = filtered.joined(separator: " ")
                return result.isEmpty ? cleaned : result
            }
            let items: [CafeteriaMenuItem] = cafeteria
                .filter { $0.menus.contains(where: { $0.type.contains(typeStr) }) }
                .sorted { $0.seq < $1.seq }
                .compactMap { cafe in
                    let typed = cafe.menus.filter { $0.type.contains(typeStr) }
                    guard !typed.isEmpty else { return nil }
                    let menus = typed.map { m in
                        CafeteriaMenuRow(
                            food: localizedFood(m.food),
                            price: m.price
                                .replacingOccurrences(of: "원", with: "")
                                .trimmingCharacters(in: .whitespaces)
                        )
                    }
                    let runningTime: String? = switch mealType {
                    case .breakfast, .closed: cafe.runningTime.breakfast
                    case .lunch: cafe.runningTime.lunch
                    case .dinner: cafe.runningTime.dinner
                    }
                    return CafeteriaMenuItem(
                        cafeteriaName: cafeteriaDisplayName(for: cafe.seq),
                        menus: menus,
                        runningTime: runningTime
                    )
                }

            return CafeteriaEntry(date: date, mealType: mealType, items: items, menuDate: menuDate)
        } catch {
            return CafeteriaEntry(date: date, mealType: mealType, items: [], menuDate: menuDate, loadFailed: true)
        }
    }
}

// MARK: - Widget

struct CafeteriaWidget: Widget {
    let kind = "CafeteriaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CafeteriaProvider()) { entry in
            CafeteriaWidgetView(entry: entry)
                .containerBackground(HYUWidgetColor.background, for: .widget)
                .widgetURL(entry.mealType.deepLinkURL)
        }
        .configurationDisplayName("widget.cafeteria.name")
        .description("widget.cafeteria.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    CafeteriaWidget()
} timeline: {
    CafeteriaEntry(date: .now, mealType: .lunch, items: [
        CafeteriaMenuItem(cafeteriaName: "학생식당", menus: [CafeteriaMenuRow(food: "된장찌개", price: "2000")], runningTime: "11:00~13:30")
    ], menuDate: .now)
}

#Preview("Medium", as: .systemMedium) {
    CafeteriaWidget()
} timeline: {
    CafeteriaEntry(date: .now, mealType: .lunch, items: [
        CafeteriaMenuItem(cafeteriaName: "학생식당", menus: [CafeteriaMenuRow(food: "된장찌개", price: "2000")], runningTime: "11:00~13:30"),
        CafeteriaMenuItem(cafeteriaName: "창업보육센터", menus: [CafeteriaMenuRow(food: "뼈다귀탕", price: "5500")], runningTime: "11:30~13:30")
    ], menuDate: .now)
}

#Preview("Large", as: .systemLarge) {
    CafeteriaWidget()
} timeline: {
    CafeteriaEntry(
        date: .now,
        mealType: .lunch,
        items: [
            CafeteriaMenuItem(cafeteriaName: "학생식당", menus: [
                CafeteriaMenuRow(food: "된장찌개", price: "2000"),
                CafeteriaMenuRow(food: "돈까스", price: "4000"),
                CafeteriaMenuRow(food: "잡채", price: "1500")
            ], runningTime: "11:00~13:30"),
            CafeteriaMenuItem(cafeteriaName: "창업보육센터", menus: [
                CafeteriaMenuRow(food: "뼈다귀탕", price: "5500"),
                CafeteriaMenuRow(food: "볶음밥", price: "3000"),
                CafeteriaMenuRow(food: "미역국", price: "2000")
            ], runningTime: "11:30~13:30"),
            CafeteriaMenuItem(cafeteriaName: "창의인재관식당", menus: [
                CafeteriaMenuRow(food: "닭갈비", price: "6000"),
                CafeteriaMenuRow(food: "쌀국수", price: "4500")
            ], runningTime: "11:30~13:00")
        ],
        menuDate: .now
    )
}
