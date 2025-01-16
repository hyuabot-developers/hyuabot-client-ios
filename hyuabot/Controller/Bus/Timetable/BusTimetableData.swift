import RxSwift
import QueryAPI

class BusTimetableData {
    static let shared = BusTimetableData()
    // Bus Timetable Query
    let timetable = BehaviorSubject<[BusTimetablePageQuery.Data.Bus.Route.Timetable]>(value: [])
    let weekdays = BehaviorSubject<[BusTimetableItem]>(value: [])
    let saturdays = BehaviorSubject<[BusTimetableItem]>(value: [])
    let sundays = BehaviorSubject<[BusTimetableItem]>(value: [])
    // Loading State
    let isLoading = BehaviorSubject<Bool>(value: false)
}
