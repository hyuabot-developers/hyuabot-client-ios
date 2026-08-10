import Api
import RxSwift

struct SubwayCombinedRealtimeData {
    let campusBlue: SubwayRealtimePageQuery.Data.Subway?
    let campusYellow: SubwayRealtimePageQuery.Data.Subway?
    let oidoBlue: SubwayRealtimePageQuery.Data.Subway?
    let oidoYellow: SubwayRealtimePageQuery.Data.Subway?
    let chojiSeohae: SubwayRealtimePageQuery.Data.Subway?
}

@MainActor
class SubwayRealtimeData {
    static let shared = SubwayRealtimeData()
    var loadedLanguage: String?
    // Subway Realtime Data
    let realtimeData = BehaviorSubject<[SubwayRealtimePageQuery.Data.Subway]>(value: [])
    let combinedRealtimeData = BehaviorSubject<SubwayCombinedRealtimeData?>(value: nil)
    let transferUp = BehaviorSubject<[SubwayTransferItem]>(value: [])
    let transferDown = BehaviorSubject<[SubwayTransferItem]>(value: [])
    /// Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)

    func prepareForLanguage(_ language: String) {
        guard loadedLanguage != language else { return }
        loadedLanguage = language
        realtimeData.onNext([])
        combinedRealtimeData.onNext(nil)
        transferUp.onNext([])
        transferDown.onNext([])
        isLoading.onNext(true)
    }
}
