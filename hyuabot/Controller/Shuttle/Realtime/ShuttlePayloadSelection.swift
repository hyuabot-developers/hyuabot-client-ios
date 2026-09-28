//
//  ShuttlePayloadSelection.swift
//  hyuabot
//

import Foundation

/// Request shape for the legacy shuttle realtime page, independent of the selected tab.
struct ShuttlePayloadSelection: Equatable {
    let byDestination: Bool
    let showBus: Bool
    let showSubway: Bool
    let subwayDestination: ShuttleSubwayTransferDestination
    let alternatives: ShuttleAlternativeDisplayMode

    var needsBus: Bool {
        byDestination && showBus
    }

    var subwayPairs: [(String, String)] {
        guard byDestination, showSubway else { return [] }
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
        return [
            (216_000_068, 216_000_383), (216_000_081, 216_000_028), (216_000_101, 216_000_028),
            (216_000_068, 216_000_379), (216_000_016, 216_000_152), (216_000_068, 216_000_138),
            (216_000_082, 216_000_077), (216_000_102, 216_000_077), (216_000_016, 216_000_074),
            (216_000_082, 217_000_140), (216_000_102, 217_000_140), (216_000_016, 217_000_264)
        ]
    }
}
