import RxSwift
import Api

struct SubwayCombinedRealtimeData {
    let campusBlue: SubwayRealtimePageQuery.Data.Subway?
    let campusYellow: SubwayRealtimePageQuery.Data.Subway?
    let oidoBlue: SubwayRealtimePageQuery.Data.Subway?
    let oidoYellow: SubwayRealtimePageQuery.Data.Subway?
}

class SubwayRealtimeData {
    static let shared = SubwayRealtimeData()
    // Subway Realtime Data
    let realtimeData = BehaviorSubject<[SubwayRealtimePageQuery.Data.Subway]>(value: [])
    let combinedRealtimeData = BehaviorSubject<SubwayCombinedRealtimeData?>(value: nil)
    let transferUp = BehaviorSubject<[SubwayTransferItem]>(value: [])
    let transferDown = BehaviorSubject<[SubwayTransferItem]>(value: [])
    // Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
}
