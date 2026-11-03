//
//  WatchDestination.swift
//  hyuabot
//

import Foundation

enum WatchDestination {
    /// Inbound dormitory stop name in a trip.
    static let dormitoryInbound = "dormitory_i"

    /// Inbound shuttlecock stop name in a trip.
    static let shuttlecockInbound = "shuttlecock_i"

    /// Stop names after the first occurrence of `currentStop` in `tripStops`; [] when `currentStop` is absent or last.
    static func stopsAfter(_ currentStop: String, in tripStops: [String]) -> [String] {
        guard let index = tripStops.firstIndex(of: currentStop) else { return [] }
        return Array(tripStops[(index + 1)...])
    }

    /// Reports whether the row represents a real departure.
    static func isDeparture(queryStop: String, stopsAfterCurrent: [String]) -> Bool {
        queryStop != shuttlecockInbound || stopsAfterCurrent.contains(dormitoryInbound)
    }

    /// WatchLocalization key for the row's destination label, or nil to fall back to order.route.name.
    static func labelKey(stopID: String, queryStop: String, tag: String, stopsAfterCurrent: [String]) -> String? {
        let toDormitory = stopsAfterCurrent.contains(dormitoryInbound)
        let destination = toDormitory ? "stop.dormitory" : "stop.shuttlecock"

        switch stopID {
        case "dormitory":
            switch tag {
            case "DH": return "stop.station"
            case "DY": return "stop.terminal"
            case "DJ": return "stop.jungang"
            case "C": return "route.circular"
            default: return nil
            }
        case "shuttlecock":
            if queryStop == shuttlecockInbound { return "stop.dormitory" }
            switch tag {
            case "DH": return "stop.station"
            case "DY": return "stop.terminal"
            case "DJ": return "stop.jungang"
            case "C": return "route.circular"
            default: return nil
            }
        case "station":
            switch tag {
            case "C": return "route.circular"
            case "DJ": return "stop.jungang"
            case "DH": return destination
            default: return nil
            }
        case "terminal":
            return destination
        case "jungang":
            return "stop.dormitory"
        default:
            return "route.direct"
        }
    }
}
