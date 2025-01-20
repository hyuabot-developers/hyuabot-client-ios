import RxSwift
import QueryAPI

class SubwayTimetableData {
    static let shared = SubwayTimetableData()
    let isLoading = BehaviorSubject<Bool>(value: false)
    let subwayTimetableUp = BehaviorSubject<[SubwayTimetablePageUpQuery.Data.Subway.Timetable.Up]>(value: [])
    let subwayTimetableDown = BehaviorSubject<[SubwayTimetablePageDownQuery.Data.Subway.Timetable.Down]>(value: [])
    let subwayTimetableUpWeekdays = BehaviorSubject<[SubwayTimetablePageUpQuery.Data.Subway.Timetable.Up]>(value: [])
    let subwayTimetableUpWeekends = BehaviorSubject<[SubwayTimetablePageUpQuery.Data.Subway.Timetable.Up]>(value: [])
    let subwayTimetableDownWeekdays = BehaviorSubject<[SubwayTimetablePageDownQuery.Data.Subway.Timetable.Down]>(value: [])
    let subwayTimetableDownWeekends = BehaviorSubject<[SubwayTimetablePageDownQuery.Data.Subway.Timetable.Down]>(value: [])
    
}
