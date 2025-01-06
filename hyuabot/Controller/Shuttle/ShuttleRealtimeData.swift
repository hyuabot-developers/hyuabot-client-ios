import RxSwift
import QueryAPI

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    // Realtime Query
    let shuttleRealtimeData = BehaviorSubject<ShuttleRealtimePageQuery.Data?>(value: nil)
}
