import Foundation

#if canImport(ActivityKit)
    import ActivityKit

    @available(iOS 16.1, *)
    struct ShuttleBoardingActivityAttributes: ActivityAttributes {
        struct ContentState: Codable, Hashable {
            let titleText: String
            let statusText: String
            let dynamicIslandStatusText: String
            let currentStopName: String
            let nextStopName: String
            let checkpointStopNames: [String]
            let checkpointTimes: [Date]
            let checkpointWaitingFormat: String
            let checkpointApproachingFormat: String
            let checkpointDepartedFormat: String
            let progress: Int
            let progressSegments: [Int]
        }

        let key: String
        let alarmKind: String?
        let routeDisplayName: String
        let boardingStopName: String
        let targetStopName: String?
        let departureTime: Date
        let checkpointStopNames: [String]
        let checkpointTimes: [Date]
        let checkpointWaitingFormat: String
        let checkpointApproachingFormat: String
        let checkpointDepartedFormat: String
    }
#endif
