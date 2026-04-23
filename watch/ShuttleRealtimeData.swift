import RxSwift
import Api

class ShuttleRealtimeData {
    static let shared = ShuttleRealtimeData()
    private init() {}
    var subscription: Disposable?
    // Realtime Query
    let isLoading = BehaviorSubject<Bool>(value: true)
    let result = BehaviorSubject<[ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]?>(value: [])
    let firstItem = BehaviorSubject<ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?>(value: nil)
    let secondItem = BehaviorSubject<ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?>(value: nil)
    let thirdItem = BehaviorSubject<ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?>(value: nil)
    let fourthItem = BehaviorSubject<ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?>(value: nil)
}
