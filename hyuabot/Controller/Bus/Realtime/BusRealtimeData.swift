import RxSwift
import QueryAPI

class BusRealtimeData {
    static let shared = BusRealtimeData()
    private init() {}
    // Realtime Query
    let busRealtimeData = BehaviorSubject<[BusRealtimePageQuery.Data.Bus]>(value: [])
}
