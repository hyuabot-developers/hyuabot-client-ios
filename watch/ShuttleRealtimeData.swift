import RxSwift
import QueryAPI

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    var subscription: Disposable?
    // Realtime Query
    let isLoading = BehaviorSubject<Bool>(value: true)
    let shuttleRealtimeData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleDormitoryData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleShuttlecockData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleStationData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleTerminalData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleJungangStatioData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
    let shuttleShuttlecockOppositeData = BehaviorSubject<[ShuttleRealtimePageQuery.Data.Shuttle.Timetable]?>(value: [])
}
