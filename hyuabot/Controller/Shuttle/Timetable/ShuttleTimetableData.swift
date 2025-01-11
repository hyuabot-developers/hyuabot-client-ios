import RxSwift
import QueryAPI

class ShuttleTimetableData {
    static let shared = ShuttleTimetableData()
    private init() {}
    // Shuttle Timetable Query
    let options = BehaviorSubject<ShuttleTimetableOptions?>(value: nil)
}
