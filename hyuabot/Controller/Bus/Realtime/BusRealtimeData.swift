import RxSwift
import QueryAPI

class BusRealtimeData {
    static let shared = BusRealtimeData()
    private init() {}
    // Realtime Query
    let busRealtimeData = BehaviorSubject<[BusRealtimePageQuery.Data.Bus]?>(value: nil)
    let cityBusCampusData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let cityBusStationData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let seoulBusCampusData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let seoulBusMainGateData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let suwonBusCampusData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let suwonBusJunctionData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let otherBusAnsanData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    let otherBusGwangmyeongStationData = BehaviorSubject<[BusRealtimeItem]>(value: [])
    // Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
}
