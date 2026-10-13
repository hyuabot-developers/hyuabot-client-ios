import Foundation

/// App Group access for the complication. Identifiers match `watch/Service/WatchStopStore.swift`.
enum ComplicationStore {
    static let appGroupSuiteName = "group.net.jaram.hyuabot"
    static let selectedStopKey = "watch_recent_stop_id"
    /// v2 discards caches written before the shuttlecock complication stopped querying shuttlecock_i.
    static let scheduleKeyPrefix = "watch_complication_schedule_v2_"
    /// Last known schedules older than this are treated as unavailable rather than stale.
    static let maximumCacheAge: TimeInterval = 2 * 60 * 60

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }

    static func selectedStopID() -> String? {
        guard let stopID = defaults.string(forKey: selectedStopKey),
              ComplicationStops.find(stopID) != nil else { return nil }
        return stopID
    }

    static func cachedSchedule(for stopID: String) -> CachedSchedule? {
        guard let data = defaults.data(forKey: scheduleKeyPrefix + stopID) else { return nil }
        return try? JSONDecoder().decode(CachedSchedule.self, from: data)
    }

    static func save(_ schedule: CachedSchedule) {
        guard let data = try? JSONEncoder().encode(schedule) else { return }
        defaults.set(data, forKey: scheduleKeyPrefix + schedule.stopID)
    }
}

struct CachedSchedule: Codable, Equatable {
    let stopID: String
    let fetchedAt: Date
    let schedule: KnownSchedule
}
