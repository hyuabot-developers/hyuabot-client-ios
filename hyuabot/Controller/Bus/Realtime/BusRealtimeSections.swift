//
//  BusRealtimeSections.swift
//  hyuabot
//
//  Created by hyuabot on 2026/11/10.
//

import RxSwift

struct BusRealtimeSectionSpec: Equatable {
    let stopID: Int32
    let routes: [Int32]
    let routeNames: [String]
    let stopName: String
}

@MainActor
enum BusRealtimeSections {
    static func specs(for tab: BusRealtimeType) -> [BusRealtimeSectionSpec] {
        switch tab {
        case .city:
            let stopID = (try? BusRealtimeData.shared.selectedBusStopID.value()) ?? 216_000_379
            return [spec(stopID, [216_000_068], ["10-1"]), spec(216_000_138, [216_000_068], ["10-1"])]
        case .seoul:
            let first = (try? BusRealtimeData.shared.seoulFirstSelectedStopID.value()) ?? 216_000_379
            let second = (try? BusRealtimeData.shared.seoulSecondSelectedStopID.value()) ?? 216_000_719
            return [spec(first, [216_000_061], ["3102"]), spec(second, [216_000_026, 216_000_043, 216_000_096], ["3100", "3101", "3100N"])]
        case .suwon:
            let stopID = (try? BusRealtimeData.shared.suwonSelectedStopID.value()) ?? 216_000_070
            return [spec(stopID, [216_000_104, 200_000_015], ["7070", "9090"])]
        default:
            return [spec(216_000_759, [216_000_075], ["50"]), spec(213_000_487, [216_000_075], ["50"])]
        }
    }

    static func subject(for tab: BusRealtimeType, index: Int) -> BehaviorSubject<[BusArrivalItem]>? {
        switch (tab, index) {
        case (.city, 0): return BusRealtimeData.shared.busRealtimeCityFromCampus
        case (.city, 1): return BusRealtimeData.shared.busRealtimeCityFromStation
        case (.seoul, 0): return BusRealtimeData.shared.busRealtimeSeoulFromCampus
        case (.seoul, 1): return BusRealtimeData.shared.busRealtimeGunpoFromCampus
        case (.suwon, 0): return BusRealtimeData.shared.busRealtimeSuwonFromCampus
        case (.other, 0): return BusRealtimeData.shared.busRealtimeKTXFromCampus
        case (.other, 1): return BusRealtimeData.shared.busRealtimeKTXFromStation
        default: return nil
        }
    }

    nonisolated static func destinationName(for stopID: Int32) -> String {
        switch stopID {
        case 216_000_138: String(localized: "bus.realtime.destination.sangnoksu")
        case 216_000_378: String(localized: "home.bus.stop.convention.short")
        case 216_000_048: String(localized: "bus.stop.main_gate")
        case 202_000_208: String(localized: "bus.stop.suwon_station")
        case 216_000_141: String(localized: "bus.stop.entrance")
        case 213_000_487: String(localized: "home.destination.gwangmyeong")
        case 216_000_117: String(localized: "bus.stop.ansan_park_prugio")
        default: BusStopName.title(for: stopID)
        }
    }

    static func rowLimit(for tab: BusRealtimeType) -> Int {
        tab == .suwon ? 10 : 5
    }

    private static func spec(_ stopID: Int32, _ routes: [Int32], _ routeNames: [String]) -> BusRealtimeSectionSpec {
        BusRealtimeSectionSpec(stopID: stopID, routes: routes, routeNames: routeNames, stopName: BusStopName.title(for: stopID))
    }
}
