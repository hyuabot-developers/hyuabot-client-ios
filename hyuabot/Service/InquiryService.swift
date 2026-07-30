//
//  InquiryService.swift
//  hyuabot
//

import Foundation

struct InquiryThreadDTO: Codable {
    let id: String
    let status: String
    let subject: String?
    let entryScreen: String?
    let entryScreenName: String?
    let lastMessageAt: String?
    let createdAt: String
}

struct InquiryMessageDTO: Codable {
    let id: Int
    let senderType: String
    let body: String
    let readAt: String?
    let createdAt: String
}

struct InquiryMessageListDTO: Codable {
    let result: [InquiryMessageDTO]
}

struct InquiryStreamEvent: Decodable {
    let threadId: String?
}

private struct OpenThreadBody: Encodable {
    let subject: String?
    let contactEmail: String?
    let entryScreen: String?
    let entryScreenName: String?

    enum CodingKeys: String, CodingKey {
        case subject
        case contactEmail
        case entryScreen
        case entryScreenName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(subject, forKey: .subject)
        try container.encode(contactEmail, forKey: .contactEmail)
        try container.encode(entryScreen, forKey: .entryScreen)
        try container.encode(entryScreenName, forKey: .entryScreenName)
    }
}

private struct SendBody: Encodable {
    let body: String
}

actor InquiryService {
    static let shared = InquiryService()

    private let baseURL = "https://backend.hyuabot.app"
    private let installationId: String = {
        let key = "shuttlePresence.anonymousInstallationId"
        if let stored = UserDefaults.standard.string(forKey: key) {
            return stored
        }
        let generated = UUID().uuidString.lowercased()
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }()

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private func makeRequest(
        path: String,
        query: [URLQueryItem] = [],
        method: String
    ) -> URLRequest? {
        guard var components = URLComponents(string: baseURL) else { return nil }
        components.path = path
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10
        request.setValue(installationId, forHTTPHeaderField: "X-Installation-Id")
        request.setValue("ios", forHTTPHeaderField: "X-App-Platform")
        request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func decoded<T: Decodable>(_ type: T.Type, from request: URLRequest) async -> T? {
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200 ..< 300).contains(http.statusCode),
              let value = try? JSONDecoder().decode(type, from: data) else { return nil }
        return value
    }

    func openThread(
        subject: String?,
        entryScreen: String?,
        entryScreenName: String?
    ) async -> InquiryThreadDTO? {
        guard var request = makeRequest(path: "/api/v1/inquiry/threads", method: "POST") else { return nil }
        let payload = OpenThreadBody(
            subject: subject,
            contactEmail: nil,
            entryScreen: entryScreen,
            entryScreenName: entryScreenName
        )
        guard let body = try? JSONEncoder().encode(payload) else { return nil }
        request.httpBody = body
        return await decoded(InquiryThreadDTO.self, from: request)
    }

    func activeThread() async -> InquiryThreadDTO? {
        guard let request = makeRequest(path: "/api/v1/inquiry/threads/me", method: "GET") else { return nil }
        return await decoded(InquiryThreadDTO.self, from: request)
    }

    func messages(threadId: String, after: Int?) async -> [InquiryMessageDTO] {
        var query: [URLQueryItem] = []
        if let after {
            query.append(URLQueryItem(name: "after", value: String(after)))
        }
        guard let request = makeRequest(
            path: "/api/v1/inquiry/threads/\(threadId)/messages",
            query: query,
            method: "GET"
        ) else { return [] }
        guard let list = await decoded(InquiryMessageListDTO.self, from: request) else { return [] }
        return list.result
    }

    func send(threadId: String, body: String) async -> InquiryMessageDTO? {
        guard var request = makeRequest(
            path: "/api/v1/inquiry/threads/\(threadId)/messages",
            method: "POST"
        ) else { return nil }
        guard let payload = try? JSONEncoder().encode(SendBody(body: body)) else { return nil }
        request.httpBody = payload
        return await decoded(InquiryMessageDTO.self, from: request)
    }

    func markRead(threadId: String) async {
        guard let request = makeRequest(
            path: "/api/v1/inquiry/threads/\(threadId)/read",
            method: "POST"
        ) else { return }
        _ = try? await URLSession.shared.data(for: request)
    }

    func streamEvents(onEvent: @escaping @Sendable (InquiryStreamEvent) async -> Void) async {
        guard let request = makeRequest(path: "/api/v1/inquiry/stream", method: "GET"),
              let (bytes, response) = try? await URLSession.shared.bytes(for: request),
              let http = response as? HTTPURLResponse,
              (200 ..< 300).contains(http.statusCode) else { return }

        var eventType: String?
        var data: String?
        do {
            for try await line in bytes.lines {
                if line.hasPrefix("event:") {
                    eventType = line.dropFirst("event:".count).trimmingCharacters(in: .whitespaces)
                } else if line.hasPrefix("data:") {
                    data = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
                } else if line.isEmpty {
                    if eventType == "message",
                       let data,
                       let event = try? JSONDecoder().decode(InquiryStreamEvent.self, from: Data(data.utf8))
                    {
                        await onEvent(event)
                    }
                    eventType = nil
                    data = nil
                }
            }
        } catch {
            return
        }
    }
}
