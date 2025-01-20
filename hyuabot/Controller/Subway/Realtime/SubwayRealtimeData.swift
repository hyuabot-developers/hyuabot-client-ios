import RxSwift

class SubwayRealtimeData {
    static let shared = SubwayRealtimeData()
    // Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
}
