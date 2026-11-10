//
//  BusTimetableData.swift
//  hyuabot
//

import Api
import RxSwift

@MainActor
class BusTimetableData {
    static let shared = BusTimetableData()
    func publish(_ items: [BusTimetableItem]) {
        timetable.onNext(items)
        isLoading.onNext(false)
    }

    // Bus Timetable Query
    let timetable = BehaviorSubject<[BusTimetableItem]>(value: [])
    /// Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
}
