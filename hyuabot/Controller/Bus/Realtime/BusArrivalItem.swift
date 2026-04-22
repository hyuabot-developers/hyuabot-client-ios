import Api
import Foundation

struct BusArrivalItem {
    var route: String
    var item: BusRealtimePageQuery.Data.Bus.Arrival
    var convertedTime: String? {
        guard let time = item.time else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: time.toLocalTime())
        if (components.hour! < 4) {
            return String(format: "%02d:%02d", components.hour! + 24, components.minute!)
        }
        return String(format: "%02d:%02d", components.hour!, components.minute!)
    }
}

extension BusArrivalItem: Comparable {
    static func < (lhs: BusArrivalItem, rhs: BusArrivalItem) -> Bool {
        if lhs.item.isRealtime == rhs.item.isRealtime {
            if lhs.item.isRealtime && rhs.item.isRealtime {
                guard let lhsTime = lhs.item.minutes, let rhsTime = rhs.item.minutes else { return false }
                return lhsTime < rhsTime
            } else if !lhs.item.isRealtime && !rhs.item.isRealtime {
                guard let lhsTime = lhs.convertedTime, let rhsTime = rhs.convertedTime else { return false }
                return lhsTime < rhsTime
            }
        }
        return lhs.item.isRealtime && !rhs.item.isRealtime
    }
}
