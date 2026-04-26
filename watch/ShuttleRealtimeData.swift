import RxSwift
import Api

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    var subscription: Disposable?
    // Realtime Query
    let isLoading = BehaviorSubject<Bool>(value: true)
    let result = BehaviorSubject<[ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order]?>(value: [])
}
