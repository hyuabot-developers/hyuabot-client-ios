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

    static func upcoming(in groups: [ShuttleDestinationGroup], now: Date) -> [ShuttleDeparture] {
        groups.flatMap { upcoming(in: $0, now: now) }.sorted {
            ($0.departure, $0.destination) < ($1.departure, $1.destination)
        }
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
