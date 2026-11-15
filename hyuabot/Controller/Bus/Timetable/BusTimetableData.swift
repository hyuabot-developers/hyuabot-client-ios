//
//  BusTimetableData.swift
//  hyuabot
//

import Api
import RxRelay
import RxSwift

@MainActor
class BusTimetableData {
    static let shared = BusTimetableData()
    func publish(_ items: [BusTimetableItem]) {
        timetable.accept(items)
        isLoading.accept(false)
    }

    // Bus Timetable Query
    let timetable = BehaviorRelay<[BusTimetableItem]>(value: [])
    /// Loading State
    let isLoading = BehaviorRelay<Bool>(value: true)
}
