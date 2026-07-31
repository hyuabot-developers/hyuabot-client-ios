//
//  ShuttlePresenceService.swift
//  hyuabot
//

import UIKit

enum ShuttlePresenceVisualStyle {
    case low
    case medium
    case high

    init(viewerCount: Int) {
        switch viewerCount {
        case 0 ... 4:
            self = .low
        case 5 ... 14:
            self = .medium
        default:
            self = .high
        }
    }

    init(viewerCount: Int, availableSeats: Int?) {
        guard let availableSeats else {
            self.init(viewerCount: viewerCount)
            return
        }
        switch viewerCount {
        case ...max(availableSeats / 2, 0):
            self = .low
        case ...max(availableSeats, 0):
            self = .medium
        default:
            self = .high
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .low:
            UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1)
        case .medium:
            UIColor(red: 0.78, green: 0.35, blue: 0.06, alpha: 1)
        case .high:
            UIColor(red: 0.74, green: 0.12, blue: 0.15, alpha: 1)
        }
    }

    var foregroundColor: UIColor {
        switch self {
        case .low:
            .hanyangBlue
        case .medium, .high:
            .white
        }
    }
}

enum ShuttlePresenceSettings {
    private static let showStatusKey = "showShuttlePresenceStatus"

    static var showsStatus: Bool {
        get {
            guard UserDefaults.standard.object(forKey: showStatusKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: showStatusKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showStatusKey)
        }
    }
}

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

private struct ShuttlePresenceCountsResponse: Decodable {
    struct Stop: Decodable {
        let stopId: String
        let viewerCount: Int?
        let visible: Bool
    }

    let stops: [Stop]
}

actor ShuttlePresenceService {
    static let shared = ShuttlePresenceService()

    #if DEBUG
        private static let previewCountsByStopID = [
            "dormitory_o": 3,
            "shuttlecock_o": 9,
            "station": 18,
            "terminal": 27
        ]
    #endif

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
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-shuttlePresenceProxy"),
               let previewCount = Self.previewCountsByStopID[stopId]
            {
                return previewCount
            }
        #endif
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

    func viewerCounts() async -> [String: Int]? {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-shuttlePresenceProxy") {
                return Self.previewCountsByStopID
            }
        #endif
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode),
              let decoded = try? JSONDecoder().decode(ShuttlePresenceCountsResponse.self, from: data)
        else { return nil }
        return Dictionary(
            uniqueKeysWithValues: decoded.stops.compactMap { stop in
                guard stop.visible, let viewerCount = stop.viewerCount else { return nil }
                return (stop.stopId, viewerCount)
            }
        )
    }
}
