import RxSwift
import Api

class ShuttleTimetableData {
    static let shared = ShuttleTimetableData()
    private init() {}
    // Shuttle Timetable Query
    let timetable = BehaviorSubject<[ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let weekdays = BehaviorSubject<[ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let weekends = BehaviorSubject<[ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let options = BehaviorSubject<ShuttleTimetableOptions?>(value: nil)
    let isLoading = BehaviorSubject<Bool>(value: false)
}
