import RxSwift
import Api

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
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
    // Show Remaining Time
    let showRemainingTime = BehaviorSubject<Bool>(value: true)
    // Show arrival by time
    let showArrivalByTime = BehaviorSubject<Bool>(value: true)
}
