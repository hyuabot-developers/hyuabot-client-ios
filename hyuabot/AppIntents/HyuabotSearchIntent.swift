//
//  HyuabotSearchIntent.swift
//  hyuabot
//

import AppIntents
import Foundation
import UIKit

enum HyuabotSearchRequest: Equatable, Sendable {
    case shuttle(stop: ShuttleStopOption?)
    case cafeteria(day: CafeteriaDayOption?, meal: CafeteriaMealOption?, restaurant: CafeteriaRestaurantOption?)
    case subway(line: SubwayLineOption?)
    case bus(route: BusRouteOption?)
}

enum HyuabotSearchLogic {
    static func tomorrowDate(from date: Foundation.Date) -> Foundation.Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    static func url(for request: HyuabotSearchRequest?) -> URL {
        var components = URLComponents()
        components.scheme = "hyuabot"

        switch request {
        case .shuttle(let stop):
            components.host = "shuttle"
            if let stop {
                components.queryItems = [URLQueryItem(name: "stop", value: stop.rawValue)]
            }
        case let .cafeteria(day, meal, _):
            components.host = "cafeteria"
            // Line and restaurant are not representable in the existing deep links.
            if let meal {
                components.queryItems = [URLQueryItem(name: "tab", value: meal.rawValue)]
                if day == .tomorrow {
                    components.queryItems?.append(URLQueryItem(name: "date", value: "tomorrow"))
                }
            }
        case .subway:
            components.host = "subway"
        case .bus:
            components.host = "bus"
        case nil:
            components.host = "shuttle"
        }

        return components.url ?? URL(fileURLWithPath: "/")
    }

    static func request(for term: String) -> HyuabotSearchRequest? {
        let loweredTerm = term.lowercased()
        let route = BusRouteOption.allCases.sorted { $0.rawValue.count > $1.rawValue.count }
            .first { loweredTerm.contains($0.rawValue.lowercased()) }
        if let route { return .bus(route: route) }
        let stop = matchedStop(in: loweredTerm)
        let restaurant = matchedRestaurant(in: loweredTerm)
        let line = matchedLine(in: loweredTerm)
        if containsAny(["셔틀", "shuttle", "シャトル", "班车", "校车"], in: loweredTerm) { return .shuttle(stop: stop) }
        if containsAny(["지하철", "전철", "4호선", "수인분당", "subway", "metro", "地下鉄", "地铁"], in: loweredTerm) {
            return .subway(line: line)
        }
        if containsAny(["버스", "bus", "バス", "公交", "巴士"], in: loweredTerm) { return .bus(route: nil) }
        let cafeteriaTerms = [
            "학식", "식당", "식단", "메뉴", "조식", "중식", "석식", "아침", "점심", "저녁",
            "cafeteria", "menu", "meal", "breakfast", "lunch", "dinner", "学食", "食堂", "菜单", "メニュー"
        ]
        if containsAny(cafeteriaTerms, in: loweredTerm) || restaurant != nil {
            return .cafeteria(
                day: matchedDay(in: loweredTerm),
                meal: matchedMeal(in: loweredTerm),
                restaurant: restaurant
            )
        }
        if let stop { return .shuttle(stop: stop) }
        if let line { return .subway(line: line) }
        return nil
    }

    private static func matchedStop(in term: String) -> ShuttleStopOption? {
        ShuttleStopOption.allCases
            .filter { !$0.title.isEmpty && term.contains($0.title.lowercased()) }
            .max { $0.title.count < $1.title.count }
    }

    private static func matchedRestaurant(in term: String) -> CafeteriaRestaurantOption? {
        CafeteriaRestaurantOption.allCases
            .filter { !$0.title.isEmpty && term.contains($0.title.lowercased()) }
            .max { $0.title.count < $1.title.count }
    }

    private static func matchedLine(in term: String) -> SubwayLineOption? {
        if containsAny(["4호선", "line 4", "line4", "4号线"], in: term) { return .line4 }
        if containsAny(["수인분당", "suin", "bundang"], in: term) { return .suinBundang }
        return nil
    }

    private static func matchedDay(in term: String) -> CafeteriaDayOption? {
        if containsAny(["내일", "tomorrow", "明日", "明天"], in: term) { return .tomorrow }
        if containsAny(["오늘", "today", "今日", "今天"], in: term) { return .today }
        return nil
    }

    private static func matchedMeal(in term: String) -> CafeteriaMealOption? {
        if containsAny(["조식", "아침", "breakfast", "朝食", "早餐"], in: term) { return .breakfast }
        if containsAny(["중식", "점심", "lunch", "昼食", "午餐"], in: term) { return .lunch }
        if containsAny(["석식", "저녁", "dinner", "夕食", "晚餐"], in: term) { return .dinner }
        return nil
    }

    private static func containsAny(_ options: [String], in term: String) -> Bool {
        options.contains { term.contains($0) }
    }
}

@available(iOS 27.0, *)
@AppIntent(schema: .system.searchInApp)
struct HyuabotSearchIntent: ShowInAppSearchResultsIntent {
    static let searchScopes: [StringSearchScope] = [.general]
    var criteria: StringSearchCriteria

    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(HyuabotSearchLogic.url(for: HyuabotSearchLogic.request(for: criteria.term)))
        return .result()
    }
}
