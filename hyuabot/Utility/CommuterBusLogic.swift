//
//  CommuterBusLogic.swift
//  hyuabot
//

import Api
import CoreGraphics
import Foundation

enum CommuterDirection: String, CaseIterable, Equatable { case toCampus, fromCampus }

struct CommuterStop: Equatable {
    let time: String?
    let name: String
    let detail: String
    let latitude: Double
    let longitude: Double
    var hasCoordinate: Bool {
        latitude != 0
    }

    var isCampus: Bool {
        name.hasPrefix("ERICA")
    }
}

struct CommuterRoute: Equatable {
    let name: String
    let summary: String
    let stops: [CommuterStop]
    var direction: CommuterDirection {
        stops.last?.isCampus == true ? .toCampus : .fromCampus
    }
}

struct CommuterServiceContext: Equatable {
    var date: Foundation.Date
    var nowMinutes: Int
    var periodType: String?
    var periodEndDay: Foundation.Date?
    var holidayType: String?
    var nextRunDay: Foundation.Date?
    var userLocation: ShuttleGeoCoordinate?
}

struct CommuterSelection: Equatable {
    var direction: CommuterDirection?
    var routeName: String?
    var expanded: Bool
    static let auto = CommuterSelection(direction: nil, routeName: nil, expanded: false)
}

enum CommuterPhase: Equatable { case off, beforeRun, finished, running }
enum CommuterOffReason: Equatable { case halt, vacationSession, vacation, weekend }
struct CommuterOffNotice: Equatable {
    let reason: CommuterOffReason
    let nextRunDay: Foundation.Date
}

enum CommuterPeriodSubtitle: Equatable { case semester(endDay: Foundation.Date), weekdaysOnly }
struct CommuterDirectionItem: Equatable {
    let direction: CommuterDirection
    let routeCount: Int
    let isSelected: Bool
}

struct CommuterRouteItem: Equatable {
    let name: String
    let summary: String
    let isSelected: Bool
}

struct CommuterRouteSummary: Equatable {
    let routeName: String
    let direction: CommuterDirection
    let firstTime: String
    let lastTime: String?
    let stopCount: Int
    let durationMinutes: Int?
    let isPartial: Bool
    let phase: CommuterPhase
}

enum CommuterClockAction: Equatable { case tick(nowMinutes: Int), reloadContext }
enum CommuterRailStyle: Equatable { case hidden, normal, traveled }
enum CommuterDotStyle: Equatable { case traveled, filled, hollow }
enum CommuterStopTag: Equatable { case departure, arrival }
struct CommuterStopRow: Equatable {
    let index: Int
    let stop: CommuterStop
    let isNear: Bool
    let isPassed: Bool
    let tag: CommuterStopTag?
    let dotSize: CGFloat
    let dotStyle: CommuterDotStyle
    let lineTop: CommuterRailStyle
    let lineBottom: CommuterRailStyle
}

enum CommuterTimelineRow: Equatable { case fold(hiddenCount: Int), stop(CommuterStopRow), bus, gap(minutes: Int, traveled: Bool) }
struct CommuterScreenModel: Equatable {
    let subtitle: CommuterPeriodSubtitle
    let directions: [CommuterDirectionItem]
    let routes: [CommuterRouteItem]
    let showsResetToNearest: Bool
    let autoDirection: CommuterDirection
    let autoRouteName: String?
    let selectedDirection: CommuterDirection
    let selectedRouteName: String?
    let summary: CommuterRouteSummary?
    let offNotice: CommuterOffNotice?
    let rows: [CommuterTimelineRow]
}

enum CommuterBusLogic {
    static let timeZone: TimeZone = {
        guard let zone = TimeZone(identifier: "Asia/Seoul") else {
            preconditionFailure("Asia/Seoul time zone is unavailable")
        }
        return zone
    }()
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = timeZone
        return value
    }

    static func minutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2 || parts.count == 3, let hours = Int(parts[0]), let minute = Int(parts[1]), (0 ... 23).contains(hours),
              (0 ... 59).contains(minute) else { return nil }
        if parts.count == 3, (Int(parts[2]).map { (0 ... 59).contains($0) } != true) {
            return nil
        }
        return hours * 60 + minute
    }

    static func meters(from origin: ShuttleGeoCoordinate, to destination: ShuttleGeoCoordinate) -> Double {
        let radians = Double.pi / 180
        let x = (destination.longitude - origin.longitude) * radians * cos((origin.latitude + destination.latitude) / 2 * radians)
        let y = (destination.latitude - origin.latitude) * radians
        return sqrt(x * x + y * y) * 6_371_000
    }

    static func day(year: Int, month: Int, day: Int) -> Foundation.Date {
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            preconditionFailure("Invalid Gregorian date")
        }
        return date
    }

    static func nextWeekday(after date: Foundation.Date) -> Foundation.Date {
        var next = date
        repeat {
            guard let followingDay = calendar.date(byAdding: .day, value: 1, to: next) else {
                preconditionFailure("Cannot advance Gregorian date")
            }
            next = followingDay
        } while [1, 7].contains(calendar.component(.weekday, from: next))
        return calendar.startOfDay(for: next)
    }

    static func firstWeekday(onOrAfter date: Foundation.Date) -> Foundation.Date {
        var next = calendar.startOfDay(for: date)
        while [1, 7].contains(calendar.component(.weekday, from: next)) {
            guard let followingDay = calendar.date(byAdding: .day, value: 1, to: next) else {
                preconditionFailure("Cannot advance Gregorian date")
            }
            next = followingDay
        }
        return next
    }

    static func periodBoundaryDay(_ isoDateTime: String) -> Foundation.Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let instant = formatter.date(from: isoDateTime) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: isoDateTime)
        }()
        guard let instant else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let parts = utc.dateComponents([.year, .month, .day], from: instant)
        guard let year = parts.year, let month = parts.month, let day = parts.day else { return nil }
        return self.day(year: year, month: month, day: day)
    }

    static func queryDateString(_ date: Foundation.Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func minutesOfDay(_ date: Foundation.Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    static func clockAction(contextDate: Foundation.Date, now: Foundation.Date) -> CommuterClockAction {
        queryDateString(now) == queryDateString(contextDate) ? .tick(nowMinutes: minutesOfDay(now)) : .reloadContext
    }

    static func routes(from commute: [CommuterBusPageQuery.Data.Commute], korean: Bool) -> [CommuterRoute] {
        commute.compactMap { route in
            let stops = route.timetable.sorted { $0.order < $1.order }.map { entry -> CommuterStop in
                let rawTime = String(entry.time.description.prefix(5))
                return CommuterStop(
                    time: rawTime == "00:00" ? nil : rawTime,
                    name: entry.stop?.name ?? entry.name,
                    detail: entry.stop?.description ?? "",
                    latitude: entry.stop?.latitude ?? 0,
                    longitude: entry.stop?.longitude ?? 0
                )
            }
            guard !stops.isEmpty else { return nil }
            return CommuterRoute(name: route.name, summary: korean ? route.description.korean : route.description.english, stops: stops)
        }
    }

    private struct NearestStop {
        let routeName: String
        let index: Int
        let meters: Double
    }

    private static func nearestStop(
        routes: [CommuterRoute], context: CommuterServiceContext, direction: CommuterDirection
    ) -> NearestStop? {
        var near: NearestStop?
        if let location = context.userLocation {
            for route in routes where route.direction == direction {
                for (index, stop) in route.stops.enumerated()
                    where (direction == .toCampus ? !stop.isCampus : stop.isCampus) && stop.hasCoordinate {
                    let distance = meters(from: location, to: ShuttleGeoCoordinate(latitude: stop.latitude, longitude: stop.longitude))
                    if near == nil || distance < (near?.meters ?? .infinity) {
                        near = NearestStop(routeName: route.name, index: index, meters: distance)
                    }
                }
            }
        }
        return near
    }

    private static func serviceNotice(
        context: CommuterServiceContext, running: Bool, semester: Bool, weekend: Bool
    ) -> CommuterOffNotice? {
        var offNotice: CommuterOffNotice?
        if !running {
            let next = context.nextRunDay ?? nextWeekday(after: context.date)
            let reason: CommuterOffReason? = context
                .holidayType == "halt" ? .halt : !semester ? (context.periodType == "vacation_session" ? .vacationSession : .vacation) :
                weekend ? .weekend : nil
            if let reason {
                offNotice = CommuterOffNotice(reason: reason, nextRunDay: next)
            }
        }
        return offNotice
    }

    static func makeModel(routes: [CommuterRoute], context: CommuterServiceContext, selection: CommuterSelection) -> CommuterScreenModel {
        let weekday = calendar.component(.weekday, from: context.date)
        let weekend = weekday == 1 || weekday == 7 || context.holidayType == "weekends"
        let semester = context.periodType == "semester"
        let running = semester && !weekend && context.holidayType != "halt"
        let subtitle: CommuterPeriodSubtitle = semester
            ? context.periodEndDay.map { .semester(endDay: $0) } ?? .weekdaysOnly : .weekdaysOnly
        let autoDirection: CommuterDirection = context.nowMinutes < 720 ? .toCampus : .fromCampus
        let near = nearestStop(routes: routes, context: context, direction: autoDirection)
        let autoRoute = near?.routeName ?? routes.first(where: { $0.direction == autoDirection })?.name
        let reset = (selection.direction != nil || selection.routeName != nil) &&
            (selection.direction != autoDirection || selection.routeName != autoRoute)
        let selectedDirection = selection.direction ?? autoDirection
        let list = routes.filter { $0.direction == selectedDirection }
        let want = selection.routeName ?? autoRoute
        let current = list.first(where: { $0.name == want }) ?? list.first
        let nearHere = near.flatMap { $0.routeName == current?.name ? $0 : nil }
        let directions = CommuterDirection.allCases.map { direction in CommuterDirectionItem(
            direction: direction,
            routeCount: routes.filter { $0.direction == direction }.count,
            isSelected: direction == selectedDirection
        )
        }
        let routeItems = list.map { CommuterRouteItem(name: $0.name, summary: $0.summary, isSelected: $0.name == current?.name) }
        let offNotice = serviceNotice(context: context, running: running, semester: semester, weekend: weekend)
        guard let current, !current.stops.isEmpty else {
            return CommuterScreenModel(
                subtitle: subtitle,
                directions: directions,
                routes: routeItems,
                showsResetToNearest: reset,
                autoDirection: autoDirection,
                autoRouteName: autoRoute,
                selectedDirection: selectedDirection,
                selectedRouteName: nil,
                summary: nil,
                offNotice: offNotice,
                rows: []
            )
        }
        let (summary, rows) = timeline(current: current, context: context, selection: selection, running: running, nearHere: nearHere)
        return CommuterScreenModel(
            subtitle: subtitle,
            directions: directions,
            routes: routeItems,
            showsResetToNearest: reset,
            autoDirection: autoDirection,
            autoRouteName: autoRoute,
            selectedDirection: selectedDirection,
            selectedRouteName: current.name,
            summary: summary,
            offNotice: offNotice,
            rows: rows
        )
    }

    private static func currentSegment(stops: [CommuterStop], phase: CommuterPhase, partial: Bool, nowMinutes: Int) -> Int {
        var segment = -1
        if phase == .running, !partial {
            for index in 0 ..< stops.count - 1
                where nowMinutes >= (minutes(stops[index].time ?? "") ?? 0) && nowMinutes < (minutes(stops[index + 1].time ?? "") ?? 0) {
                segment = index
                break
            }
        }
        return segment
    }

    private static func timeline(
        current: CommuterRoute, context: CommuterServiceContext, selection: CommuterSelection,
        running: Bool, nearHere: NearestStop?
    ) -> (CommuterRouteSummary, [CommuterTimelineRow]) {
        let stops = current.stops, last = stops.count - 1
        let partial = stops.contains { $0.time == nil }
        let firstMinutes = minutes(stops[0].time ?? "") ?? 0
        let lastMinutes = minutes(stops[last].time ?? "")
        let phase: CommuterPhase = !running ? .off : context
            .nowMinutes < firstMinutes ? .beforeRun : (!partial && context.nowMinutes >= (lastMinutes ?? 0)) ? .finished : .running
        let segment = currentSegment(stops: stops, phase: phase, partial: partial, nowMinutes: context.nowMinutes)
        let summary = CommuterRouteSummary(
            routeName: current.name,
            direction: current.direction,
            firstTime: stops[0].time ?? "—",
            lastTime: stops[last].time,
            stopCount: stops.count,
            durationMinutes: partial ? nil : (lastMinutes ?? 0) - firstMinutes,
            isPartial: partial,
            phase: phase
        )
        let rows = timelineRows(
            stops: stops,
            phase: phase,
            segment: segment,
            nearHere: nearHere,
            expanded: selection.expanded,
            direction: current.direction
        )
        return (summary, rows)
    }

    private static func timelineRows(
        stops: [CommuterStop], phase: CommuterPhase, segment: Int, nearHere: NearestStop?, expanded: Bool,
        direction: CommuterDirection
    ) -> [CommuterTimelineRow] {
        let last = stops.count - 1
        let known: (Int) -> Bool = { stops[$0].time != nil }
        var anchor = nearHere?.index ?? segment
        if segment >= 0, let nearHere {
            anchor = min(segment + 1, nearHere.index)
        }
        let foldTo = !expanded && anchor > 2 ? anchor - 1 : 0
        var rows: [CommuterTimelineRow] = []
        if foldTo > 0 {
            rows.append(.fold(hiddenCount: foldTo))
        }
        for index in foldTo ... last {
            let stop = stops[index], campus = stop.isCampus, passed = phase == .finished || (segment >= 0 && index <= segment)
            let isNear = nearHere?.index == index
            let gap = index < last && known(index) && known(index + 1) ? (minutes(stops[index + 1].time ?? "") ?? 0) -
                (minutes(stop.time ?? "") ?? 0) : 0
            let big = gap >= 20
            let dotFill = isNear || campus || index == 0
            let dot: CommuterDotStyle = passed && !isNear ? .traveled : dotFill ? .filled : .hollow
            let tag: CommuterStopTag? = campus ? (direction == .toCampus ? .arrival : .departure) : (index == 0 ? .departure : nil)
            let top: CommuterRailStyle = index == 0 ? .hidden : passed && index > 0 ? .traveled : .normal
            let bottom: CommuterRailStyle = (index == last || (big && index != segment)) ? .hidden :
                ((phase == .finished || (segment >= 0 && index < segment) || index == segment) ? .traveled : .normal)
            rows.append(.stop(CommuterStopRow(
                index: index,
                stop: stop,
                isNear: isNear,
                isPassed: passed,
                tag: tag,
                dotSize: isNear ? 14 : campus ? 12 : 10,
                dotStyle: dot,
                lineTop: top,
                lineBottom: bottom
            )))
            if index == segment {
                rows.append(.bus)
            } else if big {
                rows.append(.gap(
                    minutes: gap,
                    traveled: phase == .finished || (segment >= 0 && index < segment)
                ))
            }
        }
        return rows
    }

    static func durationText(minutes: Int) -> String {
        let hours = minutes / 60, remainder = minutes % 60
        if hours > 0, remainder > 0 {
            return String(localized: "commuter.duration.hours_minutes.\(hours).\(remainder)")
        }
        if hours > 0 {
            return String(localized: "commuter.duration.hours.\(hours)")
        }
        return String(localized: "commuter.duration.minutes.\(remainder)")
    }

    static func dayText(_ day: Foundation.Date) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = String(localized: "commuter.date.format")
        formatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ko")
        formatter.timeZone = timeZone
        return formatter.string(from: day)
    }
}
