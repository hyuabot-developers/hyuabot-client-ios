import Foundation
import CoreLocation
import UIKit

#if canImport(ActivityKit)
import ActivityKit

final class ShuttleBoardingLiveActivityManager: NSObject, CLLocationManagerDelegate {
    static let shared = ShuttleBoardingLiveActivityManager()

    private var updateTasks: [String: Task<Void, Never>] = [:]
    private var pushTokenTasks: [String: Task<Void, Never>] = [:]
    private var alightingContexts: [String: (context: ShuttleAlarmContext, destination: ShuttleAlarmStop)] = [:]
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private let alightingAlertRadius: CLLocationDistance = 300
    private let alightingGraceInterval: TimeInterval = 60

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
        let checkpointStops = context.boardingCheckpointStops

        let attributes = ShuttleBoardingActivityAttributes(
            key: context.key,
            alarmKind: "boarding",
            routeDisplayName: context.routeDisplayName,
            boardingStopName: context.boardingStop.name,
            targetStopName: context.boardingStop.name,
            departureTime: context.departureTime,
            checkpointStopNames: checkpointStops.map(\.name),
            checkpointTimes: checkpointStops.map(\.time),
            checkpointWaitingFormat: String(localized: "shuttle.alarm.checkpoint.waiting"),
            checkpointApproachingFormat: String(localized: "shuttle.alarm.checkpoint.approaching"),
            checkpointDepartedFormat: String(localized: "shuttle.alarm.checkpoint.departed")
        )
        let state = contentState(for: context)

        do {
            let activity: Activity<ShuttleBoardingActivityAttributes>
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: context.departureTime)
                activity = try Activity.request(attributes: attributes, content: content, pushType: .token)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: .token)
            }
            observeRemotePushToken(
                for: activity,
                state: state,
                createdAt: context.createdAt,
                expiresAt: context.departureTime
            )
            scheduleUpdates(for: context, activity: activity)
        } catch {
            print("Failed to start shuttle boarding live activity: \(error)")
        }
    }

    func startAlighting(context: ShuttleAlarmContext, destination: ShuttleAlarmStop) {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard destination.time > Date.now else { return }
        endExpiredActivities()
        end(for: context.key)
        alightingContexts[context.key] = (context, destination)
        startLocationUpdatesIfAvailable()
        let checkpointStops = alightingCheckpointStops(context: context, destination: destination)

        let attributes = ShuttleBoardingActivityAttributes(
            key: context.key,
            alarmKind: "alighting",
            routeDisplayName: context.routeDisplayName,
            boardingStopName: context.boardingStop.name,
            targetStopName: destination.name,
            departureTime: destination.time,
            checkpointStopNames: checkpointStops.map(\.name),
            checkpointTimes: checkpointStops.map(\.time),
            checkpointWaitingFormat: String(localized: "shuttle.alarm.checkpoint.waiting"),
            checkpointApproachingFormat: String(localized: "shuttle.alarm.checkpoint.approaching"),
            checkpointDepartedFormat: String(localized: "shuttle.alarm.checkpoint.departed")
        )
        let state = contentState(for: context, destination: destination)

        do {
            let activity: Activity<ShuttleBoardingActivityAttributes>
            if #available(iOS 16.2, *) {
                let content = ActivityContent(state: state, staleDate: destination.time.addingTimeInterval(alightingGraceInterval))
                activity = try Activity.request(attributes: attributes, content: content, pushType: .token)
            } else {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: .token)
            }
            observeRemotePushToken(
                for: activity,
                state: state,
                createdAt: context.createdAt,
                expiresAt: destination.time.addingTimeInterval(alightingGraceInterval)
            )
            scheduleAlightingUpdates(for: context, destination: destination, activity: activity)
        } catch {
            print("Failed to start shuttle alighting live activity: \(error)")
        }
    }

    func end(for key: String) {
        guard #available(iOS 16.1, *) else { return }
        updateTasks[key]?.cancel()
        updateTasks[key] = nil
        pushTokenTasks[key]?.cancel()
        pushTokenTasks[key] = nil
        alightingContexts[key] = nil
        ShuttleLiveActivityRemotePushService.shared.unregister(key: key)
        stopLocationUpdatesIfIdle()
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
        pushTokenTasks.values.forEach { $0.cancel() }
        pushTokenTasks.removeAll()
        alightingContexts.removeAll()
        stopLocationUpdatesIfIdle()
        Task {
            for activity in Activity<ShuttleBoardingActivityAttributes>.activities {
                ShuttleLiveActivityRemotePushService.shared.unregister(key: activity.attributes.key)
                await endActivity(activity)
            }
        }
    }

    @available(iOS 16.1, *)
    func endAllAndWait() async {
        updateTasks.values.forEach { $0.cancel() }
        updateTasks.removeAll()
        pushTokenTasks.values.forEach { $0.cancel() }
        pushTokenTasks.removeAll()
        alightingContexts.removeAll()
        stopLocationUpdatesIfIdle()
        for activity in Activity<ShuttleBoardingActivityAttributes>.activities {
            ShuttleLiveActivityRemotePushService.shared.unregister(key: activity.attributes.key)
            await endActivity(activity)
        }
    }

    @available(iOS 16.1, *)
    private func observeRemotePushToken(
        for activity: Activity<ShuttleBoardingActivityAttributes>,
        state: ShuttleBoardingActivityAttributes.ContentState,
        createdAt: Date,
        expiresAt: Date
    ) {
        pushTokenTasks[activity.attributes.key]?.cancel()
        pushTokenTasks[activity.attributes.key] = Task {
            for await tokenData in activity.pushTokenUpdates {
                await ShuttleLiveActivityRemotePushService.shared.register(
                    tokenData: tokenData,
                    activity: activity,
                    state: state,
                    createdAt: createdAt,
                    expiresAt: expiresAt
                )
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
                        self.pushTokenTasks[context.key]?.cancel()
                        self.pushTokenTasks[context.key] = nil
                    }
                    ShuttleLiveActivityRemotePushService.shared.unregister(key: context.key)
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
    private func scheduleAlightingUpdates(for context: ShuttleAlarmContext, destination: ShuttleAlarmStop, activity: Activity<ShuttleBoardingActivityAttributes>) {
        updateTasks[context.key]?.cancel()
        updateTasks[context.key] = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let now = Date.now
                if now >= destination.time.addingTimeInterval(self.alightingGraceInterval) || now >= destination.time {
                    await self.endActivity(activity)
                    await MainActor.run {
                        self.updateTasks[context.key] = nil
                        self.alightingContexts[context.key] = nil
                        self.pushTokenTasks[context.key]?.cancel()
                        self.pushTokenTasks[context.key] = nil
                    }
                    ShuttleLiveActivityRemotePushService.shared.unregister(key: context.key)
                    return
                }

                if let distance = self.distanceFromCurrentLocation(to: destination),
                   distance <= self.alightingAlertRadius {
                    ShuttleAlarmNotificationService.shared.fireAlightingProximityAlert(context: context, destination: destination, distance: Int(distance))
                    await self.endActivity(activity)
                    await MainActor.run {
                        self.updateTasks[context.key] = nil
                        self.alightingContexts[context.key] = nil
                        self.pushTokenTasks[context.key]?.cancel()
                        self.pushTokenTasks[context.key] = nil
                    }
                    ShuttleLiveActivityRemotePushService.shared.unregister(key: context.key)
                    return
                }

                let state = self.contentState(for: context, destination: destination)
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: state, staleDate: destination.time.addingTimeInterval(self.alightingGraceInterval))
                    await activity.update(content)
                } else {
                    await activity.update(using: state)
                }
                let nextDate = nextUpdateDate(context: context, destination: destination, now: now)
                let seconds = max(nextDate.timeIntervalSince(now), 1)
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            }
        }
    }

    @available(iOS 16.1, *)
    private func endActivity(_ activity: Activity<ShuttleBoardingActivityAttributes>) async {
        if #available(iOS 16.2, *) {
            let state = ShuttleBoardingActivityAttributes.ContentState(
                titleText: activity.attributes.alarmKind == "alighting" ? String(localized: "shuttle.alarm.alighting.live.title") : String(localized: "shuttle.alarm.boarding"),
                statusText: activity.attributes.alarmKind == "alighting" ? String(localized: "shuttle.alarm.alighting.live.completed") : String(localized: "shuttle.alarm.boarding.live.completed"),
                dynamicIslandStatusText: activity.attributes.alarmKind == "alighting" ? String(localized: "shuttle.alarm.alighting.live.completed") : String(localized: "shuttle.alarm.boarding.live.completed"),
                currentStopName: activity.attributes.alarmKind == "alighting" ? (activity.attributes.targetStopName ?? activity.attributes.boardingStopName) : activity.attributes.boardingStopName,
                nextStopName: "",
                checkpointStopNames: [activity.attributes.alarmKind == "alighting" ? (activity.attributes.targetStopName ?? activity.attributes.boardingStopName) : activity.attributes.boardingStopName],
                checkpointTimes: [],
                checkpointWaitingFormat: String(localized: "shuttle.alarm.checkpoint.waiting"),
                checkpointApproachingFormat: String(localized: "shuttle.alarm.checkpoint.approaching"),
                checkpointDepartedFormat: String(localized: "shuttle.alarm.checkpoint.departed"),
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
        let parts = [departure, distanceText(to: context.boardingStop)].filter { !$0.isEmpty }
        let statusText = parts.joined(separator: " · ")
        let dynamicIslandStatusText = departure
        return ShuttleBoardingActivityAttributes.ContentState(
            titleText: String(localized: "shuttle.alarm.boarding.live.title"),
            statusText: statusText,
            dynamicIslandStatusText: dynamicIslandStatusText,
            currentStopName: startStop,
            nextStopName: endStop,
            checkpointStopNames: checkpointStops.map(\.name),
            checkpointTimes: checkpointTimes,
            checkpointWaitingFormat: String(localized: "shuttle.alarm.checkpoint.waiting"),
            checkpointApproachingFormat: String(localized: "shuttle.alarm.checkpoint.approaching"),
            checkpointDepartedFormat: String(localized: "shuttle.alarm.checkpoint.departed"),
            progress: boardingProgress(context: context, checkpointTimes: checkpointTimes),
            progressSegments: checkpointProgressSegments(checkpointTimes)
        )
    }

    @available(iOS 16.1, *)
    private func contentState(for context: ShuttleAlarmContext, destination: ShuttleAlarmStop) -> ShuttleBoardingActivityAttributes.ContentState {
        let checkpointStops = alightingCheckpointStops(context: context, destination: destination)
        let checkpointTimes = checkpointStops.map(\.time)
        let arrival = arrivalText(destination.time)
        let distance = alightingDistanceText(to: destination)
        let statusText = [arrival, distance].filter { !$0.isEmpty }.joined(separator: " · ")
        let dynamicIslandStatusText = distance.isEmpty ? String(localized: "shuttle.alarm.alighting.tracking.short") : distance
        return ShuttleBoardingActivityAttributes.ContentState(
            titleText: String(localized: "shuttle.alarm.alighting.live.title"),
            statusText: statusText.isEmpty ? String(localized: "shuttle.alarm.alighting.preparing") : statusText,
            dynamicIslandStatusText: dynamicIslandStatusText,
            currentStopName: context.boardingStop.name,
            nextStopName: destination.name,
            checkpointStopNames: checkpointStops.map(\.name),
            checkpointTimes: checkpointTimes,
            checkpointWaitingFormat: String(localized: "shuttle.alarm.checkpoint.waiting"),
            checkpointApproachingFormat: String(localized: "shuttle.alarm.checkpoint.approaching"),
            checkpointDepartedFormat: String(localized: "shuttle.alarm.checkpoint.departed"),
            progress: checkpointTimes.count >= 2 ? checkpointProgress(checkpointTimes) : alightingProgress(distance: distanceFromCurrentLocation(to: destination)),
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

    private func nextUpdateDate(context: ShuttleAlarmContext, destination: ShuttleAlarmStop, now: Date) -> Date {
        let checkpointDates = alightingCheckpointStops(context: context, destination: destination)
            .map(\.time)
            .filter { $0 > now && $0 <= destination.time }
        let approachDates = checkpointDates
            .map { $0.addingTimeInterval(-60) }
            .filter { $0 > now }
        return (checkpointDates + approachDates + [now.addingTimeInterval(5), destination.time])
            .filter { $0 > now }
            .min() ?? destination.time
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

    private func alightingDistanceText(to stop: ShuttleAlarmStop) -> String {
        guard let distance = distanceFromCurrentLocation(to: stop) else {
            return String(localized: "shuttle.alarm.alighting.tracking")
        }
        return String(format: String(localized: "shuttle.alarm.alighting.content"), formatDistance(Int(distance)))
    }

    private func distanceFromCurrentLocation(to stop: ShuttleAlarmStop) -> CLLocationDistance? {
        guard let currentLocation,
              let latitude = stop.latitude,
              let longitude = stop.longitude else { return nil }
        let stopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return currentLocation.distance(from: stopLocation)
    }

    private func alightingCheckpointStops(context: ShuttleAlarmContext, destination: ShuttleAlarmStop) -> [ShuttleAlarmStop] {
        guard let boardingIndex = context.routeStops.firstIndex(where: { $0.id == context.boardingStop.id }),
              let destinationIndex = context.routeStops.firstIndex(where: { $0.id == destination.id }),
              boardingIndex <= destinationIndex else {
            return [context.boardingStop, destination]
        }
        var stops = Array(context.routeStops[boardingIndex...destinationIndex])
        if stops.indices.contains(0) {
            stops[0] = context.boardingStop
        }
        if let lastIndex = stops.indices.last {
            stops[lastIndex] = destination
        }
        return stops
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
        timeText(date, formatKey: "shuttle.alarm.boarding.live.departure")
    }

    private func arrivalText(_ date: Date) -> String {
        timeText(date, formatKey: "shuttle.alarm.alighting.live.arrival")
    }

    private func timeText(_ date: Date, formatKey: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm"
        return String(format: NSLocalizedString(formatKey, comment: ""), formatter.string(from: date))
    }

    private func checkpointStatusText(_ checkpointStops: [ShuttleAlarmStop]) -> String {
        guard checkpointStops.count >= 2 else {
            return checkpointStops.first.map { String(format: String(localized: "shuttle.alarm.checkpoint.waiting"), $0.name) } ?? ""
        }
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

    private func alightingCheckpointStatusText(_ checkpointStops: [ShuttleAlarmStop]) -> String {
        guard checkpointStops.count >= 2 else {
            return checkpointStops.first.map { String(format: String(localized: "shuttle.alarm.checkpoint.waiting"), $0.name) } ?? ""
        }
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

        return ""
    }

    private func alightingProgress(distance: CLLocationDistance?) -> Int {
        guard let distance else { return 0 }
        let cappedDistance = min(Int(distance), 2_000)
        return (100 - cappedDistance / 20).clamped(to: 0...100)
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
        case .authorizedAlways:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 50
            locationManager.activityType = .automotiveNavigation
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 50
            locationManager.activityType = .automotiveNavigation
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    private func stopLocationUpdatesIfIdle() {
        guard alightingContexts.isEmpty else { return }
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        updateAlightingActivitiesFromCurrentLocation()
        checkAlightingProximity()
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

    private func checkAlightingProximity() {
        guard !alightingContexts.isEmpty else { return }
        for (key, value) in alightingContexts {
            guard let distance = distanceFromCurrentLocation(to: value.destination),
                  distance <= alightingAlertRadius else { continue }
            ShuttleAlarmNotificationService.shared.fireAlightingProximityAlert(context: value.context, destination: value.destination, distance: Int(distance))
            end(for: key)
        }
    }

    private func updateAlightingActivitiesFromCurrentLocation() {
        guard #available(iOS 16.1, *), !alightingContexts.isEmpty else { return }
        Task { [weak self, alightingContexts] in
            guard let self else { return }
            for activity in Activity<ShuttleBoardingActivityAttributes>.activities where activity.attributes.alarmKind == "alighting" {
                guard let value = alightingContexts[activity.attributes.key] else { continue }
                let state = self.contentState(for: value.context, destination: value.destination)
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: state, staleDate: value.destination.time.addingTimeInterval(self.alightingGraceInterval))
                    await activity.update(content)
                } else {
                    await activity.update(using: state)
                }
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
    func startAlighting(context: ShuttleAlarmContext, destination: ShuttleAlarmStop) {}
    func end(for key: String) {}
    func endAll() {}
}
#endif
