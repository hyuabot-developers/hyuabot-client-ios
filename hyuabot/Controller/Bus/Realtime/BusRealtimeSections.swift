//
//  BusRealtimeSections.swift
//  hyuabot
//
//  Created by hyuabot on 2026/11/10.
//

struct BusRealtimeSectionSpec: Hashable {
    let stopID: Int32
    let routes: [Int32]
    let routeNames: [String]
    let stopName: String
    let destinationStopID: Int32?

    init(stopID: Int32, routes: [Int32], routeNames: [String], stopName: String, destinationStopID: Int32? = nil) {
        self.stopID = stopID
        self.routes = routes
        self.routeNames = routeNames
        self.stopName = stopName
        self.destinationStopID = destinationStopID
    }
}

@MainActor
enum BusRealtimeSections {
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
        tab == .suwon ? 7 : 3
    }
}
