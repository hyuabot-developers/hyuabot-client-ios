//
//  SubwayIntentService.swift
//  hyuabot
//

import Api
import ApolloAPI
import Foundation

struct SubwayArrivalEntry: Equatable, Sendable {
    let stationID: String
    let direction: String
    let minutes: Int
    let terminalName: String
    let isRealtime: Bool
}

enum SubwayIntentLogic {
    static func directionName(for direction: String) -> String {
        switch direction {
        case "up": String(localized: "intent.subway.direction.up")
        case "down": String(localized: "intent.subway.direction.down")
        default: direction
        }
    }

    static func rows(
        lines: [SubwayLineOption],
        direction: SubwayDirectionOption?,
        entries: [SubwayArrivalEntry],
        perDirection: Int
    ) -> [IntentSnippetRow] {
        lines.flatMap { line in
            let lineEntries = entries.filter {
                $0.stationID == line.stationID && (direction == nil || $0.direction == direction?.rawValue)
            }
            var seen = Set<String>()
            let directions = lineEntries.map(\.direction).filter { seen.insert($0).inserted }
            return directions.flatMap { directionValue in
                lineEntries.filter { $0.direction == directionValue }
                    .sorted { $0.minutes < $1.minutes }
                    .prefix(perDirection)
                    .enumerated()
                    .map { index, entry in
                        IntentSnippetRow(
                            id: "\(line.stationID)-\(directionValue)-\(index)",
                            title: "\(line.title) \(directionName(for: directionValue))",
                            detail: "\(String(format: String(localized: "intent.subway.terminal"), entry.terminalName)) · "
                                + IntentText.minutesLater(entry.minutes),
                            badge: entry.isRealtime ? IntentText.realtimeBadge : IntentText.scheduledBadge,
                            isRealtime: entry.isRealtime
                        )
                    }
            }
        }
    }

    static func makeAnswer(
        line: SubwayLineOption?,
        direction: SubwayDirectionOption?,
        entries: [SubwayArrivalEntry]
    ) -> IntentAnswer {
        let lines = line.map { [$0] } ?? SubwayLineOption.allCases
        let stationIDs = Set(lines.map(\.stationID))
        let relevant = entries.filter {
            stationIDs.contains($0.stationID) && (direction == nil || $0.direction == direction?.rawValue)
        }
        let earliest = relevant.min { $0.minutes < $1.minutes }
        let dialog = earliest.map {
            String(
                format: String(localized: "intent.subway.dialog.next"),
                SubwayLineOption(rawValue: $0.stationID)?.title ?? $0.stationID,
                $0.terminalName,
                "\($0.minutes)"
            )
        } ?? String(localized: "intent.subway.dialog.none")
        return IntentAnswer(
            dialog: dialog,
            snippet: IntentSnippetContent(
                title: line?.title ?? String(localized: "intent.subway.title"),
                subtitle: direction?.title,
                rows: rows(lines: lines, direction: direction, entries: entries, perDirection: 2),
                emptyMessage: String(localized: "intent.subway.dialog.none")
            )
        )
    }
}

enum SubwayIntentService {
    @MainActor
    static func answer(
        line: SubwayLineOption?,
        direction: SubwayDirectionOption?,
        now: Foundation.Date
    ) async -> IntentAnswer {
        let calendar = IntentClock.seoulCalendar
        let weekdayValue = calendar.component(.weekday, from: now)
        let weekday = (weekdayValue == 1 || weekdayValue == 7) ? "weekends" : "weekdays"
        let lines = line.map { [$0] } ?? SubwayLineOption.allCases
        let keys = lines.map {
            SubwayStationInput(stationID: $0.stationID, direction: ["up", "down"], weekdays: [weekday], limit: .some(4))
        }
        do {
            let response = try await Network.shared.client.fetch(
                query: SubwayRealtimePageQuery(keys: keys, language: LanguageManager.shared.apiLanguageTag),
                cachePolicy: .networkOnly
            )
            let entries = (response.data?.subway ?? []).flatMap { station in
                station.arrival.flatMap { arrival in
                    arrival.entries.map {
                        SubwayArrivalEntry(
                            stationID: station.stationID,
                            direction: arrival.direction,
                            minutes: $0.minutes,
                            terminalName: $0.terminal.name,
                            isRealtime: $0.isRealtime
                        )
                    }
                }
            }
            return SubwayIntentLogic.makeAnswer(line: line, direction: direction, entries: entries)
        } catch {
            return IntentAnswer.failure(title: line?.title ?? String(localized: "intent.subway.title"))
        }
    }
}
