//
//  BusStopName.swift
//  hyuabot
//

import Foundation

/// Localized display names for the stops used as GPS-widened section anchors
/// (Seoul tab sections 1 & 2, Suwon tab section 1).
enum BusStopName {
    static func title(for stopID: Int32) -> String {
        switch stopID {
        case 216_000_379: String(localized: "bus.stop.convention")
        case 216_000_381: String(localized: "bus.stop.cluster")
        case 216_000_383: String(localized: "bus.stop.dormitory")
        case 216_000_719: String(localized: "bus.stop.main_gate")
        case 216_000_070: String(localized: "bus.stop.entrance")
        case 202_000_106: String(localized: "bus.stop.suwon_station")
        case BusSeoulTargetStop.seocho.stopID: String(localized: "bus.stop.seocho")
        case BusSeoulTargetStop.gyodae.stopID: String(localized: "bus.stop.gyodae")
        case BusSeoulTargetStop.gangnam.stopID: String(localized: "bus.stop.gangnam")
        case BusSeoulTargetStop.yangjae.stopID: String(localized: "bus.stop.yangjae")
        case BusSeoulTargetStop.yangjaeForest.stopID: String(localized: "bus.stop.yangjae_forest")
        default: ""
        }
    }
}
