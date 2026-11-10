//
//  BusDisplayLogic.swift
//  hyuabot
//
import UIKit

struct BusArrivalRowInput: Equatable {
    let route: String
    let isRealtime: Bool
    let stops: Int?
    let seats: Int?
    let realtimeMinutes: Int?
    let scheduledMinutes: Int?
    let isLowFloor: Bool
    let destinationArrival: String?
    var destinationName: String?
}

struct BusArrivalRowModel: Equatable {
    enum Primary: Equatable { case stopsBefore(Int), waitingAtOrigin }
    enum Remaining: Equatable { case soon, minutes(Int) }
    enum Seats: Equatable { case unknown, available(Int), full }

    let route: String
    let isRealtime: Bool
    let primary: Primary
    let remaining: Remaining
    let seats: Seats
    let isLowFloor: Bool
    let destinationArrival: String?
    var destinationName: String?
}

enum BusTimetableDay: Equatable { case weekdays, saturday, sunday, weekends }

struct BusTimetableEntry: Equatable {
    let route: String
    let minutes: Int
    let isFirst: Bool
    let isLast: Bool
    var timeText: String { String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60) }
}

struct BusTimetableRowModel: Equatable {
    enum State: Equatable { case past, next(minutesUntil: Int), upcoming }
    let entry: BusTimetableEntry
    let state: State
}

struct BusTimetableHourGroup: Equatable {
    let hour: Int
    let rows: [BusTimetableRowModel]
}

struct BusTimetableLayout: Equatable {
    let groups: [BusTimetableHourGroup]
    let hiddenPastCount: Int
}

enum BusDisplayLogic {
    static let serviceCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar
    }()

    static func routeColor(_ route: String) -> UIColor {
        ["10-1", "50"].contains(route) ? .busGreen : .busRed
    }

    static func arrivalRow(_ input: BusArrivalRowInput) -> BusArrivalRowModel? {
        let primary: BusArrivalRowModel.Primary
        let remaining: BusArrivalRowModel.Remaining
        let seats: BusArrivalRowModel.Seats
        let isRealtime: Bool
        if let scheduled = input.scheduledMinutes {
            primary = .waitingAtOrigin
            remaining = .minutes(max(0, scheduled))
            seats = .unknown
            isRealtime = false
        } else if input.isRealtime, let stops = input.stops, let seatCount = input.seats,
                  let minutes = input.realtimeMinutes {
            primary = .stopsBefore(stops)
            remaining = (stops <= 1 || minutes <= 1) ? .soon : .minutes(minutes)
            seats = seatCount < 0 ? .unknown : seatCount == 0 ? .full : .available(seatCount)
            isRealtime = input.isRealtime
        } else {
            return nil
        }
        return BusArrivalRowModel(route: input.route, isRealtime: isRealtime, primary: primary,
                                  remaining: remaining, seats: seats, isLowFloor: input.isLowFloor,
                                  destinationArrival: input.destinationArrival, destinationName: input.destinationName)
    }

    static func remainingText(_ remaining: BusArrivalRowModel.Remaining) -> String {
        switch remaining {
        case .soon: String(localized: "bus.realtime.arriving_soon")
        case let .minutes(minutes): String(format: String(localized: "bus.realtime.minutes.%lld"), minutes)
        }
    }

    static func destinationETA(_ model: BusArrivalRowModel) -> String? {
        guard let arrival = model.destinationArrival else { return nil }
        guard let destination = model.destinationName, !destination.isEmpty else { return nil }
        return String(format: String(localized: "bus.realtime.eta.%@.%@"), destination, arrival)
    }

    static func serviceMinutes(of date: Foundation.Date, calendar: Calendar = serviceCalendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        return hour * 60 + (components.minute ?? 0) + (hour < 4 ? 1440 : 0)
    }

    static func dayTabs(items: [BusTimetableItem], calendar: Calendar = serviceCalendar) -> [BusTimetableDay] {
        guard !items.isEmpty else { return [.weekdays, .saturday, .sunday] }
        let routes = Set(items.map(\.route))
        let merged = routes.allSatisfy { route in
            let routeItems = items.filter { $0.route == route }
            let weekdays = routeItems.filter { $0.weekdays == "weekdays" }.map { serviceMinutes(of: $0.time, calendar: calendar) }.sorted()
            let saturday = routeItems.filter { $0.weekdays == "saturday" }.map { serviceMinutes(of: $0.time, calendar: calendar) }.sorted()
            let sunday = routeItems.filter { $0.weekdays == "sunday" }.map { serviceMinutes(of: $0.time, calendar: calendar) }.sorted()
            return weekdays == saturday && saturday == sunday
        }
        return merged ? [.weekdays, .weekends] : [.weekdays, .saturday, .sunday]
    }

    static func today(date: Foundation.Date, tabs: [BusTimetableDay], calendar: Calendar = serviceCalendar) -> BusTimetableDay {
        let serviceDate = calendar.component(.hour, from: date) < 4
            ? (calendar.date(byAdding: .day, value: -1, to: date) ?? date) : date
        switch calendar.component(.weekday, from: serviceDate) {
        case 7: return tabs.contains(.weekends) ? .weekends : .saturday
        case 1: return tabs.contains(.weekends) ? .weekends : .sunday
        default: return .weekdays
        }
    }

    static func entries(items: [BusTimetableItem], day: BusTimetableDay, routeFilter: String?, calendar: Calendar = serviceCalendar) -> [BusTimetableEntry] {
        let source: String
        switch day {
        case .weekdays: source = "weekdays"
        case .saturday, .weekends: source = "saturday"
        case .sunday: source = "sunday"
        }
        let selected = items.filter { $0.weekdays == source && (routeFilter == nil || $0.route == routeFilter) }
        let values = selected.map { ($0, serviceMinutes(of: $0.time, calendar: calendar)) }
        return values.map { item, minute in
            let routeValues = values.filter { $0.0.route == item.route }.map(\.1)
            return BusTimetableEntry(
                route: item.route,
                minutes: minute,
                isFirst: minute == routeValues.min(),
                isLast: minute == routeValues.max()
            )
        }.sorted { $0.minutes == $1.minutes ? $0.route < $1.route : $0.minutes < $1.minutes }
    }

    static func layout(entries: [BusTimetableEntry], isToday: Bool, nowMinutes: Int, expanded: Bool) -> BusTimetableLayout {
        let nextIndex = isToday ? entries.firstIndex { $0.minutes >= nowMinutes } : nil
        let hidden = isToday && !expanded ? max(0, (nextIndex ?? entries.count) - 1) : 0
        var groups: [BusTimetableHourGroup] = []
        for index in hidden..<entries.count {
            let entry = entries[index]
            let state: BusTimetableRowModel.State
            if index == nextIndex {
                state = .next(minutesUntil: entry.minutes - nowMinutes)
            } else if isToday && entry.minutes < nowMinutes {
                state = .past
            } else {
                state = .upcoming
            }
            let row = BusTimetableRowModel(entry: entry, state: state)
            let hour = entry.minutes / 60
            if groups.last?.hour == hour {
                let last = groups.removeLast()
                groups.append(BusTimetableHourGroup(hour: hour, rows: last.rows + [row]))
            } else { groups.append(BusTimetableHourGroup(hour: hour, rows: [row])) }
        }
        return BusTimetableLayout(groups: groups, hiddenPastCount: hidden)
    }
}

extension BusArrivalItem {
    func rowModel(showSecondary: Bool, now: Foundation.Date = Foundation.Date()) -> BusArrivalRowModel? {
        let scheduledSource = scheduledTime ?? (item.isRealtime ? nil : item.arrivalTime)
        let scheduledMinutes = scheduledSource.map { Int(($0.toLocalTime().busServiceSeconds - now.busServiceSeconds) / 60) }
        return BusDisplayLogic.arrivalRow(BusArrivalRowInput(
            route: route, isRealtime: item.isRealtime, stops: item.stops, seats: item.seats,
            realtimeMinutes: item.minutes, scheduledMinutes: scheduledMinutes, isLowFloor: item.lowFloor ?? false,
            destinationArrival: showSecondary ? secondaryConvertedTime : nil,
            destinationName: destinationStopID.map { BusRealtimeSections.destinationName(for: $0) }
        ))
    }
}
