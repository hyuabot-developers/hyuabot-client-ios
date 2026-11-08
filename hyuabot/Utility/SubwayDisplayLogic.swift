//
//  SubwayDisplayLogic.swift
//  hyuabot
//
import UIKit

enum SubwayLine: Equatable { case line4, suin }

enum SubwayRouteLine: Equatable {
    case line4, suin

    static func from(stationID: String) -> SubwayRouteLine {
        stationID.hasPrefix("K4") ? .line4 : .suin
    }

    var color: UIColor {
        switch self {
        case .line4: HYUColor.Route.subwayLine4
        case .suin: HYUColor.Route.subwaySuinBundang
        }
    }

    var name: String {
        String(localized: self == .line4 ? "subway.line.name.line4" : "subway.line.name.suin")
    }

    var badgeText: String {
        String(localized: self == .line4 ? "subway.line.badge.line4" : "subway.line.badge.suin")
    }
}

enum SubwayDayType: Equatable {
    case weekdays, weekends

    static func of(_ date: Date, calendar: Calendar = .current) -> SubwayDayType {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 ? .weekends : .weekdays
    }

    /// Service day: trains running between 00:00 and 04:00 belong to the previous day's timetable.
    static func serviceDay(_ date: Date, calendar: Calendar = .current) -> SubwayDayType {
        let shifted = calendar.component(.hour, from: date) < 4 ? date.addingTimeInterval(-86_400) : date
        return of(shifted, calendar: calendar)
    }

    var apiValue: String {
        self == .weekdays ? "weekdays" : "weekends"
    }
}

struct SubwayArrivalInfo: Equatable {
    let terminalName: String
    let minutes: Int
    let isRealtime: Bool
    let isLast: Bool
    let status: Int?
    let location: String?
}

struct SubwayArrivalRowModel: Equatable {
    let destination: String
    let minutesText: String
    let subtitle: String?
    let isRealtime: Bool
    let isSoon: Bool
    let isLast: Bool
    let accessibilityLabel: String
}

struct SubwayTransferLegInfo: Equatable {
    let line: SubwayRouteLine
    let terminalName: String
    let minutes: Int
    var location: String?
    var status: Int?
}

struct SubwayTransferRouteInfo: Equatable {
    let first: SubwayTransferLegInfo
    let transferStation: String?
    let waitMinutes: Int?
    let second: SubwayTransferLegInfo?
}

struct SubwayTransferLegModel: Equatable {
    let line: SubwayRouteLine
    let destination: String
    let lineName: String
    let trailingText: String
    let isStrong: Bool
    let isSoon: Bool
}

struct SubwayTransferRouteModel: Equatable {
    let first: SubwayTransferLegModel
    let transferStation: String?
    let waitText: String?
    let second: SubwayTransferLegModel?
    let accessibilityLabel: String
}

enum SubwaySectionBadge: Equatable { case line(SubwayRouteLine); case transfer }

struct SubwayTimetableTarget: Equatable {
    let line: SubwayLine
    let heading: SubwayHeadingEnum
    let accessibilityLabel: String
}

enum SubwaySectionRows: Equatable { case arrivals([SubwayArrivalRowModel]); case transfers([SubwayTransferRouteModel]) }

struct SubwaySectionContent: Equatable {
    let badge: SubwaySectionBadge
    let title: String
    let timetable: SubwayTimetableTarget?
    let rows: SubwaySectionRows
    let emptyMessage: String

    var isEmpty: Bool {
        switch rows {
        case let .arrivals(items): items.isEmpty
        case let .transfers(items): items.isEmpty
        }
    }
}

struct SubwayTimetableDeparture: Equatable {
    let minutes: Int
    let terminalName: String
    let line: SubwayLine
    let isFirst: Bool
    let isLast: Bool
}

struct SubwayTimetableRowModel: Equatable {
    let timeText: String
    let destination: String
    let line: SubwayLine
    let isPast: Bool
    let isNext: Bool
    let nextText: String?
    let isFirst: Bool
    let isLast: Bool
    let accessibilityLabel: String
}

struct SubwayTimetableHourGroup: Equatable {
    let hour: Int
    let title: String
    let accessibilityLabel: String
    let rows: [SubwayTimetableRowModel]
}

struct SubwayTimetableLayout: Equatable { let hiddenPastCount: Int; let groups: [SubwayTimetableHourGroup] }

enum SubwayDisplayLogic {
    static let maxTransferRoutesPerSection = 4

    static func routeLine(_ line: SubwayLine) -> SubwayRouteLine {
        line == .line4 ? .line4 : .suin
    }

    static func title(line: SubwayLine, heading: SubwayHeadingEnum) -> String {
        switch (line == .line4, heading == .up) {
        case (true, true): return String(localized: "subway.direction.4.up")
        case (true, false): return String(localized: "subway.direction.4.down")
        case (false, true): return String(localized: "subway.direction.suin.up")
        case (false, false): return String(localized: "subway.direction.suin.down")
        }
    }

    static func isMerged(line: SubwayLine, heading: SubwayHeadingEnum) -> Bool {
        line == .line4 && heading == .down
    }

    static func positionText(location: String?, status: Int?) -> String? {
        guard let location, !location.isEmpty, let status else { return nil }
        let key: String
        switch status {
        case 0: key = "subway.realtime.status.entering.%@"
        case 1: key = "subway.realtime.status.arrived.%@"
        case 2, 3: key = "subway.realtime.status.departed.%@"
        default: return nil
        }
        return String(format: String(localized: String.LocalizationValue(key)), location)
    }

    static func arrivalRow(_ info: SubwayArrivalInfo) -> SubwayArrivalRowModel {
        let destination = String(format: String(localized: "subway.transfer.destination.%@"), info.terminalName)
        let isSoon = info.isRealtime && (info.status == 3 || info.minutes <= 1)
        let minutesText = isSoon ? String(localized: "subway.realtime.soon") :
            String(format: String(localized: "subway.realtime.minutes.%lld"), info.minutes)
        let subtitle = info.isRealtime ? positionText(location: info.location, status: info.status) : nil
        let suffix = subtitle.map { ", \($0)" } ?? (info.isRealtime ? "" : ", " + String(localized: "subway.realtime.a11y.timetable"))
        let last = info.isLast ? ", " + String(localized: "subway.chip.last") : ""
        return SubwayArrivalRowModel(
            destination: destination,
            minutesText: minutesText,
            subtitle: subtitle,
            isRealtime: info.isRealtime,
            isSoon: isSoon,
            isLast: info.isLast,
            accessibilityLabel: "\(destination) \(minutesText)\(suffix)\(last)"
        )
    }

    static func transferRoute(_ info: SubwayTransferRouteInfo, now: Date, calendar: Calendar = .current) -> SubwayTransferRouteModel {
        let first = info.first
        let position = positionText(location: first.location, status: first.status)
        let firstDestination = String(format: String(localized: "subway.transfer.destination.%@"), first.terminalName)
        let firstSoon = position == nil && first.minutes <= 1
        let firstTrailing = position ?? (firstSoon ? String(localized: "subway.transfer.soon") :
            String(format: String(localized: "subway.minutes.after.%lld"), first.minutes))
        let firstModel = SubwayTransferLegModel(
            line: first.line,
            destination: firstDestination,
            lineName: first.line.name,
            trailingText: firstTrailing,
            isStrong: position == nil,
            isSoon: firstSoon
        )
        let second = info.second.map { leg in
            let destination = String(format: String(localized: "subway.transfer.destination.%@"), leg.terminalName)
            let clock = clockText(after: leg.minutes, now: now, calendar: calendar)
            return SubwayTransferLegModel(
                line: leg.line,
                destination: destination,
                lineName: leg.line.name,
                trailingText: String(format: String(localized: "subway.transfer.departure.%@"), clock),
                isStrong: false,
                isSoon: false
            )
        }
        let wait = info.second == nil ? nil : info.waitMinutes.map {
            String(format: String(localized: "subway.transfer.wait.dot.%lld"), $0)
        }
        let firstA11y = position.map { String(format: String(localized: "subway.transfer.a11y.current.%@"), $0) } ?? firstTrailing
        let transferA11y = if let second {
            ", " + String(
                format: String(localized: "subway.transfer.a11y.transfer.%@.%lld"),
                info.transferStation ?? "",
                info.waitMinutes ?? 0
            ) +
                ", \(second.lineName) \(second.destination) \(second.trailingText)"
        } else {
            ", " + String(localized: "subway.transfer.a11y.direct")
        }
        return SubwayTransferRouteModel(
            first: firstModel,
            transferStation: second == nil ? nil : info.transferStation,
            waitText: wait,
            second: second,
            accessibilityLabel: "\(first.line.name) \(firstDestination) \(firstA11y)\(transferA11y)"
        )
    }

    static func lineSections(line: SubwayLine, up: [SubwayArrivalInfo], down: [SubwayArrivalInfo]) -> [SubwaySectionContent] {
        [section(line: line, heading: .up, arrivals: up), section(line: line, heading: .down, arrivals: down)]
    }

    static func transferSections(
        toIncheon: [SubwayTransferRouteInfo],
        toHanyang: [SubwayTransferRouteInfo],
        now: Date,
        calendar: Calendar = .current
    ) -> [SubwaySectionContent] {
        let upDestination = String(localized: "subway.transfer.destination.up")
        let downDestination = String(localized: "subway.transfer.destination.down")
        return [
            SubwaySectionContent(
                badge: .transfer,
                title: String(localized: "subway.direction.transfer.up"),
                timetable: nil,
                rows: .transfers(Array(toIncheon.prefix(maxTransferRoutesPerSection)).map {
                    transferRoute($0, now: now, calendar: calendar)
                }),
                emptyMessage: String(format: String(localized: "subway.realtime.empty.transfer.%@"), upDestination)
            ),
            SubwaySectionContent(
                badge: .transfer,
                title: String(localized: "subway.direction.transfer.down"),
                timetable: nil,
                rows: .transfers(Array(toHanyang.prefix(maxTransferRoutesPerSection)).map {
                    transferRoute($0, now: now, calendar: calendar)
                }),
                emptyMessage: String(format: String(localized: "subway.realtime.empty.transfer.%@"), downDestination)
            )
        ]
    }

    static func sortableMinutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return (hour < 4 ? hour + 24 : hour) * 60 + minute
    }

    static func nowMinutes(_ date: Date, calendar: Calendar = .current) -> Int {
        let hour = calendar.component(.hour, from: date)
        return (hour < 4 ? hour + 24 : hour) * 60 + calendar.component(.minute, from: date)
    }

    private struct IndexedDeparture {
        let minutes: Int
        let index: Int
        let terminalName: String
    }

    static func departures(_ items: [(time: String, terminalName: String)], line: SubwayLine) -> [SubwayTimetableDeparture] {
        let sorted = items.enumerated().compactMap { index, item -> IndexedDeparture? in
            sortableMinutes(item.time).map { IndexedDeparture(minutes: $0, index: index, terminalName: item.terminalName) }
        }.sorted { $0.minutes == $1.minutes ? $0.index < $1.index : $0.minutes < $1.minutes }
        return sorted.enumerated().map { index, item in
            SubwayTimetableDeparture(
                minutes: item.minutes,
                terminalName: item.terminalName,
                line: line,
                isFirst: index == 0,
                isLast: index == sorted.count - 1
            )
        }
    }

    static func merged(_ lists: [[SubwayTimetableDeparture]]) -> [SubwayTimetableDeparture] {
        let sorted = lists.flatMap { $0 }.enumerated().sorted {
            $0.element.minutes == $1.element.minutes ? $0.offset < $1.offset : $0.element.minutes < $1.element.minutes
        }.map(\.element)
        return sorted.enumerated().map { index, departure in
            SubwayTimetableDeparture(
                minutes: departure.minutes,
                terminalName: departure.terminalName,
                line: departure.line,
                isFirst: index == 0,
                isLast: index == sorted.count - 1
            )
        }
    }

    static func timetableLayout(
        _ departures: [SubwayTimetableDeparture],
        nowMinutes: Int?,
        expanded: Bool,
        merged: Bool
    ) -> SubwayTimetableLayout {
        let departures = merged ? self.merged([departures]) : departures
        let next = nowMinutes.flatMap { now in departures.firstIndex { $0.minutes >= now } }
        let hidden = nowMinutes != nil && !expanded ? max(0, next ?? (departures.count - 1)) : 0
        var groups: [SubwayTimetableHourGroup] = []
        for (index, departure) in departures.enumerated() where index >= hidden {
            let hour = departure.minutes / 60
            let timeText = String(format: "%02d:%02d", (departure.minutes / 60) % 24, departure.minutes % 60)
            let destination = String(format: String(localized: "subway.transfer.destination.%@"), departure.terminalName)
            let past = nowMinutes.map { departure.minutes < $0 } ?? false
            let isNext = index == next
            let nextText: String? = isNext ? (departure.minutes - (nowMinutes ?? departure.minutes) <= 0 ?
                String(localized: "subway.transfer.soon") :
                String(format: String(localized: "subway.minutes.after.%lld"), departure.minutes - (nowMinutes ?? departure.minutes))) : nil
            let linePrefix = merged ? departure.line == .line4 ? String(localized: "subway.line.name.line4") + " " :
                String(localized: "subway.line.name.suin") + " " : ""
            let label = "\(timeText) \(linePrefix)\(destination)" +
                (past ? ", " + String(localized: "subway.timetable.a11y.past") : "") +
                (isNext ? ", " + String(
                    format: String(localized: "subway.timetable.a11y.next.%lld"),
                    max(0, departure.minutes - (nowMinutes ?? departure.minutes))
                ) : "") +
                (departure.isLast ? ", " + String(localized: "subway.chip.last") : "")
            let row = SubwayTimetableRowModel(
                timeText: timeText,
                destination: destination,
                line: departure.line,
                isPast: past,
                isNext: isNext,
                nextText: nextText,
                isFirst: departure.isFirst,
                isLast: departure.isLast,
                accessibilityLabel: label
            )
            let title = hour >= 24 ? String(
                format: String(localized: "subway.timetable.hour.after.midnight.%@"),
                String(format: "%02d", hour - 24)
            ) :
                String(format: String(localized: "subway.timetable.hour.%@"), String(format: "%02d", hour))
            let accessibility = String(format: String(localized: "subway.timetable.hour.a11y.%lld"), hour % 24)
            if groups.last?.hour == hour {
                let previous = groups.removeLast()
                groups.append(SubwayTimetableHourGroup(
                    hour: hour,
                    title: title,
                    accessibilityLabel: accessibility,
                    rows: previous.rows + [row]
                ))
            } else {
                groups.append(SubwayTimetableHourGroup(hour: hour, title: title, accessibilityLabel: accessibility, rows: [row]))
            }
        }
        return SubwayTimetableLayout(hiddenPastCount: hidden, groups: groups)
    }

    private static func section(line: SubwayLine, heading: SubwayHeadingEnum, arrivals: [SubwayArrivalInfo]) -> SubwaySectionContent {
        let route = routeLine(line)
        let title = title(line: line, heading: heading)
        let label = String(format: String(localized: "subway.realtime.timetable.a11y.%@.%@"), route.name, title)
        let target = SubwayTimetableTarget(line: line, heading: heading, accessibilityLabel: label)
        return SubwaySectionContent(
            badge: .line(route),
            title: title,
            timetable: target,
            rows: .arrivals(arrivals.map(arrivalRow)),
            emptyMessage: String(localized: "subway.realtime.empty.message")
        )
    }

    private static func clockText(after minutes: Int, now: Date, calendar: Calendar) -> String {
        let date = calendar.date(byAdding: .minute, value: minutes, to: now) ?? now
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
