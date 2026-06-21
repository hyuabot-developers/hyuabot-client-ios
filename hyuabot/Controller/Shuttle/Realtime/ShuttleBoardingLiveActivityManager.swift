import Foundation
import CoreLocation
import UIKit

#if canImport(ActivityKit)
import ActivityKit

final class ShuttleBoardingLiveActivityManager: NSObject, CLLocationManagerDelegate {
    static let shared = ShuttleBoardingLiveActivityManager()

    private var updateTasks: [String: Task<Void, Never>] = [:]
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    private override init() {
        super.init()
        locationManager.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(endExpiredActivities),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(endExpiredActivities),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    func start(context: ShuttleAlarmContext) {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard context.departureTime > Date.now else { return }
        endExpiredActivities()
        end(for: context.key)
        startLocationUpdatesIfAvailable()

        let attributes = ShuttleBoardingActivityAttributes(
            key: context.key,
            routeDisplayName: context.routeDisplayName,
            boardingStopName: context.boardingStop.name,
            departureTime: context.departureTime
        )
        let state = contentState(for: context)

        do {
            let activity: Activity<ShuttleBoardingActivityAttributes>
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: context.departureTime)
                activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            }
            scheduleUpdates(for: context, activity: activity)
        } catch {
            print("Failed to start shuttle boarding live activity: \(error)")
        }
    }

    func end(for key: String) {
        guard #available(iOS 16.1, *) else { return }
        updateTasks[key]?.cancel()
        updateTasks[key] = nil
        let activities = Activity<ShuttleBoardingActivityAttributes>.activities.filter { $0.attributes.key == key }
        for activity in activities {
            Task {
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: activity.content.state, staleDate: Date.now)
                    await activity.end(content, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
    }

    func endAll() {
        guard #available(iOS 16.1, *) else { return }
        updateTasks.values.forEach { $0.cancel() }
        updateTasks.removeAll()
        for activity in Activity<ShuttleBoardingActivityAttributes>.activities {
            Task {
                await endActivity(activity)
            }
        }
    }

    @available(iOS 16.1, *)
    private func scheduleUpdates(for context: ShuttleAlarmContext, activity: Activity<ShuttleBoardingActivityAttributes>) {
        updateTasks[context.key]?.cancel()
        updateTasks[context.key] = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let now = Date.now
                if now >= context.departureTime {
                    await self.endActivity(activity)
                    await MainActor.run {
                        self.updateTasks[context.key] = nil
                    }
                    return
                }
                let state = self.contentState(for: context)
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: state, staleDate: context.departureTime)
                    await activity.update(content)
                } else {
                    await activity.update(using: state)
                }
                let nextDate = nextUpdateDate(context: context, now: now)
                let seconds = max(nextDate.timeIntervalSince(now), 1)
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
    }

    @available(iOS 16.1, *)
    private func endActivity(_ activity: Activity<ShuttleBoardingActivityAttributes>) async {
        if #available(iOS 16.2, *) {
            let state = ShuttleBoardingActivityAttributes.ContentState(
                titleText: String(localized: "shuttle.alarm.boarding"),
                statusText: String(localized: "shuttle.alarm.boarding.live.completed"),
                dynamicIslandStatusText: String(localized: "shuttle.alarm.boarding.live.completed"),
                currentStopName: activity.attributes.boardingStopName,
                nextStopName: "",
                checkpointStopNames: [activity.attributes.boardingStopName],
                progress: 100,
                progressSegments: [100]
            )
            let content = ActivityContent(state: state, staleDate: Date.now)
            await activity.end(content, dismissalPolicy: .immediate)
        } else {
            await activity.end(dismissalPolicy: .immediate)
        }
    }

    @available(iOS 16.1, *)
    private func contentState(for context: ShuttleAlarmContext) -> ShuttleBoardingActivityAttributes.ContentState {
        let checkpointStops = context.boardingCheckpointStops
        let checkpointTimes = checkpointStops.map(\.time)
        let startStop = checkpointStops.first?.name ?? context.boardingStop.name
        let endStop = checkpointStops.last?.name ?? context.boardingStop.name
        let departure = departureText(context.departureTime)
        let checkpointStatus = checkpointStatusText(checkpointStops)
        let parts = [departure, distanceText(to: context.boardingStop), checkpointStatus].filter { !$0.isEmpty }
        let statusText = parts.joined(separator: " · ")
        let dynamicIslandStatusText = [departure, checkpointStatus].filter { !$0.isEmpty }.joined(separator: " · ")
        return ShuttleBoardingActivityAttributes.ContentState(
            titleText: String(localized: "shuttle.alarm.boarding.live.title"),
            statusText: statusText,
            dynamicIslandStatusText: dynamicIslandStatusText,
            currentStopName: startStop,
            nextStopName: endStop,
            checkpointStopNames: checkpointStops.map(\.name),
            progress: boardingProgress(context: context, checkpointTimes: checkpointTimes),
            progressSegments: checkpointProgressSegments(checkpointTimes)
        )
    }

    @available(iOS 16.1, *)
    private func nextUpdateDate(context: ShuttleAlarmContext, now: Date) -> Date {
        let checkpointDates = context.boardingCheckpointStops
            .map(\.time)
            .filter { $0 > now && $0 <= context.departureTime }
        let approachDates = checkpointDates
            .map { $0.addingTimeInterval(-60) }
            .filter { $0 > now }
        return (checkpointDates + approachDates + [now.addingTimeInterval(5), context.departureTime])
            .filter { $0 > now }
            .min() ?? context.departureTime
    }

    private func boardingProgress(context: ShuttleAlarmContext, checkpointTimes: [Date]) -> Int {
        if checkpointTimes.count >= 2 {
            return checkpointProgress(checkpointTimes)
        }
        let totalDuration = context.departureTime.timeIntervalSince(context.createdAt)
        guard totalDuration > 0 else { return 100 }
        let elapsed = Date.now.timeIntervalSince(context.createdAt).clamped(to: 0...totalDuration)
        return Int((elapsed * 100) / totalDuration).clamped(to: 0...100)
    }

    private func checkpointProgress(_ checkpointTimes: [Date]) -> Int {
        guard checkpointTimes.count >= 2,
              let start = checkpointTimes.first,
              let end = checkpointTimes.last else { return 0 }
        let totalDuration = end.timeIntervalSince(start)
        guard totalDuration > 0 else { return 0 }
        let elapsed = Date.now.timeIntervalSince(start).clamped(to: 0...totalDuration)
        return Int((elapsed * 100) / totalDuration).clamped(to: 0...100)
    }

    private func checkpointProgressSegments(_ checkpointTimes: [Date]) -> [Int] {
        guard checkpointTimes.count >= 2 else { return [100] }
        let intervals = zip(checkpointTimes, checkpointTimes.dropFirst())
            .map { max(Int($1.timeIntervalSince($0)), 1) }
        let total = intervals.reduce(0, +)
        guard total > 0 else { return [100] }

        var segments = intervals.map { max(1, ($0 * 100) / total) }
        var diff = 100 - segments.reduce(0, +)
        var index = segments.indices.last ?? 0
        while diff != 0 && !segments.isEmpty {
            let step = diff > 0 ? 1 : -1
            if segments[index] + step > 0 {
                segments[index] += step
                diff -= step
            }
            index = index == 0 ? segments.count - 1 : index - 1
        }
        return segments
    }

    private func distanceText(to stop: ShuttleAlarmStop) -> String {
        guard let currentLocation,
              let latitude = stop.latitude,
              let longitude = stop.longitude else { return "" }
        let stopLocation = CLLocation(latitude: latitude, longitude: longitude)
        let distance = Int(currentLocation.distance(from: stopLocation))
        let direction = directionText(from: currentLocation.coordinate, to: stopLocation.coordinate)
        return String(format: String(localized: "shuttle.alarm.boarding.live.direction.distance"), direction, formatDistance(distance))
    }

    private func formatDistance(_ distance: Int) -> String {
        if distance >= 1_000 {
            if distance % 1_000 == 0 {
                return "\(distance / 1_000)km"
            }
            return String(format: "%.1fkm", locale: Locale(identifier: "en_US_POSIX"), Double(distance) / 1_000)
        }
        return "\(distance)m"
    }

    private func departureText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return String(format: String(localized: "shuttle.alarm.boarding.live.departure"), formatter.string(from: date))
    }

    private func checkpointStatusText(_ checkpointStops: [ShuttleAlarmStop]) -> String {
        guard checkpointStops.count >= 2 else { return "" }
        let now = Date.now
        if let firstStop = checkpointStops.first, now < firstStop.time {
            return String(format: String(localized: "shuttle.alarm.checkpoint.waiting"), firstStop.name)
        }

        for stop in checkpointStops.dropFirst() where now < stop.time && stop.time.timeIntervalSince(now) <= 60 {
            return String(format: String(localized: "shuttle.alarm.checkpoint.approaching"), stop.name)
        }

        for stop in checkpointStops.dropLast().reversed() where stop.time <= now {
            return String(format: String(localized: "shuttle.alarm.checkpoint.departed"), stop.name)
        }

        return checkpointStops.first.map { String(format: String(localized: "shuttle.alarm.checkpoint.waiting"), $0.name) } ?? ""
    }

    private func directionText(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> String {
        let bearing = bearingDegrees(from: start, to: end)
        switch bearing {
        case ..<22.5, 337.5...:
            return String(localized: "direction.north")
        case ..<67.5:
            return String(localized: "direction.northeast")
        case ..<112.5:
            return String(localized: "direction.east")
        case ..<157.5:
            return String(localized: "direction.southeast")
        case ..<202.5:
            return String(localized: "direction.south")
        case ..<247.5:
            return String(localized: "direction.southwest")
        case ..<292.5:
            return String(localized: "direction.west")
        default:
            return String(localized: "direction.northwest")
        }
    }

    private func bearingDegrees(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLatitude = start.latitude * .pi / 180
        let startLongitude = start.longitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let endLongitude = end.longitude * .pi / 180
        let longitudeDelta = endLongitude - startLongitude
        let y = sin(longitudeDelta) * cos(endLatitude)
        let x = cos(startLatitude) * sin(endLatitude) - sin(startLatitude) * cos(endLatitude) * cos(longitudeDelta)
        let degrees = atan2(y, x) * 180 / .pi
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }

    private func startLocationUpdatesIfAvailable() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startLocationUpdatesIfAvailable()
    }

    @objc private func endExpiredActivities() {
        guard #available(iOS 16.1, *) else { return }
        for activity in Activity<ShuttleBoardingActivityAttributes>.activities where activity.attributes.departureTime <= Date.now {
            Task {
                await endActivity(activity)
            }
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
#else
final class ShuttleBoardingLiveActivityManager {
    static let shared = ShuttleBoardingLiveActivityManager()

    private init() {}

    func start(context: ShuttleAlarmContext) {}
    func end(for key: String) {}
    func endAll() {}
}
#endif
