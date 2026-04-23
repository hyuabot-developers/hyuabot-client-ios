import Api
import Foundation

struct BusTimetableItem {
    let route: String
    let weekdays: String
    let time: Foundation.Date
    var convertedTime: String? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        if (components.hour! < 4) {
            return String(format: "%02d:%02d", components.hour! + 24, components.minute!)
        }
        return String(format: "%02d:%02d", components.hour!, components.minute!)
    }
}

extension BusTimetableItem: Comparable {
    static func < (lhs: BusTimetableItem, rhs: BusTimetableItem) -> Bool {
        guard let lhsTime = lhs.convertedTime, let rhsTime = rhs.convertedTime else { return false }
        return lhsTime < rhsTime
    }
}
