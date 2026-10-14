import Foundation

/// Line label for one complication timetable row, mirroring the phone's by-order stop mapping.
///
/// The complication stop id picks the rule. `routeTag` (DH, DY, DJ, C) names the line where the stop
/// serves several lines. The trailing "S" (shuttlecock) or "D" (dormitory) suffix of `routeName` picks
/// between 셔틀콕 and 기숙사 where the tag alone does not. `routeName` is only ever read for that suffix:
/// it is never shown, and the Korean display text it may contain is never matched.
enum ShuttleLineLabel: CaseIterable {
    case station
    case terminal
    case jungang
    case circular
    case dormitory
    case shuttlecock

    /// Key into `ComplicationText`, whose table holds the Korean labels plus en/ja/zh equivalents.
    var localizationKey: String {
        switch self {
        case .station: return "stop.station"
        case .terminal: return "stop.terminal"
        case .jungang: return "stop.jungang"
        case .circular: return "route.circular"
        case .dormitory: return "stop.dormitory"
        case .shuttlecock: return "stop.shuttlecock"
        }
    }

    /// Returns nil when the phone would leave the label blank: an unknown complication stop, an unknown tag,
    /// or a row whose suffix is required but missing.
    static func resolve(complicationStopID: String, routeTag: String, routeName: String) -> ShuttleLineLabel? {
        let suffix = routeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let isShuttlecockSuffix = suffix.hasSuffix("S")
        let isDormitorySuffix = suffix.hasSuffix("D")

        switch complicationStopID {
        case "dormitory", "shuttlecock":
            switch routeTag {
            case "DH": return .station
            case "DY": return .terminal
            case "DJ": return .jungang
            case "C": return .circular
            default: return nil
            }
        case "station":
            switch routeTag {
            case "DH":
                if isShuttlecockSuffix { return .shuttlecock }
                if isDormitorySuffix { return .dormitory }
                return nil
            case "DJ": return .jungang
            case "C": return .circular
            default: return nil
            }
        case "terminal":
            if isShuttlecockSuffix { return .shuttlecock }
            if isDormitorySuffix { return .dormitory }
            return nil
        case "jungang":
            return .dormitory
        default:
            return nil
        }
    }
}
