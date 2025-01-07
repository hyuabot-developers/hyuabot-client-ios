import RxSwift
import QueryAPI

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    // Realtime Query
    let shuttleRealtimeData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleDormitoryToStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleDormitoryToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleDormitoryToJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleShuttlecockToStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleShuttlecockToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleShuttlecockToJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleStationToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleStationToTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleStationToJungangStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleTerminalToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleJungangStationToCampusData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleShuttlecockToDormitoryData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
}
