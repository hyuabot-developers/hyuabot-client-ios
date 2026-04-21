import RxSwift
import Api

class SubwayTimetableData {
    static let shared = SubwayTimetableData()
    let isLoading = BehaviorSubject<Bool>(value: false)
    let timetable = BehaviorSubject<[SubwayTimetablePageQuery.Data.Subway.Timetable]>(value: [])
    let timetableWeekdays = BehaviorSubject<[SubwayTimetablePageQuery.Data.Subway.Timetable]>(value: [])
    let timetableWeekends = BehaviorSubject<[SubwayTimetablePageQuery.Data.Subway.Timetable]>(value: [])
    
}
