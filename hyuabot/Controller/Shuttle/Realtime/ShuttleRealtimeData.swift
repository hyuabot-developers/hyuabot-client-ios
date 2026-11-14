//
//  ShuttleRealtimeData.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit

struct ShuttleBusAlternativeDisplayData: Equatable {
    let routeName: String
    let minutes: Int?
    let color: UIColor
    let busStopName: String
    let busStopLatitude: Double
    let busStopLongitude: Double
    var isRealtime = true
}

struct ShuttleAlarmStop: Equatable {
    let id: String
    let name: String
    let time: Foundation.Date
    let latitude: Double?
    let longitude: Double?
}

struct ShuttleAlarmContext: Equatable {
    let key: String
    let routeName: String
    let routeDisplayName: String
    let directionDisplayName: String
    let boardingStop: ShuttleAlarmStop
    let routeStops: [ShuttleAlarmStop]
    let departureTime: Foundation.Date
    let minutesUntilDeparture: Int
    let createdAt: Foundation.Date
    var chipKind: ShuttleDisplayLogic.RouteChipKind = .fallback

    var destinationStops: [ShuttleAlarmStop] {
        guard let boardingIndex = routeStops.firstIndex(where: { $0.id == boardingStop.id }) else {
            return []
        }
        return Array(routeStops.dropFirst(boardingIndex + 1))
    }

    var boardingCheckpointStops: [ShuttleAlarmStop] {
        guard let boardingIndex = routeStops.firstIndex(where: { $0.id == boardingStop.id }) else {
            return [boardingStop]
        }
        return Array(routeStops.prefix(boardingIndex + 1))
    }
}

struct ShuttleNextDayTimetable: Equatable {
    let date: String
    let isWeekend: Bool
    let departures: [String: [String: [String]]]
}

/// Use this loader only on the main actor. A completion for a date that is no longer in flight is discarded, so an older request can never overwrite a newer date.
@MainActor
final class ShuttleNextDayTimetableLoader {
    typealias Departures = [String: [String: [String]]]
    typealias Fetch = @MainActor (_ date: String, _ completion: @escaping @MainActor (Departures?) -> Void) -> Void

    private let current: @MainActor () -> ShuttleNextDayTimetable?
    private let publish: @MainActor (ShuttleNextDayTimetable?) -> Void
    private let fetch: Fetch
    private(set) var inFlightDate: String?

    init(
        current: @escaping @MainActor () -> ShuttleNextDayTimetable?,
        publish: @escaping @MainActor (ShuttleNextDayTimetable?) -> Void,
        fetch: @escaping Fetch
    ) {
        self.current = current
        self.publish = publish
        self.fetch = fetch
    }

    func load(date: String, isWeekend: Bool) {
        let existing = current()
        if existing?.date == date { return }
        if inFlightDate == date { return }
        if existing != nil { publish(nil) }
        inFlightDate = date
        fetch(date) { [weak self] departures in
            guard let self, self.inFlightDate == date else { return }
            self.inFlightDate = nil
            guard let departures else { return }
            self.publish(ShuttleNextDayTimetable(date: date, isWeekend: isWeekend, departures: departures))
        }
    }
}

@MainActor
class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    var loadedSubwayLanguage: String?
    let isLoading = BehaviorSubject<Bool>(value: true)
    // Realtime Query
    let arrival = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop]>(value: [])
    let nextDayTimetable = BehaviorSubject<ShuttleNextDayTimetable?>(value: nil)
    let notices = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Notice.Notice]>(value: [])
    let shuttleDormitoryData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleDormitoryToStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleDormitoryToTerminalData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleDormitoryToJungangStationData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleShuttlecockToStationData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockToTerminalData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockToJungangStationData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleStationToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationToJungangStationData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleTerminalToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleJungangStationToCampusData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockInData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleShuttlecockInToDormitoryData =
        BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let transferData = BehaviorSubject<ShuttleRealtimePageQuery.Data?>(value: nil)
    /// Bus alternative data
    let busAlternatives = BehaviorSubject<[String: [ShuttleBusAlternativeDisplayData]]>(value: [:])
    /// Show Remaining Time
    /// Show arrival by time
    let showRemainingTime = BehaviorSubject<Bool>(value: true)
    let showArrivalByTime = BehaviorSubject<Bool>(value: true)

    func prepareForSubwayLanguage(_ language: String) {
        guard loadedSubwayLanguage != language else { return }
        loadedSubwayLanguage = language
        transferData.onNext(nil)
        isLoading.onNext(true)
    }
}
