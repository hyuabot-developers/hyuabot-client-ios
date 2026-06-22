import RxSwift
import Api
import UIKit

struct ShuttleBusAlternativeDisplayData: Equatable {
    let routeName: String
    let minutes: Int?
    let color: UIColor
    let busStopName: String
    let busStopLatitude: Double
    let busStopLongitude: Double
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

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    let isLoading = BehaviorSubject<Bool>(value: true)
    // Realtime Query
    let arrival = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop]>(value: [])
    let notices = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Notice.Notice]>(value: [])
    let shuttleDormitoryData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleDormitoryToStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleDormitoryToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleDormitoryToJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleShuttlecockToStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockToJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleStationToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleStationToJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleTerminalToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleJungangStationToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let shuttleShuttlecockInData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let shuttleShuttlecockInToDormitoryData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]>(value: [])
    let transferData = BehaviorSubject<ShuttleRealtimePageQuery.Data?>(value: nil)
    // Bus alternative data
    let busAlternatives = BehaviorSubject<[String: [ShuttleBusAlternativeDisplayData]]>(value: [:])
    // Show Remaining Time
    let showRemainingTime = BehaviorSubject<Bool>(value: true)
    // Show arrival by time
    let showArrivalByTime = BehaviorSubject<Bool>(value: true)
}
