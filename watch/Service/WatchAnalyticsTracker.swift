//
//  WatchAnalyticsTracker.swift
//  hyuabot watch
//

import Foundation

struct WatchAnalyticsEvent: Encodable {
    let event: String
    let platform: String
    let installationId: String
    let appVersion: String
    let entryPoint: String
    let stopId: String?

    static func appOpen(installationId: String, appVersion: String) -> WatchAnalyticsEvent {
        WatchAnalyticsEvent(
            event: "watch_app_open",
            platform: "watchos",
            installationId: installationId,
            appVersion: appVersion,
            entryPoint: "app",
            stopId: nil
        )
    }

    static func stopSelected(
        installationId: String,
        appVersion: String,
        stopId: String
    ) -> WatchAnalyticsEvent {
        WatchAnalyticsEvent(
            event: "watch_stop_selected",
            platform: "watchos",
            installationId: installationId,
            appVersion: appVersion,
            entryPoint: "app",
            stopId: stopId
        )
    }
}

actor WatchAnalyticsTracker {
    static let shared = WatchAnalyticsTracker()

    private let endpoint = URL(string: "https://backend.hyuabot.app/api/v1/analytics/watch/events")!
    private let session: URLSession
    private let installationId: String
    private let appVersion: String
    private var lastAppOpenAt: Date?

    init(
        session: URLSession = .shared,
        userDefaults: UserDefaults = .standard,
        bundle: Bundle = .main
    ) {
        self.session = session
        appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

        if let storedInstallationId = userDefaults.string(forKey: Self.installationIdKey) {
            installationId = storedInstallationId
        } else {
            let newInstallationId = UUID().uuidString.lowercased()
            userDefaults.set(newInstallationId, forKey: Self.installationIdKey)
            installationId = newInstallationId
        }
    }

    func trackAppOpen() async {
        let now = Date()
        if let lastAppOpenAt, now.timeIntervalSince(lastAppOpenAt) < Self.appOpenDeduplicationInterval {
            return
        }
        lastAppOpenAt = now

        await send(.appOpen(installationId: installationId, appVersion: appVersion))
    }

    func trackStopSelected(_ stopId: String) async {
        await send(
            .stopSelected(
                installationId: installationId,
                appVersion: appVersion,
                stopId: stopId
            )
        )
    }

    private func send(_ event: WatchAnalyticsEvent) async {
        guard let body = try? JSONEncoder().encode(event) else { return }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        _ = try? await session.data(for: request)
    }

    private static let installationIdKey = "watch_analytics_installation_id"
    private static let appOpenDeduplicationInterval: TimeInterval = 2
}
