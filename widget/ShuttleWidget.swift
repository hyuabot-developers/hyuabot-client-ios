import Api
import Apollo
import AppIntents
import CoreLocation
import SwiftUI
import WidgetKit

// MARK: - Models

struct ShuttleEntry: TimelineEntry {
    let date: Foundation.Date
    let stopDisplayName: String
    let stopID: String
    let groups: [ShuttleDestinationGroup]
    let errorState: ShuttleErrorState
}

enum ShuttleErrorState {
    case none
    case noLocation
    case ended
    case error
}

// MARK: - Helpers

final class WidgetCompletion<Value>: @unchecked Sendable {
    private let completion: (Value) -> Void

    init(_ completion: @escaping (Value) -> Void) {
        self.completion = completion
    }

    func callAsFunction(_ value: Value) {
        completion(value)
    }
}

func stopDisplayName(for stopID: String) -> String {
    switch stopID {
    case "dormitory_o": String(localized: "stop.dormitory")
    case "shuttlecock_o": String(localized: "stop.shuttlecock")
    case "station": String(localized: "stop.station")
    case "terminal": String(localized: "stop.terminal")
    case "jungang_stn": String(localized: "stop.jungang.stn")
    case "shuttlecock_i": String(localized: "stop.shuttlecock.in")
    default: stopID
    }
}

func destinationDisplayName(for destination: String) -> String {
    switch destination {
    case "STATION": String(localized: "destination.station")
    case "TERMINAL": String(localized: "destination.terminal")
    case "CAMPUS": String(localized: "destination.campus")
    case "JUNGANG": String(localized: "destination.jungang")
    default: destination
    }
}

func formatTime(_ time: String) -> String {
    let parts = time.split(separator: ":")
    guard parts.count >= 2 else { return time }
    return "\(parts[0]):\(parts[1])"
}

// MARK: - Location Fetcher

final class WidgetLocationFetcher: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    func getCurrentLocation() async -> CLLocation? {
        await withCheckedContinuation { cont in
            DispatchQueue.main.async {
                self.continuation = cont
                let mgr = CLLocationManager()
                mgr.delegate = self
                mgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
                self.manager = mgr

                switch mgr.authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    mgr.requestLocation()
                case .notDetermined:
                    mgr.requestWhenInUseAuthorization()
                default:
                    self.continuation?.resume(returning: nil)
                    self.continuation = nil
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        continuation?.resume(returning: locations.first)
        continuation = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if continuation != nil {
                manager.requestLocation()
            }
        case .denied, .restricted:
            continuation?.resume(returning: nil)
            continuation = nil
        default:
            break
        }
    }
}

// MARK: - Provider

struct ShuttleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShuttleEntry {
        ShuttleEntry(
            date: ShuttleSampleData.referenceDate,
            stopDisplayName: "한대앞",
            stopID: "station",
            groups: [
                ShuttleDestinationGroup(
                    destination: "기숙사", times: ["14:03", "14:20", "14:40"],
                    destinationKey: "CAMPUS", serviceDate: ShuttleSampleData.referenceDate
                ),
                ShuttleDestinationGroup(
                    destination: "예술인", times: ["14:12", "14:35"],
                    destinationKey: "TERMINAL", serviceDate: ShuttleSampleData.referenceDate
                ),
                ShuttleDestinationGroup(
                    destination: "중앙역", times: ["14:25", "14:55"],
                    destinationKey: "JUNGANG", serviceDate: ShuttleSampleData.referenceDate
                )
            ],
            errorState: .none
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShuttleEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let completion = WidgetCompletion(completion)
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShuttleEntry>) -> Void) {
        let completion = WidgetCompletion(completion)
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Foundation.Date.now)
                ?? Foundation.Date.now.addingTimeInterval(300)
            let entries = ShuttleDepartureMath.minuteTimelineDates(from: entry.date, count: 5).map {
                ShuttleEntry(
                    date: $0,
                    stopDisplayName: entry.stopDisplayName,
                    stopID: entry.stopID,
                    groups: entry.groups,
                    errorState: entry.errorState
                )
            }
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry() async -> ShuttleEntry {
        let fetchedAt = Foundation.Date.now
        let locationFetcher = WidgetLocationFetcher()
        let location = await locationFetcher.getCurrentLocation()

        guard let location else {
            return ShuttleEntry(date: fetchedAt, stopDisplayName: "", stopID: "", groups: [], errorState: .noLocation)
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let currentTimeStr = timeFormatter.string(from: fetchedAt)

        do {
            let response = try await WidgetNetwork.shared
                .fetch(query: ShuttleWidgetQuery(after: GraphQLNullable(stringLiteral: currentTimeStr)))

            guard let stops = response.data?.shuttle.stops, !stops.isEmpty else {
                return ShuttleEntry(date: fetchedAt, stopDisplayName: "", stopID: "", groups: [], errorState: .error)
            }

            let nearestStop = stops.min { a, b in
                CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: location)
                    < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: location)
            }

            guard let stop = nearestStop else {
                return ShuttleEntry(date: fetchedAt, stopDisplayName: "", stopID: "", groups: [], errorState: .error)
            }

            func makeGroups(from timetable: ShuttleWidgetQuery.Data.Shuttle.Stop.Timetable) -> [ShuttleDestinationGroup] {
                timetable.destination.compactMap { group in
                    let times = group.entries.prefix(6).map { formatTime($0.time) }
                    guard !times.isEmpty else { return nil }
                    return ShuttleDestinationGroup(
                        destination: destinationDisplayName(for: group.destination),
                        times: Array(times),
                        destinationKey: group.destination,
                        serviceDate: fetchedAt
                    )
                }
            }

            var groups = makeGroups(from: stop.timetable)
            var displayStopName = stopDisplayName(for: stop.name)

            if stop.name == "shuttlecock_o" || stop.name == "shuttlecock_i" {
                let companionName = stop.name == "shuttlecock_o" ? "shuttlecock_i" : "shuttlecock_o"
                if let companion = stops.first(where: { $0.name == companionName }) {
                    groups += makeGroups(from: companion.timetable)
                }
                displayStopName = String(localized: "stop.shuttlecock")
            }

            return ShuttleEntry(
                date: fetchedAt,
                stopDisplayName: displayStopName,
                stopID: stop.name,
                groups: groups,
                errorState: groups.isEmpty ? .ended : .none
            )
        } catch {
            return ShuttleEntry(date: fetchedAt, stopDisplayName: "", stopID: "", groups: [], errorState: .error)
        }
    }
}

// MARK: - Views

struct ShuttleWidget: Widget {
    let kind = "ShuttleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            ShuttleWidgetView(entry: entry)
                .containerBackground(HYUWidgetColor.background, for: .widget)
                .widgetURL(entry.stopID.isEmpty ? nil : URL(string: "hyuabot://shuttle?stop=\(entry.stopID)"))
        }
        .configurationDisplayName("widget.shuttle.name")
        .description("widget.shuttle.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

private let previewGroups: [ShuttleDestinationGroup] = [
    ShuttleDestinationGroup(
        destination: "기숙사", times: ["14:03", "14:20", "14:40", "15:00", "15:20", "15:40"],
        destinationKey: "CAMPUS", serviceDate: ShuttleSampleData.referenceDate
    ),
    ShuttleDestinationGroup(
        destination: "예술인", times: ["14:12", "14:35", "14:58", "15:21"],
        destinationKey: "TERMINAL", serviceDate: ShuttleSampleData.referenceDate
    ),
    ShuttleDestinationGroup(
        destination: "중앙역", times: ["14:25", "14:55", "15:25"],
        destinationKey: "JUNGANG", serviceDate: ShuttleSampleData.referenceDate
    )
]

#Preview("Small", as: .systemSmall) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(date: ShuttleSampleData.referenceDate, stopDisplayName: "한대앞", stopID: "station", groups: previewGroups, errorState: .none)
}

#Preview("Medium", as: .systemMedium) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(date: ShuttleSampleData.referenceDate, stopDisplayName: "한대앞", stopID: "station", groups: previewGroups, errorState: .none)
}

#Preview("Large", as: .systemLarge) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(date: ShuttleSampleData.referenceDate, stopDisplayName: "한대앞", stopID: "station", groups: previewGroups, errorState: .none)
}
