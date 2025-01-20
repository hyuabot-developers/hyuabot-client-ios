import RxSwift
import QueryAPI

class SubwayRealtimeData {
    static let shared = SubwayRealtimeData()
    // Subway Realtime Data
    let realtimeData = BehaviorSubject<[SubwayRealtimePageQuery.Data.Subway]>(value: [])
    let line4Up = BehaviorSubject<[SubwayRealtimeItem]>(value: [])
    let line4Down = BehaviorSubject<[SubwayRealtimeItem]>(value: [])
    let lineSuinUp = BehaviorSubject<[SubwayRealtimeItem]>(value: [])
    let lineSuinDown = BehaviorSubject<[SubwayRealtimeItem]>(value: [])
    // Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
}
