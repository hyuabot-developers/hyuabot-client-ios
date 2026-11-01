//
//  CafeteriaMenuEntity.swift
//  hyuabot
//

import Api
import ApolloAPI
import AppIntents
import CoreSpotlight
import Foundation

struct CafeteriaMenuEntityKey: Hashable, Sendable {
    let date: String
    let seq: Int
    let meal: CafeteriaMealOption
}

struct CafeteriaMenuEntity: AppEntity, Hashable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.cafeteria.type")
    static let defaultQuery = CafeteriaMenuEntityQuery()

    let id: String
    let date: String
    let restaurantSeq: Int
    let restaurantName: String
    let meal: CafeteriaMealOption
    let menuSummary: String

    var name: String { "\(date) \(restaurantName) \(meal.title)" }
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(menuSummary)")
    }
}

@available(iOS 18.0, *)
extension CafeteriaMenuEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.title = name
        attributes.contentDescription = menuSummary
        attributes.keywords = [restaurantName, meal.title, meal.menuMarker, "학식", "식단", "메뉴"]
        return attributes
    }
}

enum CafeteriaMenuEntityLogic {
    static func identifier(for key: CafeteriaMenuEntityKey) -> String {
        "\(key.date)|\(key.seq)|\(key.meal.rawValue)"
    }

    static func key(from identifier: String) -> CafeteriaMenuEntityKey? {
        let parts = identifier.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let seq = Int(parts[1]),
              let meal = CafeteriaMealOption(rawValue: String(parts[2])) else { return nil }
        return CafeteriaMenuEntityKey(date: String(parts[0]), seq: seq, meal: meal)
    }

    static func campusID(forSeq seq: Int) -> Int { seq < 10 ? 1 : 2 }

    static func indexDates(now: Foundation.Date, calendar: Calendar) -> [String] {
        let today = IntentClock.dateString(from: now, calendar: calendar)
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return [today, IntentClock.dateString(from: tomorrowDate, calendar: calendar)]
    }

    static func entities(date: String, cafeterias: [CafeteriaMenus]) -> [CafeteriaMenuEntity] {
        cafeterias.sorted { $0.seq < $1.seq }.flatMap { cafeteria in
            CafeteriaMealOption.allCases.compactMap { meal in
                let rows = CafeteriaIntentLogic.rows(for: meal, restaurant: nil, cafeterias: [cafeteria])
                guard !rows.isEmpty else { return nil }
                let name = CafeteriaIntentLogic.cafeteriaName(seq: cafeteria.seq)
                let key = CafeteriaMenuEntityKey(date: date, seq: cafeteria.seq, meal: meal)
                return CafeteriaMenuEntity(
                    id: identifier(for: key), date: date, restaurantSeq: cafeteria.seq,
                    restaurantName: name.isEmpty ? "\(cafeteria.seq)" : name,
                    meal: meal, menuSummary: rows.map(\.detail).filter { !$0.isEmpty }.joined(separator: " / ")
                )
            }
        }
    }

    static func filter(_ entities: [CafeteriaMenuEntity], matching string: String) -> [CafeteriaMenuEntity] {
        let query = string.filter { !$0.isWhitespace }.lowercased()
        guard !query.isEmpty else { return entities }
        return entities.filter {
            "\($0.name) \($0.menuSummary) \($0.meal.menuMarker)".filter { !$0.isWhitespace }.lowercased().contains(query)
        }
    }

    static func shouldRefresh(lastRefresh: Foundation.Date?, now: Foundation.Date) -> Bool {
        guard let lastRefresh else { return true }
        return now.timeIntervalSince(lastRefresh) >= 1800
    }

    static func snapshot(fetches: [CafeteriaMenuFetch]) -> CafeteriaMenuSnapshot {
        let entities = fetches.flatMap { fetch in
            fetch.menus.map { entities(date: fetch.date, cafeterias: $0) } ?? []
        }
        return CafeteriaMenuSnapshot(entities: entities, isComplete: !fetches.isEmpty && fetches.allSatisfy { $0.menus != nil })
    }

    static func indexAction(for snapshot: CafeteriaMenuSnapshot) -> CafeteriaIndexAction {
        guard snapshot.isComplete else { return .keep }
        return snapshot.entities.isEmpty ? .clear : .replace(snapshot.entities)
    }

    static func validatedMenus(mappedMenus: [CafeteriaMenus]?, graphQLErrorCount: Int) throws -> [CafeteriaMenus] {
        if graphQLErrorCount > 0 { throw CafeteriaMenuFetchError.graphQLErrors }
        guard let mappedMenus else { throw CafeteriaMenuFetchError.missingData }
        return mappedMenus
    }

    static func fetch(date: String, mappedMenus: [CafeteriaMenus]?, graphQLErrorCount: Int) -> CafeteriaMenuFetch {
        CafeteriaMenuFetch(date: date, menus: try? validatedMenus(mappedMenus: mappedMenus, graphQLErrorCount: graphQLErrorCount))
    }
}

struct CafeteriaMenuFetch {
    let date: String
    let menus: [CafeteriaMenus]?
}

struct CafeteriaMenuSnapshot: Equatable, Sendable {
    let entities: [CafeteriaMenuEntity]
    let isComplete: Bool
}

enum CafeteriaIndexAction: Equatable, Sendable {
    case keep
    case clear
    case replace([CafeteriaMenuEntity])
}

enum CafeteriaMenuFetchError: Error, Equatable, Sendable {
    case graphQLErrors
    case missingData
}

enum CafeteriaMenuStore {
    @MainActor
    static func menus(date: String, campusID: Int) async throws -> [CafeteriaMenus] {
        let response = try await Network.shared.client.fetch(
            query: CafeteriaPageQuery(date: date, campusID: Int32(campusID)),
            cachePolicy: .networkOnly
        )
        return try CafeteriaMenuEntityLogic.validatedMenus(
            mappedMenus: response.data.map { data in
                data.cafeteria.map { item in
                    CafeteriaMenus(seq: item.seq, menus: item.menus.map {
                        CafeteriaMenuEntry(type: $0.type, food: $0.food, price: $0.price)
                    })
                }
            },
            graphQLErrorCount: response.errors?.count ?? 0
        )
    }

    @MainActor
    static func snapshot(dates: [String], campusIDs: [Int]) async -> CafeteriaMenuSnapshot {
        var fetches: [CafeteriaMenuFetch] = []
        for date in dates {
            for campusID in campusIDs {
                do {
                    fetches.append(CafeteriaMenuFetch(date: date, menus: try await menus(date: date, campusID: campusID)))
                } catch {
                    fetches.append(CafeteriaMenuFetch(date: date, menus: nil))
                }
            }
        }
        return CafeteriaMenuEntityLogic.snapshot(fetches: fetches)
    }

    @MainActor
    static func entities(dates: [String], campusIDs: [Int]) async -> [CafeteriaMenuEntity] {
        await snapshot(dates: dates, campusIDs: campusIDs).entities
    }
}

struct CafeteriaMenuEntityQuery: EntityStringQuery {
    func entities(for identifiers: [CafeteriaMenuEntity.ID]) async throws -> [CafeteriaMenuEntity] {
        let keys = identifiers.compactMap(CafeteriaMenuEntityLogic.key(from:))
        let dates = keys.reduce(into: [String]()) { result, key in
            if !result.contains(key.date) { result.append(key.date) }
        }
        let campusIDs = keys.reduce(into: [Int]()) { result, key in
            let campusID = CafeteriaMenuEntityLogic.campusID(forSeq: key.seq)
            if !result.contains(campusID) { result.append(campusID) }
        }
        let all = await CafeteriaMenuStore.entities(dates: dates, campusIDs: campusIDs)
        return identifiers.compactMap { id in all.first { $0.id == id } }
    }

    func entities(matching string: String) async throws -> [CafeteriaMenuEntity] {
        let dates = CafeteriaMenuEntityLogic.indexDates(now: .now, calendar: IntentClock.seoulCalendar)
        let snapshot = await CafeteriaMenuStore.snapshot(dates: dates, campusIDs: [1, 2])
        return CafeteriaMenuEntityLogic.filter(snapshot.entities, matching: string)
    }

    func suggestedEntities() async throws -> [CafeteriaMenuEntity] {
        let date = IntentClock.dateString(from: .now, calendar: IntentClock.seoulCalendar)
        let campusID = CafeteriaIntentLogic.campusID(
            for: nil, storedCampusID: UserDefaults.standard.integer(forKey: "campusID")
        )
        return await CafeteriaMenuStore.entities(dates: [date], campusIDs: [campusID])
    }
}

enum CafeteriaMenuIndexer {
    @MainActor private static var lastRefresh: Foundation.Date?

    @MainActor
    static func scheduleRefresh(now: Foundation.Date = .now) {
        guard CafeteriaMenuEntityLogic.shouldRefresh(lastRefresh: lastRefresh, now: now) else { return }
        lastRefresh = now
        Task { await refresh(now: now) }
    }

    @MainActor
    static func refresh(now: Foundation.Date) async {
        guard #available(iOS 18.0, *) else { return }
        let dates = CafeteriaMenuEntityLogic.indexDates(now: now, calendar: IntentClock.seoulCalendar)
        let snapshot = await CafeteriaMenuStore.snapshot(dates: dates, campusIDs: [1, 2])
        do {
            switch CafeteriaMenuEntityLogic.indexAction(for: snapshot) {
            case .keep:
                return
            case .clear:
                try await CSSearchableIndex.default().deleteAppEntities(ofType: CafeteriaMenuEntity.self)
            case .replace(let entities):
                try await CSSearchableIndex.default().deleteAppEntities(ofType: CafeteriaMenuEntity.self)
                try await CSSearchableIndex.default().indexAppEntities(entities)
            }
        } catch {
            return
        }
    }
}
