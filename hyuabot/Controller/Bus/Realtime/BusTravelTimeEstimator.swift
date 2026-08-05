import Api
import Foundation

/// Estimates a secondary stop's arrival time from actual departure-log history, instead of
/// naively assuming the Nth arrival at both stops is the same physical bus.
///
/// For each historical (date, vehicle) that passed both stops, the time-of-day dependent travel
/// duration is recorded; the estimate then averages only the samples close in time-of-day to the
/// arrival being estimated, so rush-hour and off-peak durations aren't blended together.
enum BusTravelTimeEstimator {
    private struct Sample {
        let primaryMinutes: Double
        let durationMinutes: Double
    }

    /// Durations further apart than this are treated as a mismatched/wrapped-route pairing, not a real trip.
    private static let maxPlausibleDurationMinutes: Double = 180
    private static let timeOfDayWindows: [Double] = [30, 60]

    static func secondaryArrivalTime(
        primaryArrivalTime: Api.LocalTime,
        primaryLogs: [BusRealtimePageQuery.Data.Bus.Log],
        secondaryLogs: [BusRealtimePageQuery.Data.Bus.Log]
    ) -> Api.LocalTime? {
        let samples = travelDurationSamples(primaryLogs: primaryLogs, secondaryLogs: secondaryLogs)
        guard !samples.isEmpty else { return nil }

        let targetMinutes = minutesSinceMidnight(primaryArrivalTime)
        for window in timeOfDayWindows {
            let nearby = samples.filter { abs($0.primaryMinutes - targetMinutes) <= window }
            guard !nearby.isEmpty else { continue }
            let averageDuration = nearby.map(\.durationMinutes).reduce(0, +) / Double(nearby.count)
            return offsetLocalTime(primaryArrivalTime, byMinutes: averageDuration)
        }
        return nil
    }

    private static func travelDurationSamples(
        primaryLogs: [BusRealtimePageQuery.Data.Bus.Log],
        secondaryLogs: [BusRealtimePageQuery.Data.Bus.Log]
    ) -> [Sample] {
        let secondaryByDate = Dictionary(grouping: secondaryLogs, by: \.date)
        var samples: [Sample] = []
        for primaryLog in primaryLogs {
            guard let sameDateSecondaryLogs = secondaryByDate[primaryLog.date] else { continue }
            let laterMatches = sameDateSecondaryLogs.filter { $0.vehicle == primaryLog.vehicle && $0.time > primaryLog.time }
            guard let matched = laterMatches.min(by: { $0.time < $1.time }) else { continue }

            let primaryMinutes = minutesSinceMidnight(primaryLog.time)
            let duration = minutesSinceMidnight(matched.time) - primaryMinutes
            guard duration > 0, duration < maxPlausibleDurationMinutes else { continue }
            samples.append(Sample(primaryMinutes: primaryMinutes, durationMinutes: duration))
        }
        return samples
    }

    private static func minutesSinceMidnight(_ localTime: Api.LocalTime) -> Double {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: localTime.toLocalTime())
        return Double((components.hour ?? 0) * 60 + (components.minute ?? 0)) + Double(components.second ?? 0) / 60
    }

    private static func offsetLocalTime(_ localTime: Api.LocalTime, byMinutes minutes: Double) -> Api.LocalTime {
        localTime.toLocalTime().addingTimeInterval(minutes * 60).toLocalTimeString()
    }
}
