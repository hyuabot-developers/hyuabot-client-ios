import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class ShuttleLiveActivityRemotePushService {
    static let shared = ShuttleLiveActivityRemotePushService()

    private let endpoint = URL(string: "https://backend.hyuabot.app/api/v1/live-activity/shuttle")!
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private init() {}

    func register(
        tokenData: Data,
        activity: Activity<ShuttleBoardingActivityAttributes>,
        state: ShuttleBoardingActivityAttributes.ContentState,
        createdAt: Date,
        expiresAt: Date
    ) async {
        let requestBody = ShuttleLiveActivityRegisterRequest(
            key: activity.attributes.key,
            pushToken: tokenData.map { String(format: "%02x", $0) }.joined(),
            apnsEnvironment: apnsEnvironment,
            alarmKind: activity.attributes.alarmKind ?? "boarding",
            titleText: state.titleText,
            statusText: state.statusText,
            dynamicIslandStatusText: state.dynamicIslandStatusText,
            currentStopName: state.currentStopName,
            nextStopName: state.nextStopName,
            checkpointWaitingFormat: state.checkpointWaitingFormat,
            checkpointApproachingFormat: state.checkpointApproachingFormat,
            checkpointDepartedFormat: state.checkpointDepartedFormat,
            progressSegments: state.progressSegments,
            createdAt: createdAt,
            expiresAt: expiresAt,
            checkpoints: zip(activity.attributes.checkpointStopNames, activity.attributes.checkpointTimes).map {
                ShuttleLiveActivityCheckpointRequest(name: $0.0, time: $0.1)
            }
        )

        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(requestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print("Failed to register shuttle Live Activity push token: \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to register shuttle Live Activity push token: \(error)")
        }
    }

    func unregister(key: String) {
        let url = endpoint.appendingPathComponent(key)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: request).resume()
    }
}

private struct ShuttleLiveActivityRegisterRequest: Encodable {
    let key: String
    let pushToken: String
    let apnsEnvironment: String
    let alarmKind: String
    let titleText: String
    let statusText: String
    let dynamicIslandStatusText: String
    let currentStopName: String
    let nextStopName: String
    let checkpointWaitingFormat: String
    let checkpointApproachingFormat: String
    let checkpointDepartedFormat: String
    let progressSegments: [Int]
    let createdAt: Date
    let expiresAt: Date
    let checkpoints: [ShuttleLiveActivityCheckpointRequest]
}

private struct ShuttleLiveActivityCheckpointRequest: Encodable {
    let name: String
    let time: Date
}

private var apnsEnvironment: String {
    #if DEBUG
    "development"
    #else
    "production"
    #endif
}
#endif
