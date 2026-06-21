import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct ShuttleBoardingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let titleText: String
        let statusText: String
        let dynamicIslandStatusText: String
        let currentStopName: String
        let nextStopName: String
        let checkpointStopNames: [String]
        let progress: Int
        let progressSegments: [Int]
    }

    let key: String
    let routeDisplayName: String
    let boardingStopName: String
    let departureTime: Date
}
#endif
