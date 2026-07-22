//
//  ShuttlePresenceService.swift
//  hyuabot
//

import Foundation

private struct ShuttlePresenceRequest: Encodable {
    let stopId: String
    let sessionId: String
    let platform: String
    let appVersion: String
}

private struct ShuttlePresenceResponse: Decodable {
    let viewerCount: Int?
    let visible: Bool
}

actor ShuttlePresenceService {
    static let shared = ShuttlePresenceService()

    private let endpoint = URL(string: "https://backend.hyuabot.app/api/v1/presence/shuttle")!
    private let sessionId: String = {
        let key = "shuttlePresence.anonymousInstallationId"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        let generated = UUID().uuidString.lowercased()
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }()

    func heartbeat(stopId: String) async -> Int? {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let payload = ShuttlePresenceRequest(
            stopId: stopId,
            sessionId: sessionId,
            platform: "ios",
            appVersion: appVersion
        )
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        request.httpBody = try? JSONEncoder().encode(payload)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode),
              let decoded = try? JSONDecoder().decode(ShuttlePresenceResponse.self, from: data),
              decoded.visible else { return nil }
        return decoded.viewerCount
    }
}
