//
//  ShuttlePayloadSelection.swift
//  hyuabot
//

import Foundation

/// Request shape for the legacy shuttle realtime page: only the selected stop and the transfers/alternatives
/// its current display settings actually render.
struct ShuttlePayloadSelection: Equatable {
    let stop: String
    let byDestination: Bool
    let showBus: Bool
    let showSubway: Bool
    let subwayDestination: ShuttleSubwayTransferDestination
    let alternatives: ShuttleAlternativeDisplayMode

    private var outbound: Bool {
        ["dormitory_o", "shuttlecock_o"].contains(stop)
    }

    var needsBus: Bool {
        byDestination && showBus && outbound
    }

    var subwayPairs: [(String, String)] {
        guard byDestination, showSubway, outbound else { return [] }
        return switch subwayDestination {
        case .seoul: [("K449", "up"), ("K450", "up")]
        case .suwonYongin: [("K251", "up")]
        case .oido: [("K449", "down"), ("K251", "down"), ("K450", "down")]
        case .incheon: [("K449", "down"), ("K251", "down"), ("K258", "down")]
        case .sosa: [("K449", "down"), ("K251", "down"), ("S26", "up"), ("K450", "down")]
        }
    }

    var alternativePairs: [(Int32, Int32)] {
        guard alternatives != .hidden else { return [] }
        return switch stop {
        case "dormitory_o": [(216_000_068, 216_000_383), (216_000_081, 216_000_028), (216_000_101, 216_000_028)]
        case "shuttlecock_o": [(216_000_068, 216_000_379), (216_000_016, 216_000_152)]
        case "station": [(216_000_068, 216_000_138)]
        case "terminal": [(216_000_082, 216_000_077), (216_000_102, 216_000_077), (216_000_016, 216_000_074)]
        case "jungang_stn": [(216_000_082, 217_000_140), (216_000_102, 217_000_140), (216_000_016, 217_000_264)]
        default: []
        }
    }
}
