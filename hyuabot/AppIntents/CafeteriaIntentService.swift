//
//  CafeteriaIntentService.swift
//  hyuabot
//

import Foundation
import Api

struct CafeteriaMenuEntry: Equatable, Sendable {
    let type: String
    let food: String
    let price: String
}

struct CafeteriaMenus: Equatable, Sendable {
    let seq: Int
    let menus: [CafeteriaMenuEntry]
}

enum CafeteriaIntentLogic {
    static func cafeteriaName(seq: Int) -> String {
        switch seq {
        case 1: String(localized: "cafeteria.title.1")
        case 2: String(localized: "cafeteria.title.2")
        case 4: String(localized: "cafeteria.title.4")
        case 6: String(localized: "cafeteria.title.6")
        case 7: String(localized: "cafeteria.title.7")
        case 8: String(localized: "cafeteria.title.8")
        case 11: String(localized: "cafeteria.title.11")
        case 12: String(localized: "cafeteria.title.12")
        case 13: String(localized: "cafeteria.title.13")
        case 14: String(localized: "cafeteria.title.14")
        case 15: String(localized: "cafeteria.title.15")
        default:
            ""
        }
    }

    static func campusID(for restaurant: CafeteriaRestaurantOption?, storedCampusID: Int) -> Int {
        restaurant?.campusID ?? (storedCampusID == 0 ? 2 : storedCampusID)
    }

    static func rows(
        for meal: CafeteriaMealOption,
        restaurant: CafeteriaRestaurantOption?,
        cafeterias: [CafeteriaMenus]
    ) -> [IntentSnippetRow] {
        cafeterias
            .filter { restaurant == nil || $0.seq == restaurant?.seq }
            .sorted { $0.seq < $1.seq }
            .flatMap { cafeteria in
                let name = cafeteriaName(seq: cafeteria.seq)
                return cafeteria.menus
                    .filter { $0.type.contains(meal.menuMarker) }
                    .enumerated()
                    .map { index, menu in
                        let details = menu.food
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                            .joined(separator: ", ")
                        return IntentSnippetRow(
                            id: "\(cafeteria.seq)-\(index)",
                            title: name.isEmpty ? "\(cafeteria.seq)" : name,
                            detail: details,
                            badge: menu.price.isEmpty ? nil : menu.price,
                            isRealtime: false
                        )
                    }
            }
    }

    static func makeAnswer(
        meal: CafeteriaMealOption,
        day: CafeteriaDayOption,
        restaurant: CafeteriaRestaurantOption?,
        cafeterias: [CafeteriaMenus]
    ) -> IntentAnswer {
        let rows = rows(for: meal, restaurant: restaurant, cafeterias: cafeterias)
        let dateTitle = day.title
        let mealTitle = meal.title
        let title = "\(dateTitle) \(mealTitle)"
        let subtitle = restaurant?.title

        guard let first = rows.first else {
            let message: String
            if let restaurant {
                message = String(
                    format: String(localized: "intent.cafeteria.dialog.none.restaurant"),
                    dateTitle,
                    mealTitle,
                    restaurant.title
                )
            } else {
                message = String(format: String(localized: "intent.cafeteria.dialog.none"), dateTitle, mealTitle)
            }
            return IntentAnswer(
                dialog: message,
                snippet: IntentSnippetContent(
                    title: title,
                    subtitle: subtitle,
                    rows: [],
                    emptyMessage: String(localized: "cafeteria.no.data")
                )
            )
        }

        let message = String(
            format: String(localized: "intent.cafeteria.dialog.menu"),
            dateTitle,
            mealTitle,
            first.title,
            first.detail
        )
        return IntentAnswer(
            dialog: message,
            snippet: IntentSnippetContent(
                title: title,
                subtitle: subtitle,
                rows: rows,
                emptyMessage: String(localized: "cafeteria.no.data")
            )
        )
    }
}

enum CafeteriaIntentService {
    @MainActor
    static func answer(
        meal: CafeteriaMealOption?,
        day: CafeteriaDayOption?,
        restaurant: CafeteriaRestaurantOption?,
        now: Foundation.Date
    ) async -> IntentAnswer {
        let calendar = IntentClock.seoulCalendar
        let selectedDay = day ?? .today
        let selectedMeal = meal ?? CafeteriaMealOption.current(at: now, calendar: calendar)
        let queryDate = calendar.date(byAdding: .day, value: selectedDay.dayOffset, to: now) ?? now
        let dateString = IntentClock.dateString(from: queryDate, calendar: calendar)
        let campusID = CafeteriaIntentLogic.campusID(
            for: restaurant,
            storedCampusID: UserDefaults.standard.integer(forKey: "campusID")
        )

        do {
            let response = try await Network.shared.client.fetch(
                query: CafeteriaPageQuery(date: dateString, campusID: Int32(campusID)),
                cachePolicy: .networkOnly
            )
            let fetchedCafeterias: [CafeteriaPageQuery.Data.Cafeterium] = response.data?.cafeteria ?? []
            let cafeterias = fetchedCafeterias.map { cafeteria in
                CafeteriaMenus(
                    seq: cafeteria.seq,
                    menus: cafeteria.menus.map {
                        CafeteriaMenuEntry(type: $0.type, food: $0.food, price: $0.price)
                    }
                )
            }
            return CafeteriaIntentLogic.makeAnswer(
                meal: selectedMeal,
                day: selectedDay,
                restaurant: restaurant,
                cafeterias: cafeterias
            )
        } catch {
            return .failure(title: "\(selectedDay.title) \(selectedMeal.title)")
        }
    }
}
