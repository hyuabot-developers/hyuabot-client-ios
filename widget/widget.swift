import Api
import Apollo
import AppIntents
import SwiftUI
import WidgetKit

private let appGroupID = "group.net.jaram.hyuabot"

// MARK: - Models

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

struct CafeteriaEntry: TimelineEntry {
    let date: Foundation.Date
    let mealType: MealType
    let items: [CafeteriaMenuItem]
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
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CafeteriaEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let entry = await fetchEntry(for: .now)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CafeteriaEntry>) -> Void) {
        Task {
            let now = Foundation.Date.now
            let entry = await fetchEntry(for: now)
            let nextUpdate = nextMealTransition(after: now)
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
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
        let dateString = dateFormatter.string(from: date)

        do {
            let response = try await WidgetNetwork.shared.fetch(query: CafeteriaPageQuery(date: dateString, campusID: Int32(campusID)))

            guard let cafeteria = response.data?.cafeteria else {
                return CafeteriaEntry(date: date, mealType: mealType, items: [])
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

            return CafeteriaEntry(date: date, mealType: mealType, items: items)
        } catch {
            return CafeteriaEntry(date: date, mealType: mealType, items: [])
        }
    }
}

// MARK: - Views

struct CafeteriaLargeView: View {
    let entry: CafeteriaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: entry.mealType.icon)
                    .foregroundStyle(.blue)
                Text(entry.mealType.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(entry.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(entry.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Button(intent: RefreshCafeteriaIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            if entry.items.isEmpty {
                Text("cafeteria.no.data")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 16)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.items) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.cafeteriaName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                if let rt = item.runningTime {
                                    Text(rt)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer()
                            }
                            ForEach(item.menus) { menu in
                                HStack {
                                    Text(menu.food)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Spacer()
                                    if !menu.price.isEmpty {
                                        Text("\(menu.price)원")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        Divider()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetURL(entry.mealType.deepLinkURL)
    }
}

// MARK: - Widget

struct CafeteriaWidget: Widget {
    let kind = "CafeteriaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CafeteriaProvider()) { entry in
            CafeteriaLargeView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("widget.cafeteria.name")
        .description("widget.cafeteria.description")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

// MARK: - Preview

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
        ]
    )
}
