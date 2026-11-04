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
        upcomingByGroup(in: groups, now: now).flatMap { $0 }
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
    /// Route tag -> destination key for the stops where one shuttle is listed under several
    /// destinations (campus-bound stops). The time-ordered `order` list the app uses lists each
    /// physical shuttle once, so grouping it by route tag avoids duplicates (e.g. 한대앞 via 중앙역).
    private static let orderedStops: Set<String> = ["dormitory_o", "shuttlecock_o"]
    private static let routeDestinationKey = ["DH": "STATION", "DY": "TERMINAL", "DJ": "JUNGANG", "C": "CAMPUS"]

    static func makeGroups(
        stopName: String,
        order: [(tag: String, time: String)],
        destinations: [(key: String, times: [String])],
        limit: Int,
        serviceDate: Date
    ) -> [ShuttleDestinationGroup] {
        func group(_ key: String, _ times: [String]) -> ShuttleDestinationGroup? {
            let formatted = times.prefix(limit).map(formatTime)
            guard !formatted.isEmpty else { return nil }
            return ShuttleDestinationGroup(
                destination: destinationDisplayName(for: key),
                times: Array(formatted),
                destinationKey: key,
                serviceDate: serviceDate
            )
        }
        guard orderedStops.contains(stopName), !order.isEmpty else {
            return destinations.compactMap { group($0.key, $0.times) }
        }
        let keys = ["STATION", "TERMINAL", "JUNGANG", "CAMPUS"]
        let byKey = Dictionary(grouping: order.compactMap { item in routeDestinationKey[item.tag].map { ($0, item.time) } }, by: \.0)
        return keys.compactMap { key in group(key, (byKey[key] ?? []).map(\.1)) }
    }
}
