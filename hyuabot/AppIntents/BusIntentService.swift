//
//  BusIntentService.swift
//  hyuabot
//

import Api
import ApolloAPI
import Foundation

struct BusArrivalEntry: Equatable, Sendable {
    let routeID: Int
    let routeName: String
    let stopID: Int
    let minutes: Int?
    let stops: Int?
    let isRealtime: Bool
    let time: String?
}

enum BusIntentLogic {
    static func rows(entries: [BusArrivalEntry], perRoute: Int) -> [IntentSnippetRow] {
        let usable = entries.filter { $0.minutes != nil || $0.time != nil }
        var keys: [String] = []
        for entry in usable {
            let key = "\(entry.routeID)-\(entry.stopID)"
            if !keys.contains(key) { keys.append(key) }
        }
        return keys.flatMap { key in
            usable.filter { "\($0.routeID)-\($0.stopID)" == key }
                .sorted { ($0.minutes ?? Int.max) < ($1.minutes ?? Int.max) }
                .prefix(perRoute)
                .enumerated()
                .map { index, entry in
                    let stopName = BusStopName.title(for: Int32(clamping: entry.stopID))
                    return IntentSnippetRow(
                        id: "\(key)-\(index)",
                        title: stopName.isEmpty ? entry.routeName : "\(entry.routeName) · \(stopName)",
                        detail: detail(for: entry),
                        badge: entry.isRealtime ? IntentText.realtimeBadge : IntentText.scheduledBadge,
                        isRealtime: entry.isRealtime
                    )
                }
        }
    }

    private static func detail(for entry: BusArrivalEntry) -> String {
        if let minutes = entry.minutes {
            let stops = entry.stops.map { " · " + String(format: String(localized: "intent.bus.stops.left"), "\($0)") } ?? ""
            return IntentText.minutesLater(minutes) + stops
        }
        return String(format: String(localized: "intent.bus.departure.time"), IntentClock.shortTime(entry.time ?? ""))
    }

    static func filter(entries: [BusArrivalEntry], route: BusRouteOption?) -> [BusArrivalEntry] {
        guard let route else { return entries }
        return entries.filter { $0.routeName == route.routeName }
    }

    static func makeAnswer(route: BusRouteOption?, entries: [BusArrivalEntry]) -> IntentAnswer {
        let filtered = filter(entries: entries, route: route)
        let realtime = filtered.filter { $0.minutes != nil }.min { ($0.minutes ?? 0) < ($1.minutes ?? 0) }
        let dialog: String
        if let entry = realtime, let minutes = entry.minutes {
            dialog = String(format: String(localized: "intent.bus.dialog.next"), entry.routeName, "\(minutes)")
        } else if let scheduled = filtered.first(where: { $0.time != nil }), let time = scheduled.time {
            dialog = String(format: String(localized: "intent.bus.dialog.scheduled"), scheduled.routeName, IntentClock.shortTime(time))
        } else {
            dialog = String(localized: "intent.bus.dialog.none")
        }
        return IntentAnswer(dialog: dialog, snippet: IntentSnippetContent(
            title: route?.title ?? String(localized: "intent.bus.title"),
            subtitle: nil,
            rows: rows(entries: filtered, perRoute: 2),
            emptyMessage: String(localized: "intent.bus.dialog.none")
        ))
    }
}

enum BusIntentService {
    @MainActor
    static func answer(route: BusRouteOption?) async -> IntentAnswer {
        let pairs = route?.routeStops ?? BusRouteOption.defaultRouteStops
        let inputs = pairs.map { BusRouteStopInput(route: $0.route, stop: $0.stop, limit: .some(3)) }
        let currentLanguage = Bundle.main.preferredLocalizations.first ?? "ko"
        let language = currentLanguage.starts(with: "ko") ? "KOREAN" : "ENGLISH"
        do {
            let response = try await Network.shared.client.fetch(
                query: BusRealtimePageQuery(language: language, busInput: inputs),
                cachePolicy: .networkOnly
            )
            let entries = (response.data?.bus ?? []).flatMap { bus in
                bus.arrival.map {
                    BusArrivalEntry(
                        routeID: Int(bus.route.seq),
                        routeName: bus.route.name,
                        stopID: Int(bus.stop.seq),
                        minutes: $0.minutes,
                        stops: $0.stops,
                        isRealtime: $0.isRealtime,
                        time: $0.time
                    )
                }
            }
            return BusIntentLogic.makeAnswer(route: route, entries: entries)
        } catch {
            return IntentAnswer.failure(title: route?.title ?? String(localized: "intent.bus.title"))
        }
    }
}
