//
//  ShuttleDepartureMath.swift
//  hyuabot
//

import Foundation

struct ShuttleDestinationGroup: Identifiable {
    let id = UUID()
    let destination: String
    let times: [String]
    let destinationKey: String
    let serviceDate: Foundation.Date
}

struct ShuttleDeparture: Identifiable {
    let id = UUID()
    let destination: String
    let destinationKey: String
    let time: String
    let departure: Foundation.Date
    let minutes: Int
}

enum ShuttleSampleData {
    /// 2026-03-03 14:00 Asia/Seoul.
    static let referenceDate = Date(timeIntervalSince1970: 1_772_514_000)
}

enum ShuttleDepartureMath {
    static func departureDate(for time: String, serviceDate: Date) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]), (0 ... 23).contains(hour),
              (0 ... 59).contains(minute)
        else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: serviceDate)
    }

    static func minutesUntil(_ departure: Date, now: Date) -> Int? {
        let interval = departure.timeIntervalSince(now)
        guard interval >= 0 else { return nil }
        return Int((interval / 60).rounded(.up))
    }

    static func upcoming(in group: ShuttleDestinationGroup, now: Date) -> [ShuttleDeparture] {
        group.times.compactMap { time in
            guard let departure = departureDate(for: time, serviceDate: group.serviceDate),
                  let minutes = minutesUntil(departure, now: now)
            else { return nil }
            return ShuttleDeparture(
                destination: group.destination,
                destinationKey: group.destinationKey,
                time: time,
                departure: departure,
                minutes: minutes
            )
        }
    }

    static func upcomingByGroup(in groups: [ShuttleDestinationGroup], now: Date) -> [[ShuttleDeparture]] {
        groups.map { group -> [ShuttleDeparture] in
            var seen = Set<Date>()
            return upcoming(in: group, now: now).filter { seen.insert($0.departure).inserted }
        }.filter { !$0.isEmpty }
    }

    static func upcoming(in groups: [ShuttleDestinationGroup], now: Date) -> [ShuttleDeparture] {
        // The same bus can be listed under several destinations (e.g. circular, or a Jungang run that
        // also stops at 한대앞), so keep one row per departure time, labeled by the first group.
        var seen = Set<Date>()
        return upcomingByGroup(in: groups, now: now).flatMap { $0 }
            .filter { seen.insert($0.departure).inserted }
            .sorted { ($0.departure, $0.destination) < ($1.departure, $1.destination) }
    }

    static func nextPerGroup(in groups: [ShuttleDestinationGroup], now: Date) -> [ShuttleDeparture] {
        groups.compactMap { upcoming(in: $0, now: now).first }.sorted { $0.departure < $1.departure }
    }

    static func transferHasContent(groups: [ShuttleDestinationGroup], transitArrivalCount: Int, now: Date) -> Bool {
        !upcoming(in: groups, now: now).isEmpty || transitArrivalCount > 0
    }

    static func minuteTimelineDates(from start: Date, count: Int) -> [Date] {
        guard count > 0 else { return [] }
        let first = Calendar.current.dateInterval(of: .minute, for: start)?.end ?? start.addingTimeInterval(60)
        return [start] + (1 ..< count).map { first.addingTimeInterval(TimeInterval(($0 - 1) * 60)) }
    }
}

extension ShuttleDepartureMath {
    struct ShuttleEntryInput {
        let tag: String
        let name: String
        let time: String
    }

    /// Display order of the destination groups for each stop, mirroring the app's destination sections.
    private static let groupOrder: [String: [String]] = [
        "dormitory_o": ["STATION", "TERMINAL", "JUNGANG"],
        "shuttlecock_o": ["STATION", "TERMINAL", "JUNGANG"],
        "station": ["DORMITORY", "SHUTTLECOCK", "CIRCULAR", "JUNGANG"],
        "terminal": ["DORMITORY", "SHUTTLECOCK"],
        "jungang_stn": ["DORMITORY"],
        "shuttlecock_i": ["DORMITORY"]
    ]

    /// Maps one server entry to the widget destination key shown for the stop, or nil to skip it.
    /// Uses the same tag and route-name suffix rules as the app's shuttle screen.
    static func groupKey(stopName: String, bucket: String, tag: String, routeName: String) -> String? {
        let isShuttlecockSide = routeName.hasSuffix("S")
        switch stopName {
        case "dormitory_o", "shuttlecock_o":
            return bucket
        case "station":
            switch bucket {
            case "CAMPUS":
                switch tag {
                case "C": return "CIRCULAR"
                case "DJ": return "JUNGANG"
                default: return isShuttlecockSide ? "SHUTTLECOCK" : "DORMITORY"
                }
            case "TERMINAL": return "CIRCULAR"
            case "JUNGANG": return "JUNGANG"
            default: return nil
            }
        case "terminal":
            return isShuttlecockSide ? "SHUTTLECOCK" : "DORMITORY"
        case "jungang_stn":
            return "DORMITORY"
        case "shuttlecock_i":
            // Shuttlecock-side runs end at this stop, so only dormitory-bound runs are departures.
            return isShuttlecockSide ? nil : "DORMITORY"
        default:
            return nil
        }
    }

    static func makeGroups(
        stopName: String,
        destinations: [(key: String, entries: [ShuttleEntryInput])],
        limit: Int,
        serviceDate: Date
    ) -> [ShuttleDestinationGroup] {
        var timesByKey: [String: Set<String>] = [:]
        for bucket in destinations {
            for entry in bucket.entries {
                guard let key = groupKey(stopName: stopName, bucket: bucket.key, tag: entry.tag, routeName: entry.name) else { continue }
                timesByKey[key, default: []].insert(entry.time)
            }
        }
        return (groupOrder[stopName] ?? []).compactMap { key in
            let formatted = (timesByKey[key] ?? []).sorted().prefix(limit).map(formatTime)
            guard !formatted.isEmpty else { return nil }
            return ShuttleDestinationGroup(
                destination: destinationDisplayName(for: key),
                times: Array(formatted),
                destinationKey: key,
                serviceDate: serviceDate
            )
        }
    }
}
