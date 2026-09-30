//
//  RealtimeFreshness.swift
//  hyuabot
//

import Foundation

enum RealtimeFreshness {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }

    static func latestUpdate(_ values: [String?]) -> Date? {
        values.compactMap(parse).max()
    }

    static func isBusStale(_ values: [String?], now: Date) -> Bool {
        isStale(latestUpdate(values), after: 120, now: now)
    }

    static func isSubwayStale(_ values: [String?], now: Date) -> Bool {
        isStale(latestUpdate(values), after: 180, now: now)
    }

    static func ageMinutes(_ latestUpdate: Date?, now: Date) -> Int? {
        latestUpdate.map { max(0, Int(now.timeIntervalSince($0) / 60)) }
    }

    private static func isStale(_ latestUpdate: Date?, after seconds: TimeInterval, now: Date) -> Bool {
        guard let latestUpdate else { return false }
        return now.timeIntervalSince(latestUpdate) >= seconds
    }

    // swiftlint:disable:next function_parameter_count
    static func statusText(
        stationUpdates: [[String?]],
        hasArrivals: Bool,
        lastSuccessfulCheckAt: Date?,
        isLoading: Bool,
        hasError: Bool,
        isOffline: Bool,
        staleAfter seconds: TimeInterval,
        now: Date = .now
    ) -> String {
        if hasError {
            return String(localized: isOffline ? "transit.offline" : "transit.error")
        }
        if isLoading, lastSuccessfulCheckAt == nil {
            return String(localized: "transit.loading")
        }
        guard let lastSuccessfulCheckAt, hasArrivals else {
            return String(localized: "transit.empty")
        }
        let updates = stationUpdates.compactMap(latestUpdate)
        let staleUpdates = stationUpdates.filter { timestamps in
            switch seconds {
            case 120: isBusStale(timestamps, now: now)
            case 180: isSubwayStale(timestamps, now: now)
            default: isStale(latestUpdate(timestamps), after: seconds, now: now)
            }
        }.compactMap(latestUpdate)
        if let oldestStale = staleUpdates.min() {
            return String(
                format: String(localized: "transit.stale.%lld"),
                ageMinutes(oldestStale, now: now) ?? 0
            )
        }
        if updates.isEmpty {
            return String(localized: "transit.timetable")
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        return String(format: String(localized: "transit.checked.%@"), formatter.string(from: lastSuccessfulCheckAt))
    }
}
