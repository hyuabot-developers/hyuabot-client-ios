import Foundation
import WidgetKit

/// Shares the watch app's selected stop with the watch complication through the App Group.
///
/// The complication target keeps matching copies of these identifiers (see `watchWidget/ComplicationStore.swift`).
/// Keep them in sync when changing either side.
enum WatchStopStore {
    static let appGroupSuiteName = "group.net.jaram.hyuabot"
    static let selectedStopKey = "watch_recent_stop_id"
    static let nearestStopKey = "watch_nearest_stop_id"
    static let nearestCheckedAtKey = "watch_nearest_checked_at"
    static let urlScheme = "hyuabot-watch"
    private static let legacyStopKey = "watch_recent_stop_id"

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }

    /// Returns the stop the watch app last resolved or the user last picked, migrating the value from
    /// `UserDefaults.standard` on first read after the App Group was introduced.
    static func selectedStopID() -> String? {
        let defaults = sharedDefaults
        if let stopID = defaults.string(forKey: selectedStopKey) {
            return WatchShuttleStop.all.contains(where: { $0.id == stopID }) ? stopID : nil
        }
        guard let legacy = UserDefaults.standard.string(forKey: legacyStopKey),
              WatchShuttleStop.all.contains(where: { $0.id == legacy }) else { return nil }
        defaults.set(legacy, forKey: selectedStopKey)
        return legacy
    }

    /// Saves the stop and reloads complication timelines only when the selection actually changed.
    static func save(stopID: String) {
        let defaults = sharedDefaults
        guard defaults.string(forKey: selectedStopKey) != stopID else { return }
        defaults.set(stopID, forKey: selectedStopKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// The stop last found nearest to the user. nil when the last check found no stop nearby, or never ran.
    static func nearestStopID() -> String? {
        guard let stopID = sharedDefaults.string(forKey: nearestStopKey),
              WatchShuttleStop.all.contains(where: { $0.id == stopID }) else { return nil }
        return stopID
    }

    static func nearestCheckedAt() -> Date? {
        sharedDefaults.object(forKey: nearestCheckedAtKey) as? Date
    }

    /// Records the nearest stop and when it was checked, then reloads complication timelines.
    /// The reload always runs so a re-check clears a stale marker even when the stop is unchanged.
    static func saveNearest(stopID: String, at date: Date) {
        let defaults = sharedDefaults
        defaults.set(stopID, forKey: nearestStopKey)
        defaults.set(date, forKey: nearestCheckedAtKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Forgets the nearest stop so the complication falls back to the stop the user last picked.
    static func clearNearest() {
        let defaults = sharedDefaults
        guard defaults.string(forKey: nearestStopKey) != nil else { return }
        defaults.removeObject(forKey: nearestStopKey)
        defaults.removeObject(forKey: nearestCheckedAtKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func deepLink(for stopID: String) -> URL {
        URL(string: "\(urlScheme)://stop/\(stopID)")!
    }

    static func stopID(from url: URL) -> String? {
        guard url.scheme == urlScheme, url.host == "stop" else { return nil }
        let stopID = url.lastPathComponent
        return WatchShuttleStop.all.contains(where: { $0.id == stopID }) ? stopID : nil
    }
}
