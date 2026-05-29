import WidgetKit
import SwiftUI

private let appGroupID = "group.net.jaram.hyuabot"

private let cafeteriaQuery = """
query CafeteriaPageQuery($date: Date!, $campusID: Int!) {
    cafeteria(input: { date: $date, campus: $campusID }) {
        seq
        runningTime { breakfast lunch dinner }
        menus { type food price }
    }
}
"""

// MARK: - Response Types

private struct CafeteriaResponse: Decodable {
    let cafeteria: [CafeteriaData]

    struct CafeteriaData: Decodable {
        let seq: Int
        let runningTime: RunningTime
        let menus: [Menu]

        struct RunningTime: Decodable {
            let breakfast: String?
            let lunch: String?
            let dinner: String?
        }

        struct Menu: Decodable {
            let type: String
            let food: String
            let price: String
        }
    }
}

// MARK: - Models

enum MealType {
    case breakfast, lunch, dinner, closed

    var title: String {
        switch self {
        case .breakfast: return String(localized: "meal.breakfast")
        case .lunch: return String(localized: "meal.lunch")
        case .dinner: return String(localized: "meal.dinner")
        case .closed: return String(localized: "meal.closed")
        }
    }

    var typeString: String {
        switch self {
        case .breakfast, .closed: return "조식"
        case .lunch: return "중식"
        case .dinner: return "석식"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .closed: return "moon.zzz.fill"
        }
    }
}

struct CafeteriaMenuItem: Identifiable {
    let id = UUID()
    let cafeteriaName: String
    let foods: [String]
    let price: String
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
    case 10..<15: return .lunch
    case 15..<20: return .dinner
    default: return .closed
    }
}

private func cafeteriaDisplayName(for seq: Int) -> String {
    switch seq {
    case 1: return "학생회관"
    case 2: return "생활과학관"
    case 4: return "신소재공학관"
    case 6: return "제1생활관"
    case 7: return "제2생활관"
    case 8: return "행원파크"
    case 11: return "교직원식당"
    case 12: return "학생식당"
    case 13: return "창의인재원"
    case 14: return "푸드코트"
    case 15: return "창업보육센터"
    default: return "식당"
    }
}

private func nextMealTransition(after date: Foundation.Date) -> Foundation.Date {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: date)
    switch hour {
    case ..<10:
        return cal.date(bySettingHour: 10, minute: 0, second: 0, of: date)!
    case 10..<15:
        return cal.date(bySettingHour: 15, minute: 0, second: 0, of: date)!
    case 15..<20:
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
                CafeteriaMenuItem(cafeteriaName: "학생회관", foods: ["된장찌개", "돈까스", "잡채"], price: "3500", runningTime: "11:00~13:30"),
                CafeteriaMenuItem(cafeteriaName: "생활과학관", foods: ["뼈다귀탕", "볶음밥"], price: "5000", runningTime: "11:30~13:30")
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
        let campusID = UserDefaults(suiteName: appGroupID)?.integer(forKey: "campusID") ?? 2
        let mealType = currentMealType(for: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let dateString = dateFormatter.string(from: date)

        do {
            let response: CafeteriaResponse = try await widgetGraphQL(
                query: cafeteriaQuery,
                variables: ["date": dateString, "campusID": campusID]
            )

            let typeStr = mealType.typeString
            let items: [CafeteriaMenuItem] = response.cafeteria
                .filter { $0.menus.contains(where: { $0.type.contains(typeStr) }) }
                .sorted { $0.seq < $1.seq }
                .compactMap { cafe in
                    let filtered = cafe.menus.filter { $0.type.contains(typeStr) }
                    guard !filtered.isEmpty else { return nil }
                    let foods = filtered.map { $0.food }
                    let price = (filtered.first?.price ?? "")
                        .replacingOccurrences(of: "원", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    let runningTime: String? = {
                        switch mealType {
                        case .breakfast, .closed: return cafe.runningTime.breakfast
                        case .lunch: return cafe.runningTime.lunch
                        case .dinner: return cafe.runningTime.dinner
                        }
                    }()
                    return CafeteriaMenuItem(
                        cafeteriaName: cafeteriaDisplayName(for: cafe.seq),
                        foods: foods,
                        price: price,
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

struct CafeteriaWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CafeteriaEntry

    var body: some View {
        switch family {
        case .systemSmall:
            CafeteriaSmallView(entry: entry)
        case .systemMedium:
            CafeteriaMediumView(entry: entry)
        case .systemLarge:
            CafeteriaLargeView(entry: entry)
        default:
            CafeteriaSmallView(entry: entry)
        }
    }
}

struct CafeteriaSmallView: View {
    let entry: CafeteriaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: entry.mealType.icon)
                    .foregroundStyle(.blue)
                    .font(.caption2)
                Text(entry.mealType.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Spacer()
            }

            if let first = entry.items.first {
                Text(first.cafeteriaName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(first.foods.prefix(3), id: \.self) { food in
                        Text(food)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                if !first.price.isEmpty {
                    Text("\(first.price)원")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            } else {
                Spacer()
                Text("cafeteria.no.menu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(12)
    }
}

struct CafeteriaMediumView: View {
    let entry: CafeteriaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: entry.mealType.icon)
                    .foregroundStyle(.blue)
                    .font(.subheadline)
                Text(entry.mealType.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            if entry.items.isEmpty {
                Text("cafeteria.no.data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Array(entry.items.prefix(2).enumerated()), id: \.offset) { index, item in
                        if index > 0 {
                            Divider()
                                .padding(.horizontal, 8)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.cafeteriaName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            ForEach(item.foods.prefix(3), id: \.self) { food in
                                Text(food)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            if !item.price.isEmpty {
                                Text("\(item.price)원")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(12)
    }
}

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
                Text(entry.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            if entry.items.isEmpty {
                Spacer()
                Text("cafeteria.no.data")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.items.prefix(6)) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(item.cafeteriaName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                if !item.price.isEmpty {
                                    Text("\(item.price)원")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            if let rt = item.runningTime {
                                Text(rt)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            ForEach(item.foods.prefix(4), id: \.self) { food in
                                Text("· \(food)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Divider()
                    }
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Widget

struct CafeteriaWidget: Widget {
    let kind = "CafeteriaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CafeteriaProvider()) { entry in
            CafeteriaWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("widget.cafeteria.name")
        .description("widget.cafeteria.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    CafeteriaWidget()
} timeline: {
    CafeteriaEntry(
        date: .now,
        mealType: .lunch,
        items: [CafeteriaMenuItem(cafeteriaName: "학생회관", foods: ["된장찌개", "돈까스", "잡채"], price: "3500", runningTime: "11:00~13:30")]
    )
}

#Preview("Medium", as: .systemMedium) {
    CafeteriaWidget()
} timeline: {
    CafeteriaEntry(
        date: .now,
        mealType: .lunch,
        items: [
            CafeteriaMenuItem(cafeteriaName: "학생회관", foods: ["된장찌개", "돈까스", "잡채"], price: "3500", runningTime: "11:00~13:30"),
            CafeteriaMenuItem(cafeteriaName: "생활과학관", foods: ["뼈다귀탕", "볶음밥", "미역국"], price: "5000", runningTime: "11:30~13:30")
        ]
    )
}

#Preview("Large", as: .systemLarge) {
    CafeteriaWidget()
} timeline: {
    CafeteriaEntry(
        date: .now,
        mealType: .lunch,
        items: [
            CafeteriaMenuItem(cafeteriaName: "학생회관", foods: ["된장찌개", "돈까스", "잡채", "계란프라이"], price: "3500", runningTime: "11:00~13:30"),
            CafeteriaMenuItem(cafeteriaName: "생활과학관", foods: ["뼈다귀탕", "볶음밥", "미역국"], price: "5000", runningTime: "11:30~13:30"),
            CafeteriaMenuItem(cafeteriaName: "제1생활관", foods: ["닭갈비", "쌀국수"], price: "4000", runningTime: "11:30~13:00")
        ]
    )
}
