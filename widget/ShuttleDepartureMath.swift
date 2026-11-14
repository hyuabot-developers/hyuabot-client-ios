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
    /// Route identity (tag + name) for each entry of `times`, so the same bus listed under several groups can be told
    /// apart from different buses leaving at the same minute. Empty when unknown.
    var busIDs: [String] = []
}

struct ShuttleDeparture: Identifiable {
    let id = UUID()
    let destination: String
    let destinationKey: String
    let time: String
    let departure: Foundation.Date
    let minutes: Int
    var busID: String = ""
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
        group.times.enumerated().compactMap { index, time in
            guard let departure = departureDate(for: time, serviceDate: group.serviceDate),
                  let minutes = minutesUntil(departure, now: now)
            else { return nil }
            return ShuttleDeparture(
                destination: group.destination,
                destinationKey: group.destinationKey,
                time: time,
                departure: departure,
                minutes: minutes,
                busID: group.busIDs.indices.contains(index) ? group.busIDs[index] : ""
            )
        }
    }

    static func upcomingByGroup(in groups: [ShuttleDestinationGroup], now: Date) -> [[ShuttleDeparture]] {
        groups.map { group -> [ShuttleDeparture] in
            var seen = Set<Date>()
            return upcoming(in: group, now: now).filter { seen.insert($0.departure).inserted }
        }.filter { !$0.isEmpty }
    }

    /// Circular runs (route tag C) are listed under both 한대앞 and 예술인 at the dormitory and shuttlecock stops.
    /// Outside the per-direction board they are one bus, so relabel them as 순환.
    static func circularLabeled(_ departure: ShuttleDeparture) -> ShuttleDeparture {
        guard departure.busID.hasPrefix("C|"),
              departure.destinationKey == "STATION" || departure.destinationKey == "TERMINAL"
        else { return departure }
        return ShuttleDeparture(
            destination: destinationDisplayName(for: "CIRCULAR"),
            destinationKey: "CIRCULAR",
            time: departure.time,
            departure: departure.departure,
            minutes: departure.minutes,
            busID: departure.busID
        )
    }

    static func upcoming(in groups: [ShuttleDestinationGroup], now: Date) -> [ShuttleDeparture] {
        // The same bus can be listed under several destinations (e.g. circular, or a Jungang run that
        // also stops at 한대앞), so keep one row per bus and departure time, labeled by the first group.
        // Different buses leaving at the same minute (e.g. 한대앞행 and 예술인행) stay separate.
        // Circular buses are relabelled 순환 first, so their 한대앞 and 예술인 copies collapse into one row.
        struct BusKey: Hashable {
            let departure: Date
            let busID: String
        }
        var seen = Set<BusKey>()
        return upcomingByGroup(in: groups, now: now).flatMap { $0 }.map(circularLabeled)
            .filter { seen.insert(BusKey(departure: $0.departure, busID: $0.busID)).inserted }
            .sorted { ($0.departure, $0.destination) < ($1.departure, $1.destination) }
    }

    static func nextPerGroup(in groups: [ShuttleDestinationGroup], now: Date) -> [ShuttleDeparture] {
        // Circular buses form their own 순환 group here, so the same bus is not shown under both 한대앞 and 예술인.
        var nextByLabel: [String: ShuttleDeparture] = [:]
        var labelOrder: [String] = []
        for group in groups {
            for departure in upcoming(in: group, now: now).map(circularLabeled) {
                let label = departure.destinationKey + "|" + departure.destination
                if let current = nextByLabel[label] {
                    if departure.departure < current.departure {
                        nextByLabel[label] = departure
                    }
                } else {
                    nextByLabel[label] = departure
                    labelOrder.append(label)
                }
            }
        }
        return labelOrder.compactMap { nextByLabel[$0] }.sorted { $0.departure < $1.departure }
    }

    /// Upcoming departures per destination label, for lists that are not direction specific.
    /// Circular runs are relabelled 순환 first, so they form one row instead of appearing under 한대앞 and 예술인.
    static func upcomingByLabel(in groups: [ShuttleDestinationGroup], now: Date) -> [[ShuttleDeparture]] {
        var departuresByLabel: [String: [ShuttleDeparture]] = [:]
        var seenByLabel: [String: Set<Date>] = [:]
        var labelOrder: [String] = []
        for group in groups {
            for departure in upcoming(in: group, now: now).map(circularLabeled) {
                let label = departure.destinationKey + "|" + departure.destination
                if departuresByLabel[label] == nil {
                    departuresByLabel[label] = []
                    labelOrder.append(label)
                }
                guard seenByLabel[label, default: []].insert(departure.departure).inserted else { continue }
                departuresByLabel[label, default: []].append(departure)
            }
        }
        return labelOrder.compactMap { label in departuresByLabel[label]?.sorted { $0.departure < $1.departure } }
            .filter { !$0.isEmpty }
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
        var busByTimeByKey: [String: [String: String]] = [:]
        for bucket in destinations {
            for entry in bucket.entries {
                guard let key = groupKey(stopName: stopName, bucket: bucket.key, tag: entry.tag, routeName: entry.name) else { continue }
                busByTimeByKey[key, default: [:]][entry.time] = busByTimeByKey[key]?[entry.time] ?? "\(entry.tag)|\(entry.name)"
            }
        }
        return (groupOrder[stopName] ?? []).compactMap { key in
            let busByTime = busByTimeByKey[key] ?? [:]
            let sortedTimes = busByTime.keys.sorted().prefix(limit)
            let formatted = sortedTimes.map(formatTime)
            guard !formatted.isEmpty else { return nil }
            return ShuttleDestinationGroup(
                destination: destinationDisplayName(for: key),
                times: Array(formatted),
                destinationKey: key,
                serviceDate: serviceDate,
                busIDs: sortedTimes.map { busByTime[$0] ?? "" }
            )
        }
    }
}
