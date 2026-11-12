//
//  ShuttleDisplayLogic.swift
//  hyuabot
//
import Foundation

enum ShuttleDisplayLogic {
    struct RowTimes: Equatable {
        let trailing: String
        let isSoon: Bool
    }

    static func minutesUntil(_ departure: Date, now: Date) -> Int {
        max(0, Int(departure.timeIntervalSince(now)) / 60)
    }

    static func logArrivalDate(startDeparture: Date, minutesFromStart: Int, now: Date) -> Date? {
        let arrival = startDeparture.addingTimeInterval(TimeInterval(minutesFromStart) * 60)
        return arrival >= now ? arrival : nil
    }

    static func clockText(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    /// The single time value shown on the right of a row: minutes left, or the clock time.
    static func rowTimes(
        departure: Date,
        now: Date,
        showsRemainingTime: Bool,
        calendar: Calendar = .current
    ) -> RowTimes {
        let minutes = minutesUntil(departure, now: now)
        let isSoon = minutes <= 1
        guard showsRemainingTime else {
            return RowTimes(trailing: clockText(departure, calendar: calendar), isSoon: isSoon)
        }
        let remaining = String(format: String(localized: "shuttle.realtime.duration.format.%lld"), minutes)
        return RowTimes(trailing: remaining, isSoon: isSoon)
    }

    static func serviceMinutes(hour: Int, minute: Int) -> Int {
        (hour < 4 ? hour + 24 : hour) * 60 + minute
    }

    private static func timeComponents(_ time: String) -> (hour: Int, minute: Int)? {
        let parts = time.split(separator: ":", omittingEmptySubsequences: false)
        let numbers = parts.compactMap { Int($0) }
        guard parts.count == 2 || parts.count == 3,
              numbers.count == parts.count,
              (0 ... 47).contains(numbers[0]),
              (0 ... 59).contains(numbers[1]),
              numbers.count == 2 || (0 ... 59).contains(numbers[2])
        else { return nil }
        return (numbers[0], numbers[1])
    }

    static func serviceMinutes(time: String) -> Int? {
        guard let components = timeComponents(time) else { return nil }
        return serviceMinutes(hour: components.hour, minute: components.minute)
    }

    static func clock(time: String) -> String? {
        guard let components = timeComponents(time) else { return nil }
        return String(format: "%02d:%02d", components.hour, components.minute)
    }

    static func stopKey(_ stop: ShuttleStopEnum) -> String {
        switch stop {
        case .dormiotryOut: "dormitory_o"
        case .shuttlecockOut: "shuttlecock_o"
        case .station: "station"
        case .terminal: "terminal"
        case .jungangStation: "jungang_stn"
        case .shuttlecockIn: "shuttlecock_i"
        }
    }

    private static func destinations(stopID: String) -> [String] {
        switch stopID {
        case "dormitory_o", "shuttlecock_o": ["STATION", "TERMINAL", "JUNGANG"]
        case "station": ["CAMPUS", "TERMINAL", "JUNGANG"]
        case "terminal", "jungang_stn", "shuttlecock_i": ["CAMPUS"]
        default: []
        }
    }

    static func destinationKey(stopID: String, section: Int) -> String? {
        let sections = destinations(stopID: stopID)
        return sections.indices.contains(section) ? sections[section] : nil
    }

    static func timetableRoute(
        start: String.LocalizationValue,
        end: String.LocalizationValue
    ) -> (stopID: String, destinationKey: String?) {
        let stopID: String
        switch start {
        case "shuttle.stop.dormitory.out": stopID = "dormitory_o"
        case "shuttle.stop.shuttlecock.out": stopID = "shuttlecock_o"
        case "shuttle.stop.station": stopID = "station"
        case "shuttle.stop.terminal": stopID = "terminal"
        case "shuttle.stop.jungang.station": stopID = "jungang_stn"
        case "shuttle.stop.shuttlecock.in": stopID = "shuttlecock_i"
        default: return ("", nil)
        }
        let destination: String
        switch end {
        case "shuttle.destination.shorten.station": destination = "STATION"
        case "shuttle.destination.shorten.terminal": destination = "TERMINAL"
        case "shuttle.destination.shorten.jungang_station": destination = "JUNGANG"
        case "shuttle.destination.shorten.campus": destination = "CAMPUS"
        default: return (stopID, nil)
        }
        guard let section = destinations(stopID: stopID).firstIndex(of: destination) else {
            return (stopID, nil)
        }
        return (stopID, destinationKey(stopID: stopID, section: section))
    }

    struct StopTime: Equatable {
        let stop: String
        let time: String
    }

    struct Arrival: Equatable {
        let stop: String
        let clock: String
    }

    private static func validStops(_ stops: [StopTime]) -> [(entry: StopTime, minutes: Int)] {
        stops.compactMap { entry in
            serviceMinutes(time: entry.time).map { (entry: entry, minutes: $0) }
        }.sorted { $0.minutes < $1.minutes }
    }

    static func arrival(destinationKey: String, boardingTime: String, stops: [StopTime]) -> Arrival? {
        guard let boardingMinutes = serviceMinutes(time: boardingTime) else { return nil }
        let candidates = validStops(stops).filter { $0.minutes > boardingMinutes }
        let match: (entry: StopTime, minutes: Int)? = switch destinationKey {
        case "STATION": candidates.first { $0.entry.stop == "station" }
        case "TERMINAL": candidates.first { $0.entry.stop == "terminal" }
        case "JUNGANG": candidates.first { $0.entry.stop == "jungang_stn" }
        case "CAMPUS": candidates.last
        default: nil
        }
        guard let match, let clock = clock(time: match.entry.time) else { return nil }
        return Arrival(stop: match.entry.stop, clock: clock)
    }

    static func orderArrivals(boardingStopID: String, boardingTime: String, stops: [StopTime]) -> [Arrival] {
        guard let boardingMinutes = serviceMinutes(time: boardingTime) else { return [] }
        let validEntries = validStops(stops)
        var candidates = validEntries.filter {
            $0.minutes > boardingMinutes && ["station", "terminal", "jungang_stn"].contains($0.entry.stop)
        }
        let includesCampus = boardingStopID != "dormitory_o" && boardingStopID != "shuttlecock_o"
        if includesCampus, let last = validEntries.last, last.minutes > boardingMinutes {
            candidates.append(last)
        }
        var seenStops = Set<String>()
        return candidates.sorted { $0.minutes < $1.minutes }.compactMap { candidate in
            guard seenStops.insert(candidate.entry.stop).inserted,
                  let clock = clock(time: candidate.entry.time) else { return nil }
            return Arrival(stop: candidate.entry.stop, clock: clock)
        }
    }

    static func stopShortName(_ stop: String) -> String? {
        switch stop {
        case "station": String(localized: "shuttle.destination.shorten.station")
        case "terminal": String(localized: "shuttle.destination.shorten.terminal")
        case "jungang_stn": String(localized: "shuttle.destination.shorten.jungang_station")
        case "dormitory_o", "dormitory_i": String(localized: "shuttle.destination.shorten.campus")
        case "shuttlecock_o", "shuttlecock_i": String(localized: "shuttle.type.shuttlecock")
        default: nil
        }
    }

    static func destinationRowText(destinationKey: String, boardingTime: String, stops: [StopTime]) -> String? {
        guard let arrival = arrival(destinationKey: destinationKey, boardingTime: boardingTime, stops: stops),
              let name = stopShortName(arrival.stop) else { return nil }
        return String(format: String(localized: "shuttle.realtime.arrives_at_stop.%@.%@"), name, arrival.clock)
    }

    static func orderRowText(boardingStopID: String, boardingTime: String, stops: [StopTime]) -> String? {
        let joined = orderArrivals(boardingStopID: boardingStopID, boardingTime: boardingTime, stops: stops)
            .compactMap { arrival in stopShortName(arrival.stop).map { "\($0) \(arrival.clock)" } }
            .joined(separator: " · ")
        return joined.isEmpty ? nil : String(format: String(localized: "shuttle.realtime.arrives_at.%@"), joined)
    }

    static func timetableArrivalText(destinationKey: String?, boardingTime: String, stops: [StopTime]) -> String? {
        guard let destinationKey,
              let arrival = arrival(destinationKey: destinationKey, boardingTime: boardingTime, stops: stops),
              let name = stopShortName(arrival.stop) else { return nil }
        return "\(name) \(arrival.clock)"
    }

    enum RouteChipKind: Equatable {
        case direct, circular, jungang, terminal, fallback
    }

    static func routeChipKind(stopID: String, destinationKey: String?, routeTag: String) -> RouteChipKind {
        if routeTag == "C" {
            return .circular
        }
        guard let destinationKey else {
            switch routeTag {
            case "DH": return .direct
            case "DY": return .terminal
            case "DJ": return .jungang
            default: return .fallback
            }
        }
        if destinationKey == "JUNGANG" {
            return .jungang
        }
        if destinationKey == "TERMINAL", stopID == "station" {
            return .circular
        }
        if destinationKey == "CAMPUS", routeTag == "DJ" {
            return .jungang
        }
        if ["DH", "DY", "DJ"].contains(routeTag) {
            return .direct
        }
        return .fallback
    }

    enum TimetableRowState: Equatable {
        case past, next, upcoming
    }

    static func timetableStates(departureMinutes: [Int], nowMinutes: Int?) -> [TimetableRowState] {
        guard let nowMinutes else { return Array(repeating: .upcoming, count: departureMinutes.count) }
        var foundNext = false
        return departureMinutes.map { minutes in
            if minutes < nowMinutes {
                return .past
            }
            if !foundNext {
                foundNext = true
                return .next
            }
            return .upcoming
        }
    }

    struct HourSection: Equatable {
        let hour: Int
        let rows: Range<Int>
    }

    static func hourSections(departureMinutes: [Int]) -> [HourSection] {
        guard let firstMinutes = departureMinutes.first else { return [] }
        var sections: [HourSection] = []
        var startIndex = 0
        var hour = (firstMinutes / 60) % 24
        for index in 1 ... departureMinutes.count {
            if index == departureMinutes.count || (departureMinutes[index] / 60) % 24 != hour {
                sections.append(HourSection(hour: hour, rows: startIndex ..< index))
                if index < departureMinutes.count {
                    startIndex = index
                    hour = (departureMinutes[index] / 60) % 24
                }
            }
        }
        return sections
    }

    static func isServiceDayMatch(isWeekdays: Bool, selectedDate: Date?, now: Date, calendar: Calendar) -> Bool {
        if let selectedDate, !calendar.isDate(selectedDate, inSameDayAs: now) {
            return false
        }
        let shifted = calendar.date(byAdding: .hour, value: -4, to: now) ?? now
        let weekday = calendar.component(.weekday, from: shifted)
        let isWeekend = weekday == 1 || weekday == 7
        return isWeekdays ? !isWeekend : isWeekend
    }

    struct TimetableProjection: Equatable {
        // Section belongs to the projection API required by its consumers.
        // swiftlint:disable:next nesting
        struct Section: Equatable {
            let hour: Int
            let itemIndices: [Int]
        }

        let sections: [Section]
        let hiddenPastCount: Int
        let states: [TimetableRowState]
        let scrollTargetItem: Int?

        func itemIndex(at indexPath: IndexPath) -> Int? {
            guard sections.indices.contains(indexPath.section),
                  sections[indexPath.section].itemIndices.indices.contains(indexPath.row) else { return nil }
            return sections[indexPath.section].itemIndices[indexPath.row]
        }

        func indexPath(ofItem item: Int) -> IndexPath? {
            for (sectionIndex, section) in sections.enumerated() {
                if let row = section.itemIndices.firstIndex(of: item) {
                    return IndexPath(row: row, section: sectionIndex)
                }
            }
            return nil
        }
    }

    static func timetableProjection(
        departureMinutes: [Int],
        nowMinutes: Int?,
        scrollNowMinutes: Int,
        showsPastRows: Bool
    ) -> TimetableProjection {
        let states = timetableStates(departureMinutes: departureMinutes, nowMinutes: nowMinutes)
        let pastCount = states.prefix(while: { $0 == .past }).count
        let foldsPastRows = !showsPastRows && pastCount > 0 && pastCount < departureMinutes.count
        let visibleIndices = Array((foldsPastRows ? pastCount : 0) ..< departureMinutes.count)
        let sections = hourSections(departureMinutes: visibleIndices.map { departureMinutes[$0] }).map { section in
            TimetableProjection.Section(hour: section.hour, itemIndices: Array(visibleIndices[section.rows]))
        }
        let nextItem = departureMinutes.firstIndex { $0 > scrollNowMinutes }
        let scrollTarget = nextItem.flatMap { visibleIndices.contains($0) ? $0 : nil } ?? visibleIndices.first
        return TimetableProjection(
            sections: sections,
            hiddenPastCount: foldsPastRows ? pastCount : 0,
            states: states,
            scrollTargetItem: scrollTarget
        )
    }
}

extension ShuttleDisplayLogic {
    struct EmptyText: Equatable {
        let title: String
        let body: String
    }

    static func emptyText(destination: String, departureTimes: [String], isWeekend: Bool) -> EmptyText {
        let firstDeparture = departureTimes.compactMap { time -> (Int, String)? in
            guard let minutes = serviceMinutes(time: time), let clock = clock(time: time) else { return nil }
            return (minutes, clock)
        }.min { $0.0 < $1.0 }
        guard let firstDeparture else {
            return EmptyText(
                title: isWeekend
                    ? String(localized: "shuttle.realtime.empty.weekend.title")
                    : String(localized: "shuttle.realtime.empty.not_operating.title"),
                body: String(localized: "shuttle.realtime.empty.not_operating.body")
            )
        }
        return EmptyText(
            title: String(format: String(localized: "shuttle.realtime.empty.ended.title"), destination),
            body: String(format: String(localized: "shuttle.realtime.empty.ended.body"), firstDeparture.1)
        )
    }
}
