//
//  ShuttleTimetableData.swift
//  hyuabot
//

import Api
import RxRelay
import RxSwift

@MainActor
class ShuttleTimetableData {
    static let shared = ShuttleTimetableData()
    private init() {}
    // Shuttle Timetable Query
    let timetable = BehaviorRelay<[ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let weekdays = BehaviorRelay<[ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let weekends = BehaviorRelay<[ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]>(value: [])
    let options = BehaviorRelay<ShuttleTimetableOptions?>(value: nil)
    let isLoading = BehaviorRelay<Bool>(value: false)
}
