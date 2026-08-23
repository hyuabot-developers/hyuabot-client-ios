import Api
import Foundation

struct BusArrivalItem {
    var route: String
    var item: BusRealtimePageQuery.Data.Bus.Arrival
    var secondaryArrivalTime: Api.LocalTime?
    var scheduledTime: Api.LocalTime? = nil
    var convertedTime: String? {
        guard let time = scheduledTime ?? item.arrivalTime else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: time.toLocalTime())
        if components.hour! < 4 {
            return String(format: "%02d:%02d", components.hour! + 24, components.minute!)
        }
        return String(format: "%02d:%02d", components.hour!, components.minute!)
    }

    var secondaryConvertedTime: String? {
        guard let time = secondaryArrivalTime else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: time.toLocalTime())
        return String(format: "%02d:%02d", components.hour!, components.minute!)
    }
}

extension BusArrivalItem: Comparable {
    static func < (lhs: BusArrivalItem, rhs: BusArrivalItem) -> Bool {
        guard let lhsMinutes = lhs.remainingMinutes, let rhsMinutes = rhs.remainingMinutes else {
            return lhs.item.isRealtime && !rhs.item.isRealtime
        }
        return lhsMinutes < rhsMinutes
    }

    /// Minutes from now until arrival, computed the same way regardless of whether the estimate came
    /// from live GPS (`minutes`) or a historical-log/timetable clock time (`arrivalTime`), so merging
    /// realtime and scheduled entries from multiple routes (e.g. Suwon's 7070/9090) sorts chronologically
    /// instead of grouping all realtime entries before all scheduled ones.
    private var remainingMinutes: Double? {
        if let scheduledTime {
            let arrival = scheduledTime.toLocalTime()
            let now = Foundation.Date()
            func serviceSeconds(_ date: Foundation.Date) -> Int {
                let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
                let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
                return seconds < 4 * 3600 ? seconds + 86400 : seconds
            }
            return Double(serviceSeconds(arrival) - serviceSeconds(now)) / 60
        }
        if item.isRealtime {
            guard let minutes = item.minutes else { return nil }
            return Double(minutes)
        }
        guard let arrivalTime = item.arrivalTime else { return nil }
        let arrival = arrivalTime.toLocalTime()
        let now = Foundation.Date()
        func serviceSeconds(_ date: Foundation.Date) -> Int {
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            let seconds = (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
            return seconds < 4 * 3600 ? seconds + 86400 : seconds
        }
        return Double(serviceSeconds(arrival) - serviceSeconds(now)) / 60
    }
}
