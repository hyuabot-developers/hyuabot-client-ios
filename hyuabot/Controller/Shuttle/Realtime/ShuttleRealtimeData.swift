//
//  ShuttleRealtimeData.swift
//  hyuabot
//

import Api
import RxSwift
import RxRelay
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
    let isLoading = BehaviorRelay<Bool>(value: true)
    // Realtime Query
    let arrival = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop]>(value: [])
    let nextDayTimetable = BehaviorRelay<ShuttleNextDayTimetable?>(value: nil)
    let notices = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Notice.Notice]>(value: [])
    let shuttleDormitoryData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleDormitoryToStationData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleDormitoryToTerminalData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleDormitoryToJungangStationData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleShuttlecockToStationData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockToTerminalData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockToJungangStationData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleStationToCampusData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationToTerminalData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationToJungangStationData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleTerminalData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleTerminalToCampusData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleJungangStationData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleJungangStationToCampusData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockInData = BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleShuttlecockInToDormitoryData =
        BehaviorRelay<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let transferData = BehaviorRelay<ShuttleRealtimePageQuery.Data?>(value: nil)
    /// Bus alternative data
    let busAlternatives = BehaviorRelay<[String: [ShuttleBusAlternativeDisplayData]]>(value: [:])
    /// Show Remaining Time
    /// Show arrival by time
    let showRemainingTime = BehaviorRelay<Bool>(value: true)
    let showArrivalByTime = BehaviorRelay<Bool>(value: true)

    func prepareForSubwayLanguage(_ language: String) {
        guard loadedSubwayLanguage != language else { return }
        loadedSubwayLanguage = language
        transferData.accept(nil)
        isLoading.accept(true)
    }
}
