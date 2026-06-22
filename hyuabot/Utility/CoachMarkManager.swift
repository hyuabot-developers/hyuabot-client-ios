import Foundation

final class CoachMarkManager {
    static let shared = CoachMarkManager()
    private init() {}

    static let currentVersion = 1

    private let initializedKey = "coachMarkInitialized"
    private let skipVersionKey = "coachMarkSkipVersion"
    private let appLaunchedKey = "appHasLaunched"
    private let pageIds = [
        "bus.realtime",
        "cafeteria",
        "calendar",
        "contact",
        "map",
        "readingroom",
        "root.more",
        "setting",
        "shuttle.realtime",
        "shuttle.timetable",
        "subway.realtime"
    ]

    // Call before appHasLaunched is written to UserDefaults
    func initialize() {
        if UserDefaults.standard.bool(forKey: initializedKey) {
            if !UserDefaults.standard.bool(forKey: appLaunchedKey) {
                UserDefaults.standard.set(0, forKey: skipVersionKey)
                UserDefaults.standard.set(true, forKey: appLaunchedKey)
                pageIds.forEach {
                    UserDefaults.standard.removeObject(forKey: pageKey($0, Self.currentVersion))
                }
            }
            UserDefaults.standard.synchronize()
            return
        }
        let isExistingUser = UserDefaults.standard.bool(forKey: appLaunchedKey)
        if isExistingUser {
            // Existing user updating to coach mark version — skip all
            UserDefaults.standard.set(Self.currentVersion, forKey: skipVersionKey)
        } else {
            // Fresh install — show all v1+ marks
            UserDefaults.standard.set(0, forKey: skipVersionKey)
            UserDefaults.standard.set(true, forKey: appLaunchedKey)
        }
        UserDefaults.standard.set(true, forKey: initializedKey)
        UserDefaults.standard.synchronize()
    }

    func shouldShowPage(_ pageId: String, version: Int = 1) -> Bool {
        initialize()
        let skip = UserDefaults.standard.integer(forKey: skipVersionKey)
        guard version > skip else { return false }
        return !UserDefaults.standard.bool(forKey: pageKey(pageId, version))
    }

    func markPageShown(_ pageId: String, version: Int = 1) {
        UserDefaults.standard.set(true, forKey: pageKey(pageId, version))
        NotificationCenter.default.post(name: .coachMarkPageShown, object: nil, userInfo: ["pageId": pageId])
    }

    func resetAll() {
        UserDefaults.standard.set(0, forKey: skipVersionKey)
        UserDefaults.standard.set(true, forKey: initializedKey)
        UserDefaults.standard.set(true, forKey: appLaunchedKey)
        pageIds.forEach {
            UserDefaults.standard.removeObject(forKey: pageKey($0, Self.currentVersion))
        }
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: .coachMarkReset, object: nil)
    }

    private func pageKey(_ pageId: String, _ version: Int) -> String {
        "coachMark.\(pageId).v\(version)"
    }
}

extension Notification.Name {
    static let coachMarkPageShown = Notification.Name("CoachMarkPageShown")
    static let coachMarkReset = Notification.Name("CoachMarkReset")
}
