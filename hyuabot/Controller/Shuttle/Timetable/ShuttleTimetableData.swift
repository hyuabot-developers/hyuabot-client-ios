import RxSwift
import QueryAPI

class ShuttleTimetableData {
    static let shared = ShuttleTimetableData()
    private init() {}
    // Shuttle Timetable Query
    let timetable = BehaviorSubject<[ShuttleTimetablePageQuery.Data.Shuttle.Timetable]>(value: [])
    let weekdays = BehaviorSubject<[ShuttleTimetablePageQuery.Data.Shuttle.Timetable]>(value: [])
    let weekends = BehaviorSubject<[ShuttleTimetablePageQuery.Data.Shuttle.Timetable]>(value: [])
    let options = BehaviorSubject<ShuttleTimetableOptions?>(value: nil)
    let isLoading = BehaviorSubject<Bool>(value: false)
}
