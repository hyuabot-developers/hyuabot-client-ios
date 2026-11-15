//
//  SubwayRealtimeData.swift
//  hyuabot
//

import Api
import RxRelay
import RxSwift

struct SubwayCombinedRealtimeData {
    let campusBlue: SubwayRealtimePageQuery.Data.Subway?
    let campusYellow: SubwayRealtimePageQuery.Data.Subway?
    let oidoBlue: SubwayRealtimePageQuery.Data.Subway?
    let oidoYellow: SubwayRealtimePageQuery.Data.Subway?
}

@MainActor
class SubwayRealtimeData {
    static let shared = SubwayRealtimeData()
    var loadedLanguage: String?
    // Subway Realtime Data
    let realtimeData = BehaviorRelay<[SubwayRealtimePageQuery.Data.Subway]>(value: [])
    let combinedRealtimeData = BehaviorRelay<SubwayCombinedRealtimeData?>(value: nil)
    let transferUp = BehaviorRelay<[SubwayTransferItem]>(value: [])
    let transferDown = BehaviorRelay<[SubwayTransferItem]>(value: [])
    /// Loading State
    let isLoading = BehaviorRelay<Bool>(value: true)

    func prepareForLanguage(_ language: String) {
        guard loadedLanguage != language else { return }
        loadedLanguage = language
        realtimeData.accept([])
        combinedRealtimeData.accept(nil)
        transferUp.accept([])
        transferDown.accept([])
        isLoading.accept(true)
    }
}
