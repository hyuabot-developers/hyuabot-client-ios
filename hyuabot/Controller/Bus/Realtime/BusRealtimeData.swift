import RxSwift
import Api

class BusRealtimeData {
    static let shared = BusRealtimeData()
    private init() {}
    // Realtime Query
    let busRealtimeData = BehaviorSubject<[BusRealtimePageQuery.Data.Bus]>(value: [])
    let busRealtimeCityFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeCityFromStation = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeSeoulFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeGunpoFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeSuwonFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeKTXFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeKTXFromStation = BehaviorSubject<[BusArrivalItem]>(value: [])
    let notices = BehaviorSubject<[BusRealtimePageQuery.Data.Notice.Notice]>(value: [])
    // Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
}
