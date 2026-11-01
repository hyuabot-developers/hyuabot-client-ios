//
//  TransitArrivalEntities.swift
//  hyuabot
//

import AppIntents
import Foundation

enum TransitEntityMatcher {
    static func normalized(_ value: String) -> String {
        value.lowercased().filter { !$0.isWhitespace && !$0.isNewline }
    }

    static func matches(_ query: String, candidates: [String]) -> Bool {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return true }
        return candidates.contains { normalized($0).contains(normalizedQuery) || normalizedQuery.contains(normalized($0)) }
    }
}

enum TransitEntityLoader {
    static func load<Option: Sendable, Entity: Sendable>(
        _ options: [Option],
        make: @escaping @Sendable (Option) async -> Entity
    ) async -> [Entity] {
        await withTaskGroup(of: (Int, Entity).self) { group in
            for (index, option) in options.enumerated() {
                group.addTask { (index, await make(option)) }
            }
            var results: [(Int, Entity)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }
}

struct ShuttleArrivalEntity: AppEntity, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String

    init(stop: ShuttleStopOption, answer: IntentAnswer) {
        id = stop.rawValue
        name = stop.title
        summary = answer.dialog
    }

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.shuttle.type")
    static let defaultQuery = ShuttleArrivalEntityQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)", subtitle: "\(summary)") }
}

struct ShuttleArrivalEntityQuery: EntityStringQuery {
    static func stops(matching string: String) -> [ShuttleStopOption] {
        ShuttleStopOption.allCases.filter { TransitEntityMatcher.matches(string, candidates: [$0.title, $0.rawValue]) }
    }

    nonisolated func entities(for identifiers: [String]) async throws -> [ShuttleArrivalEntity] {
        await TransitEntityLoader.load(ShuttleStopOption.allCases.filter { identifiers.contains($0.rawValue) }) { stop in
            let answer = await ShuttleIntentService.answer(for: stop, direction: nil, now: Date())
            return ShuttleArrivalEntity(stop: stop, answer: answer)
        }
    }

    nonisolated func entities(matching string: String) async throws -> [ShuttleArrivalEntity] {
        await TransitEntityLoader.load(Self.stops(matching: string)) { stop in
            let answer = await ShuttleIntentService.answer(for: stop, direction: nil, now: Date())
            return ShuttleArrivalEntity(stop: stop, answer: answer)
        }
    }

    nonisolated func suggestedEntities() async throws -> [ShuttleArrivalEntity] {
        try await entities(for: ShuttleStopOption.allCases.map(\.rawValue))
    }
}

struct SubwayArrivalEntity: AppEntity, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String

    init(line: SubwayLineOption, answer: IntentAnswer) {
        id = line.stationID
        name = line.title
        summary = answer.dialog
    }

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.subway.type")
    static let defaultQuery = SubwayArrivalEntityQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)", subtitle: "\(summary)") }
}

struct SubwayArrivalEntityQuery: EntityStringQuery {
    static func lines(matching string: String) -> [SubwayLineOption] {
        SubwayLineOption.allCases.filter { TransitEntityMatcher.matches(string, candidates: [$0.title, $0.rawValue]) }
    }

    nonisolated func entities(for identifiers: [String]) async throws -> [SubwayArrivalEntity] {
        await TransitEntityLoader.load(SubwayLineOption.allCases.filter { identifiers.contains($0.stationID) }) { line in
            let answer = await SubwayIntentService.answer(line: line, direction: nil, now: Date())
            return SubwayArrivalEntity(line: line, answer: answer)
        }
    }

    nonisolated func entities(matching string: String) async throws -> [SubwayArrivalEntity] {
        await TransitEntityLoader.load(Self.lines(matching: string)) { line in
            let answer = await SubwayIntentService.answer(line: line, direction: nil, now: Date())
            return SubwayArrivalEntity(line: line, answer: answer)
        }
    }

    nonisolated func suggestedEntities() async throws -> [SubwayArrivalEntity] {
        try await entities(for: SubwayLineOption.allCases.map(\.stationID))
    }
}

struct BusArrivalEntity: AppEntity, Hashable, Sendable {
    let id: String
    let name: String
    let summary: String

    init(route: BusRouteOption, answer: IntentAnswer) {
        id = route.rawValue
        name = route.title
        summary = answer.dialog
    }

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.entity.bus.type")
    static let defaultQuery = BusArrivalEntityQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)", subtitle: "\(summary)") }
}

struct BusArrivalEntityQuery: EntityStringQuery {
    static func routes(matching string: String) -> [BusRouteOption] {
        BusRouteOption.allCases.filter { TransitEntityMatcher.matches(string, candidates: [$0.title, $0.rawValue]) }
    }

    nonisolated func entities(for identifiers: [String]) async throws -> [BusArrivalEntity] {
        await TransitEntityLoader.load(BusRouteOption.allCases.filter { identifiers.contains($0.rawValue) }) { route in
            let answer = await BusIntentService.answer(route: route)
            return BusArrivalEntity(route: route, answer: answer)
        }
    }

    nonisolated func entities(matching string: String) async throws -> [BusArrivalEntity] {
        await TransitEntityLoader.load(Self.routes(matching: string)) { route in
            let answer = await BusIntentService.answer(route: route)
            return BusArrivalEntity(route: route, answer: answer)
        }
    }

    nonisolated func suggestedEntities() async throws -> [BusArrivalEntity] {
        try await entities(for: BusRouteOption.allCases.map(\.rawValue))
    }
}
