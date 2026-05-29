import WidgetKit
import SwiftUI
import CoreLocation

private let shuttleQuery = """
query ShuttleWidgetQuery($after: LocalTime) {
    shuttle(input: {
        stops: [
            { name: "dormitory_o", limit: { order: 8, destination: 3 } },
            { name: "shuttlecock_o", limit: { order: 8, destination: 3 } },
            { name: "station", limit: { order: 8, destination: 3 } },
            { name: "terminal", limit: { order: 8, destination: 3 } },
            { name: "jungang_stn", limit: { order: 8, destination: 3 } },
            { name: "shuttlecock_i", limit: { order: 8, destination: 3 } }
        ],
        after: $after
    }) {
        stops {
            latitude
            longitude
            name
            timetable {
                destination {
                    destination
                    entries { time }
                }
            }
        }
    }
}
"""

// MARK: - Response Types

private struct ShuttleResponse: Decodable {
    let shuttle: ShuttleData

    struct ShuttleData: Decodable {
        let stops: [Stop]

        struct Stop: Decodable {
            let latitude: Double
            let longitude: Double
            let name: String
            let timetable: Timetable

            struct Timetable: Decodable {
                let destination: [DestinationGroup]

                struct DestinationGroup: Decodable {
                    let destination: String
                    let entries: [Entry]

                    struct Entry: Decodable {
                        let time: String
                    }
                }
            }
        }
    }
}

// MARK: - Models

struct ShuttleArrival: Identifiable {
    let id = UUID()
    let destination: String
    let time: String
}

struct ShuttleEntry: TimelineEntry {
    let date: Foundation.Date
    let stopDisplayName: String
    let arrivals: [ShuttleArrival]
    let errorState: ShuttleErrorState
}

enum ShuttleErrorState {
    case none
    case noLocation
    case noData
}

// MARK: - Helpers

private func stopDisplayName(for stopID: String) -> String {
    switch stopID {
    case "dormitory_o": return String(localized: "stop.dormitory")
    case "shuttlecock_o": return String(localized: "stop.shuttlecock")
    case "station": return String(localized: "stop.station")
    case "terminal": return String(localized: "stop.terminal")
    case "jungang_stn": return String(localized: "stop.jungang.stn")
    case "shuttlecock_i": return String(localized: "stop.shuttlecock.in")
    default: return stopID
    }
}

private func destinationDisplayName(for destination: String) -> String {
    switch destination {
    case "STATION": return String(localized: "destination.station")
    case "TERMINAL": return String(localized: "destination.terminal")
    case "CAMPUS": return String(localized: "destination.campus")
    case "JUNGANG": return String(localized: "destination.jungang")
    default: return destination
    }
}

private func formatTime(_ time: String) -> String {
    let parts = time.split(separator: ":")
    guard parts.count >= 2 else { return time }
    return "\(parts[0]):\(parts[1])"
}

// MARK: - Location Fetcher

final class WidgetLocationFetcher: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private var manager: CLLocationManager?
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    func getCurrentLocation() async -> CLLocation? {
        return await withCheckedContinuation { cont in
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
            date: .now,
            stopDisplayName: "한대앞",
            arrivals: [
                ShuttleArrival(destination: "기숙사", time: "15:30"),
                ShuttleArrival(destination: "터미널", time: "15:45"),
                ShuttleArrival(destination: "기숙사", time: "16:00"),
                ShuttleArrival(destination: "중앙역", time: "16:10")
            ],
            errorState: .none
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShuttleEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        Task {
            let entry = await fetchEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShuttleEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Foundation.Date.now)!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry() async -> ShuttleEntry {
        let locationFetcher = WidgetLocationFetcher()
        let location = await locationFetcher.getCurrentLocation()

        guard let location else {
            return ShuttleEntry(date: .now, stopDisplayName: "", arrivals: [], errorState: .noLocation)
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let currentTimeStr = timeFormatter.string(from: Foundation.Date.now)

        do {
            let response: ShuttleResponse = try await widgetGraphQL(
                query: shuttleQuery,
                variables: ["after": currentTimeStr]
            )

            let stops = response.shuttle.stops
            guard !stops.isEmpty else {
                return ShuttleEntry(date: .now, stopDisplayName: "", arrivals: [], errorState: .noData)
            }

            let nearestStop = stops.min { a, b in
                CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: location)
                < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: location)
            }

            guard let stop = nearestStop else {
                return ShuttleEntry(date: .now, stopDisplayName: "", arrivals: [], errorState: .noData)
            }

            let arrivals: [ShuttleArrival] = stop.timetable.destination
                .flatMap { group in
                    group.entries.prefix(2).map { entry in
                        ShuttleArrival(
                            destination: destinationDisplayName(for: group.destination),
                            time: formatTime(entry.time)
                        )
                    }
                }
                .sorted { $0.time < $1.time }

            return ShuttleEntry(
                date: .now,
                stopDisplayName: stopDisplayName(for: stop.name),
                arrivals: arrivals,
                errorState: .none
            )
        } catch {
            return ShuttleEntry(date: .now, stopDisplayName: "", arrivals: [], errorState: .noData)
        }
    }
}

// MARK: - Views

struct ShuttleWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ShuttleEntry

    var body: some View {
        switch family {
        case .systemSmall:
            ShuttleSmallView(entry: entry)
        case .systemMedium:
            ShuttleMediumView(entry: entry)
        case .systemLarge:
            ShuttleLargeView(entry: entry)
        default:
            ShuttleSmallView(entry: entry)
        }
    }
}

struct ShuttleSmallView: View {
    let entry: ShuttleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.green)
                    .font(.caption2)
                Text("shuttle.title")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                Spacer()
            }

            switch entry.errorState {
            case .noLocation:
                Spacer()
                Image(systemName: "location.slash")
                    .foregroundStyle(.secondary)
                Text("shuttle.no.location")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            case .noData:
                Spacer()
                Text("shuttle.no.data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            case .none:
                Text(entry.stopDisplayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Spacer(minLength: 2)

                ForEach(entry.arrivals.prefix(3)) { arrival in
                    HStack {
                        Text(arrival.destination)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text(arrival.time)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(12)
    }
}

struct ShuttleMediumView: View {
    let entry: ShuttleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline)
                Text("shuttle.title")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                if !entry.stopDisplayName.isEmpty {
                    Text("· \(entry.stopDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            switch entry.errorState {
            case .noLocation:
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "location.slash")
                            .foregroundStyle(.secondary)
                        Text("shuttle.location.required")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            case .noData:
                Text("shuttle.no.data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .none:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(entry.arrivals.prefix(6)) { arrival in
                        HStack {
                            Text(arrival.destination)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            Text(arrival.time)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(12)
    }
}

struct ShuttleLargeView: View {
    let entry: ShuttleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.green)
                Text("shuttle.title")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                if !entry.stopDisplayName.isEmpty {
                    Text("· \(entry.stopDisplayName)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.date, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            switch entry.errorState {
            case .noLocation:
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "location.slash.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("shuttle.location.required")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("shuttle.location.guide")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            case .noData:
                Spacer()
                Text("shuttle.no.data")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            case .none:
                VStack(spacing: 0) {
                    ForEach(entry.arrivals.prefix(8)) { arrival in
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.green.opacity(0.7))
                                    .font(.caption)
                                Text(arrival.destination)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            Text(arrival.time)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 6)
                        Divider()
                    }
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Widget

struct ShuttleWidget: Widget {
    let kind = "ShuttleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleProvider()) { entry in
            ShuttleWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("widget.shuttle.name")
        .description("widget.shuttle.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(
        date: .now,
        stopDisplayName: "한대앞",
        arrivals: [
            ShuttleArrival(destination: "기숙사", time: "15:30"),
            ShuttleArrival(destination: "터미널", time: "15:45"),
            ShuttleArrival(destination: "기숙사", time: "16:00")
        ],
        errorState: .none
    )
}

#Preview("Medium", as: .systemMedium) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(
        date: .now,
        stopDisplayName: "한대앞",
        arrivals: [
            ShuttleArrival(destination: "기숙사", time: "15:30"),
            ShuttleArrival(destination: "터미널", time: "15:45"),
            ShuttleArrival(destination: "기숙사", time: "16:00"),
            ShuttleArrival(destination: "중앙역", time: "16:10"),
            ShuttleArrival(destination: "기숙사", time: "16:30"),
            ShuttleArrival(destination: "터미널", time: "16:45")
        ],
        errorState: .none
    )
}

#Preview("Large", as: .systemLarge) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(
        date: .now,
        stopDisplayName: "한대앞",
        arrivals: [
            ShuttleArrival(destination: "기숙사", time: "15:30"),
            ShuttleArrival(destination: "터미널", time: "15:45"),
            ShuttleArrival(destination: "기숙사", time: "16:00"),
            ShuttleArrival(destination: "중앙역", time: "16:10"),
            ShuttleArrival(destination: "기숙사", time: "16:30"),
            ShuttleArrival(destination: "터미널", time: "16:45"),
            ShuttleArrival(destination: "기숙사", time: "17:00"),
            ShuttleArrival(destination: "중앙역", time: "17:20")
        ],
        errorState: .none
    )
}
