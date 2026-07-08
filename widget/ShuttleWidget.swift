import Api
import Apollo
import AppIntents
import CoreLocation
import SwiftUI
import WidgetKit

// MARK: - Models

struct ShuttleDestinationGroup: Identifiable {
    let id = UUID()
    let destination: String
    let times: [String]
}

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
    case noData
}

// MARK: - Helpers

func maxTimesInWidth(_ width: CGFloat) -> Int {
    let destWidth: CGFloat = 80
    let timeWidth: CGFloat = 38
    let spacing: CGFloat = 6
    let raw = Int((width - destWidth + spacing) / (timeWidth + spacing))
    return max(1, raw - 1)
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
            date: .now,
            stopDisplayName: "한대앞",
            stopID: "station",
            groups: [
                ShuttleDestinationGroup(destination: "기숙사", times: ["15:30", "16:00", "16:30"]),
                ShuttleDestinationGroup(destination: "예술인", times: ["15:45", "16:15"]),
                ShuttleDestinationGroup(destination: "중앙역", times: ["16:10", "16:40"])
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
            return ShuttleEntry(date: .now, stopDisplayName: "", stopID: "", groups: [], errorState: .noLocation)
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let currentTimeStr = timeFormatter.string(from: Foundation.Date.now)

        do {
            let response = try await WidgetNetwork.shared
                .fetch(query: ShuttleWidgetQuery(after: GraphQLNullable(stringLiteral: currentTimeStr)))

            guard let stops = response.data?.shuttle.stops, !stops.isEmpty else {
                return ShuttleEntry(date: .now, stopDisplayName: "", stopID: "", groups: [], errorState: .noData)
            }

            let nearestStop = stops.min { a, b in
                CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: location)
                    < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: location)
            }

            guard let stop = nearestStop else {
                return ShuttleEntry(date: .now, stopDisplayName: "", stopID: "", groups: [], errorState: .noData)
            }

            func makeGroups(from timetable: ShuttleWidgetQuery.Data.Shuttle.Stop.Timetable) -> [ShuttleDestinationGroup] {
                timetable.destination.compactMap { group in
                    let times = group.entries.prefix(6).map { formatTime($0.time) }
                    guard !times.isEmpty else { return nil }
                    return ShuttleDestinationGroup(
                        destination: destinationDisplayName(for: group.destination),
                        times: Array(times)
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
                date: .now,
                stopDisplayName: displayStopName,
                stopID: stop.name,
                groups: groups,
                errorState: .none
            )
        } catch {
            return ShuttleEntry(date: .now, stopDisplayName: "", stopID: "", groups: [], errorState: .noData)
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
                    .foregroundStyle(Color("hanyangBlue"))
                    .font(.godoCaption2)
                Text("shuttle.title")
                    .font(.godoCaptionSemibold)
                    .foregroundStyle(Color("hanyangBlue"))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.godoCaption2)
                    .foregroundStyle(.tertiary)
                Button(intent: RefreshShuttleIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.godoCaption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }

            switch entry.errorState {
            case .noLocation:
                Spacer()
                Image(systemName: "location.slash")
                    .foregroundStyle(.secondary)
                Text("shuttle.no.location")
                    .font(.godoCaption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            case .noData:
                Spacer()
                Text("shuttle.no.data")
                    .font(.godoCaption2)
                    .foregroundStyle(.secondary)
                Spacer()
            case .none:
                Text(entry.stopDisplayName)
                    .font(.godoSubheadlineBold)
                    .lineLimit(1)
                Spacer(minLength: 2)

                if entry.groups.isEmpty {
                    Text("shuttle.no.data")
                        .font(.godoCaption2)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entry.groups) { group in
                        HStack {
                            Text(group.destination)
                                .font(.godoCaption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Spacer()
                            if let first = group.times.first {
                                Text(first)
                                    .font(.godoCaption2Semibold)
                                    .monospacedDigit()
                            }
                        }
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
                    .foregroundStyle(Color("hanyangBlue"))
                    .font(.godoSubheadline)
                Text("shuttle.title")
                    .font(.godoSubheadlineBold)
                    .foregroundStyle(Color("hanyangBlue"))
                if !entry.stopDisplayName.isEmpty {
                    Text("· \(entry.stopDisplayName)")
                        .font(.godoSubheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.date, style: .time)
                    .font(.godoCaption2)
                    .foregroundStyle(.tertiary)
                Button(intent: RefreshShuttleIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.godoCaption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
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
                            .font(.godoCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            case .noData:
                Text("shuttle.no.data")
                    .font(.godoCaption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .none:
                if entry.groups.isEmpty {
                    Text("shuttle.no.data")
                        .font(.godoCaption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    GeometryReader { geo in
                        let count = maxTimesInWidth(geo.size.width)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(entry.groups) { group in
                                HStack(spacing: 0) {
                                    Text(group.destination)
                                        .font(.godoCaption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: 80, alignment: .leading)
                                        .lineLimit(1)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        ForEach(group.times.prefix(count), id: \.self) { time in
                                            Text(time)
                                                .font(.godoCaptionSemibold)
                                                .monospacedDigit()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: geo.size.width, alignment: .topLeading)
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
                    .foregroundStyle(Color("hanyangBlue"))
                Text("shuttle.title")
                    .font(.godoHeadline)
                    .foregroundStyle(Color("hanyangBlue"))
                if !entry.stopDisplayName.isEmpty {
                    Text("· \(entry.stopDisplayName)")
                        .font(.godoHeadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.date, style: .time)
                    .font(.godoCaption2)
                    .foregroundStyle(.tertiary)
                Button(intent: RefreshShuttleIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.godoCaption2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
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
                        .font(.godoSubheadline)
                        .foregroundStyle(.secondary)
                    Text("shuttle.location.guide")
                        .font(.godoCaption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            case .noData:
                Spacer()
                Text("shuttle.no.data")
                    .font(.godoBody)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            case .none:
                let sorted = entry.groups
                    .flatMap { g in g.times.map { (dest: g.destination, time: $0) } }
                    .sorted { $0.time < $1.time }
                if sorted.isEmpty {
                    Spacer()
                    Text("shuttle.no.data")
                        .font(.godoBody)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(sorted.prefix(8).enumerated()), id: \.offset) { _, item in
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(Color("hanyangBlue").opacity(0.7))
                                        .font(.godoCaption)
                                    Text(item.dest)
                                        .font(.godoSubheadlineMedium)
                                }
                                Spacer()
                                Text(item.time)
                                    .font(.godoSubheadlineSemibold)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                } // else
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
                .widgetURL(entry.stopID.isEmpty ? nil : URL(string: "hyuabot://shuttle?stop=\(entry.stopID)"))
        }
        .configurationDisplayName("widget.shuttle.name")
        .description("widget.shuttle.description")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

private let previewGroups: [ShuttleDestinationGroup] = [
    ShuttleDestinationGroup(destination: "기숙사", times: ["15:30", "16:00", "16:30", "17:00", "17:30", "18:00"]),
    ShuttleDestinationGroup(destination: "예술인", times: ["15:45", "16:15", "16:45", "17:15"]),
    ShuttleDestinationGroup(destination: "중앙역", times: ["16:10", "16:40", "17:10"])
]

#Preview("Small", as: .systemSmall) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(date: .now, stopDisplayName: "한대앞", stopID: "station", groups: previewGroups, errorState: .none)
}

#Preview("Medium", as: .systemMedium) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(date: .now, stopDisplayName: "한대앞", stopID: "station", groups: previewGroups, errorState: .none)
}

#Preview("Large", as: .systemLarge) {
    ShuttleWidget()
} timeline: {
    ShuttleEntry(date: .now, stopDisplayName: "한대앞", stopID: "station", groups: previewGroups, errorState: .none)
}
