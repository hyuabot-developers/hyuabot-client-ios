//
//  BusStopName.swift
//  hyuabot
//

import Foundation

/// Localized display names for every bus section stop.
enum BusStopName {
    static func title(for stopID: Int32) -> String {
        switch stopID {
        case 216_000_138: String(localized: "bus.stop.sangnoksu_exit3")
        case 216_000_759: String(localized: "bus.stop.ansan_park_prugio")
        case 213_000_487: String(localized: "bus.stop.ktx_gwangmyeong_exit1")
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
        case 226_000_038: String(localized: "bus.stop.uiwang_tollgate")
        case 216_000_074: String(localized: "bus.stop.seongeo_park_terminal")
        case 216_000_077: String(localized: "bus.stop.ansan_bus_terminal")
        case 217_000_264: String(localized: "bus.stop.jungang_exit2")
        case 217_000_140: String(localized: "bus.stop.jungang_exit1")
        case 216_000_152: String(localized: "bus.stop.seongan_gil")
        case 216_000_722: String(localized: "bus.stop.handae_exit2")
        case 216_000_690, 216_000_691: String(localized: "bus.stop.daengigol")
        case 216_000_028: String(localized: "bus.stop.gyeonggi_technopark")
        default: ""
        }
    }
}
