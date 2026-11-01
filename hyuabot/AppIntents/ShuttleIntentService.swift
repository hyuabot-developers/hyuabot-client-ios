//
//  ShuttleIntentService.swift
//  hyuabot
//

import Api
import ApolloAPI
import CoreLocation
import Foundation

struct ShuttleDestinationTimes: Equatable, Sendable {
    let destination: String
    let times: [String]
}

struct ShuttleStopTimes: Equatable, Sendable {
    let stopID: String
    let destinations: [ShuttleDestinationTimes]
}

struct ShuttleNextDeparture: Equatable, Sendable {
    let stopID: String
    let destination: String
    let time: String
    let minutes: Int
}

enum ShuttleIntentLogic {
    private struct Target { let stop: ShuttleStopOption; let fromLocation: Bool }
    private struct AnswerRows { let rows: [IntentSnippetRow]; let note: String?; let earliest: ShuttleNextDeparture? }
    private struct IndexedDeparture { let minutes: Int; let destinationIndex: Int; let sequence: Int; let departure: ShuttleNextDeparture }

    static let nearbyDistanceMeters: Double = 3_000

    static func stopName(for stopID: String) -> String {
        ShuttleStopOption(rawValue: stopID)?.title ?? stopID
    }

    static func destinationName(for destination: String) -> String {
        switch destination {
        case "STATION": String(localized: "intent.shuttle.destination.station")
        case "TERMINAL": String(localized: "intent.shuttle.destination.terminal")
        case "CAMPUS": String(localized: "intent.shuttle.destination.campus")
        case "JUNGANG": String(localized: "intent.shuttle.destination.jungang")
        default: destination
        }
    }

    static func upcomingDepartures(
        in stop: ShuttleStopTimes,
        direction: ShuttleDirectionOption?,
        now: Foundation.Date,
        calendar: Calendar
    ) -> [ShuttleNextDeparture] {
        let departures = stop.destinations.enumerated().flatMap { destinationIndex, destination in
            destination.times.compactMap { time -> IndexedDeparture? in
                if direction.map({ $0.matches(destination: destination.destination) }) == false { return nil }
                guard let minutes = IntentClock.minutesUntil(time, from: now, calendar: calendar) else { return nil }
                return IndexedDeparture(
                    minutes: minutes,
                    destinationIndex: destinationIndex,
                    sequence: destination.times.firstIndex(of: time) ?? 0,
                    departure: ShuttleNextDeparture(
                        stopID: stop.stopID,
                        destination: destination.destination,
                        time: IntentClock.shortTime(time),
                        minutes: minutes
                    )
                )
            }
        }
        return departures.sorted {
            if $0.minutes != $1.minutes { return $0.minutes < $1.minutes }
            if $0.destinationIndex != $1.destinationIndex { return $0.destinationIndex < $1.destinationIndex }
            return $0.sequence < $1.sequence
        }.map(\.departure)
    }

    static func distance(from: ShuttleGeoCoordinate, to: ShuttleGeoCoordinate) -> Double {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }

    static func nearestStop(to coordinate: ShuttleGeoCoordinate, direction: ShuttleDirectionOption?) -> ShuttleStopOption? {
        var nearest: ShuttleStopOption?
        var nearestDistance = Double.greatestFiniteMagnitude
        for option in ShuttleStopOption.allCases where option != .shuttlecockIn {
            let candidateDistance = distance(from: coordinate, to: option.coordinate)
            guard candidateDistance <= nearbyDistanceMeters, candidateDistance < nearestDistance else { continue }
            nearest = option
            nearestDistance = candidateDistance
        }
        if nearest == .shuttlecock, direction == .toCampus { return .shuttlecockIn }
        return nearest
    }

    static func makeAnswer(
        stop: ShuttleStopOption?,
        direction: ShuttleDirectionOption?,
        location: IntentLocationResult?,
        stops: [ShuttleStopTimes],
        now: Foundation.Date,
        calendar: Calendar
    ) -> IntentAnswer {
        let target = resolvedTarget(stop: stop, direction: direction, location: location)
        let rows: [IntentSnippetRow]
        let snippetTitle: String
        let note: String?
        let earliest: ShuttleNextDeparture?
        if let target {
            let result = singleStopResult(
                target: target.stop,
                fromLocation: target.fromLocation,
                direction: direction,
                stops: stops,
                now: now,
                calendar: calendar
            )
            rows = result.rows
            snippetTitle = target.stop.title
            note = result.note
            earliest = result.earliest
        } else {
            let result = overviewResult(
                direction: direction,
                location: location,
                stops: stops,
                now: now,
                calendar: calendar
            )
            rows = result.rows
            snippetTitle = String(localized: "intent.shuttle.snippet.title.all")
            note = result.note
            earliest = result.earliest
        }
        let subtitleParts = [direction?.title, note].compactMap { $0 }
        let subtitle = subtitleParts.isEmpty ? nil : subtitleParts.joined(separator: " · ")
        let dialog = dialog(for: earliest)
        return IntentAnswer(
            dialog: dialog,
            snippet: IntentSnippetContent(
                title: snippetTitle,
                subtitle: subtitle,
                rows: rows,
                emptyMessage: String(localized: "intent.shuttle.dialog.none")
            )
        )
    }

    private static func resolvedTarget(
        stop: ShuttleStopOption?,
        direction: ShuttleDirectionOption?,
        location: IntentLocationResult?
    ) -> Target? {
        if let stop { return Target(stop: stop, fromLocation: false) }
        if case .coordinate(let coordinate)? = location, let nearest = nearestStop(to: coordinate, direction: direction) {
            return Target(stop: nearest, fromLocation: true)
        }
        return nil
    }

    private static func singleStopResult(
        target: ShuttleStopOption,
        fromLocation: Bool,
        direction: ShuttleDirectionOption?,
        stops: [ShuttleStopTimes],
        now: Foundation.Date,
        calendar: Calendar
    ) -> AnswerRows {
        guard let data = stops.first(where: { $0.stopID == target.rawValue }) else {
            return AnswerRows(rows: [], note: fromLocation ? String(localized: "intent.shuttle.nearest") : nil, earliest: nil)
        }
        let departures = upcomingDepartures(in: data, direction: direction, now: now, calendar: calendar)
        let rows = data.destinations.compactMap { destination -> IntentSnippetRow? in
            let times = departures.filter { $0.destination == destination.destination }.map(\.time)
            guard let first = departures.first(where: { $0.destination == destination.destination }) else { return nil }
            return IntentSnippetRow(
                id: "\(target.rawValue)-\(destination.destination)",
                title: destinationName(for: destination.destination),
                detail: "\(IntentText.minutesLater(first.minutes)) · \(times.prefix(3).joined(separator: ", "))",
                badge: nil,
                isRealtime: false
            )
        }
        return AnswerRows(
            rows: rows,
            note: fromLocation ? String(localized: "intent.shuttle.nearest") : nil,
            earliest: departures.first
        )
    }

    private static func overviewResult(
        direction: ShuttleDirectionOption?,
        location: IntentLocationResult?,
        stops: [ShuttleStopTimes],
        now: Foundation.Date,
        calendar: Calendar
    ) -> AnswerRows {
        var rows: [IntentSnippetRow] = []
        var earliest: ShuttleNextDeparture?
        for option in ShuttleStopOption.allCases {
            guard let data = stops.first(where: { $0.stopID == option.rawValue }),
                  let departure = upcomingDepartures(
                    in: data,
                    direction: direction,
                    now: now,
                    calendar: calendar
                  ).first else { continue }
            rows.append(IntentSnippetRow(
                id: option.rawValue,
                title: option.title,
                detail: "\(destinationName(for: departure.destination)) · \(IntentText.minutesLater(departure.minutes))"
                    + " · \(departure.time)",
                badge: nil,
                isRealtime: false
            ))
            if earliest == nil || departure.minutes < (earliest?.minutes ?? Int.max) { earliest = departure }
        }
        return AnswerRows(rows: rows, note: locationNote(location), earliest: earliest)
    }

    private static func locationNote(_ location: IntentLocationResult?) -> String? {
        switch location {
        case nil: nil
        case .notAuthorized: String(localized: "intent.shuttle.location.hint")
        case .unavailable: String(localized: "intent.shuttle.location.unavailable")
        case .coordinate: String(localized: "intent.shuttle.location.far")
        }
    }

    private static func dialog(for departure: ShuttleNextDeparture?) -> String {
        guard let departure else { return String(localized: "intent.shuttle.dialog.none") }
        return String(
            format: String(localized: "intent.shuttle.dialog.next"),
            stopName(for: departure.stopID),
            destinationName(for: departure.destination),
            "\(departure.minutes)",
            departure.time
        )
    }
}

enum ShuttleIntentService {
    @MainActor
    private static func locationIfNeeded(for stop: ShuttleStopOption?) async -> IntentLocationResult? {
        guard stop == nil else { return nil }
        return await IntentLocationProvider.currentLocation()
    }

    @MainActor
    static func answer(for stop: ShuttleStopOption?, direction: ShuttleDirectionOption?, now: Foundation.Date) async -> IntentAnswer {
        let calendar = IntentClock.seoulCalendar
        let after = IntentClock.timeString(from: now, calendar: calendar)
        async let location = locationIfNeeded(for: stop)
        do {
            let response = try await Network.shared.client.fetch(
                query: ShuttleWidgetQuery(after: .some(after)),
                cachePolicy: .networkOnly
            )
            let stops = (response.data?.shuttle.stops ?? []).map { stopData in
                ShuttleStopTimes(
                    stopID: stopData.name,
                    destinations: stopData.timetable.destination.map { destination in
                        ShuttleDestinationTimes(destination: destination.destination, times: destination.entries.map(\.time))
                    }
                )
            }
            let resolvedLocation = await location
            return ShuttleIntentLogic.makeAnswer(
                stop: stop,
                direction: direction,
                location: resolvedLocation,
                stops: stops,
                now: now,
                calendar: calendar
            )
        } catch {
            return IntentAnswer.failure(title: stop?.title ?? String(localized: "intent.shuttle.title"))
        }
    }
}
