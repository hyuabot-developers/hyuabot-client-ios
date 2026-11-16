//
//  BusRealtimeData.swift
//  hyuabot
//

import Api
import Foundation
import RxRelay
import RxSwift

@MainActor
class BusRealtimeData {
    static let shared = BusRealtimeData()
    private init() {}
    /// Realtime Query
    let busRealtimeData = BehaviorRelay<[BusRealtimePageQuery.Data.Bus]>(value: [])
    let busLocationGroup = BehaviorRelay<BusLocationGroup?>(value: nil)
    let busRealtimeSectionItems = BehaviorRelay<[BusRealtimeSectionSpec: [BusArrivalItem]]>(value: [:])
    let notices = BehaviorRelay<[BusRealtimePageQuery.Data.Notice.Notice]>(value: [])
    /// Loading State
    let isLoading = BehaviorRelay<Bool>(value: true)
    /// Whether to show the secondary arrival-time suffix ("▶ HH:mm 도착 예정")
    let showSecondaryEta = BehaviorRelay<Bool>(value: BusRealtimeDisplaySettings.showsSecondaryEta)
    /// Seoul-bound destination used for the secondary ETA when the primary section is on campus
    let seoulTargetStop = BehaviorRelay<BusSeoulTargetStop>(value: BusRealtimeDisplaySettings.seoulTargetStop)
}

/// Keep one row per route and arrival minute, preferring API arrivals to historical templates.
enum BusArrivalDeduplication {
    private struct Key: Hashable {
        let route: String
        let minute: Int
    }

    static func uniqueItems(_ items: [BusArrivalItem], now: Foundation.Date = .now) -> [BusArrivalItem] {
        var result: [BusArrivalItem] = []
        var indices: [Key: Int] = [:]
        for item in items {
            let time = (item.scheduledTime ?? item.item.arrivalTime)?.toLocalTimeOrNil(on: now)
                ?? (item.item.isRealtime ? item.item.minutes.map { now.addingTimeInterval(Double($0) * 60) } : nil)
            guard let time else {
                result.append(item)
                continue
            }
            let key = Key(route: item.route, minute: BusDisplayLogic.serviceMinutes(of: time, calendar: .current))
            if let index = indices[key] {
                if priority(item) > priority(result[index]) { result[index] = item }
            } else {
                indices[key] = result.count
                result.append(item)
            }
        }
        return result
    }

    private static func priority(_ item: BusArrivalItem) -> Int {
        item.scheduledTime != nil ? 0 : (item.item.isRealtime ? 2 : 1)
    }
}
