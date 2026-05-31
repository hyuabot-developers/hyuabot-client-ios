import WidgetKit
import SwiftUI
import AppIntents
import CoreLocation

// MARK: - Shared Transfer Badge (used by ShuttleWidget too)

struct TransferBadge: View {
    let stopID: String

    var body: some View {
        if let info = transferInfo(for: stopID) {
            HStack(spacing: 3) {
                Image(systemName: info.icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(info.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func transferInfo(for stopID: String) -> (icon: String, label: String)? {
        switch stopID {
        case "dormitory_o", "shuttlecock_o":
            return ("arrow.triangle.swap", String(localized: "transfer.badge.all"))
        case "station", "jungang_stn":
            return ("tram.fill", String(localized: "transfer.badge.subway"))
        case "terminal":
            return ("bus.doubledecker.fill", String(localized: "transfer.badge.bus50"))
        default:
            return nil
        }
    }
}

// MARK: - Transit Arrival Model

struct TransitEntry: Identifiable {
    let id = UUID()
    let terminal: String
    let minutes: Int
}

struct TransitArrival: Identifiable {
    let id = UUID()
    let name: String
    let colorKey: String
    let upEntries: [TransitEntry]
    let downEntries: [TransitEntry]

    var isSubway: Bool { !downEntries.isEmpty }
}

// MARK: - Transfer Entry

struct TransferEntry: TimelineEntry {
    let date: Foundation.Date
    let stopDisplayName: String
    let stopID: String
    let shuttleGroups: [ShuttleDestinationGroup]
    let transitArrivals: [TransitArrival]
    let errorState: ShuttleErrorState
}

// MARK: - Response Types

private struct SubwayTransferResponse: Decodable {
    let subway: [Station]
    struct Station: Decodable {
        let stationID: String
        let arrival: [ArrivalGroup]
        struct ArrivalGroup: Decodable {
            let direction: String
            let entries: [Entry]
            struct Entry: Decodable {
                let minutes: Int
                let terminal: Terminal
                struct Terminal: Decodable { let stationID: String; let name: String }
            }
        }
    }
}

private struct BusTransferResponse: Decodable {
    let bus: [BusRoute]
    struct BusRoute: Decodable {
        let route: Route
        let arrival: [Arrival]
        struct Route: Decodable { let seq: Int; let name: String }
        struct Arrival: Decodable {
            let minutes: Int?
            let stops: Int?
        }
    }
}

// MARK: - Queries

private let dormitorySubwayQuery = """
query($weekday: String!) {
    subway(input: { keys: [
        { stationID: "K449", direction: ["up", "down"], weekdays: [$weekday], limit: 1 },
        { stationID: "K251", direction: ["up", "down"], weekdays: [$weekday], limit: 1 }
    ]}) { stationID arrival { direction entries { minutes terminal { stationID name } } } }
}
"""

private let dormitoryBusQuery = """
query { bus(input: [{ route: 200000015, stop: 216000070, limit: 2 }]) { route { seq name } arrival { minutes stops } } }
"""

private let terminalBusQuery = """
query { bus(input: [{ route: 216000104, stop: 216000117, limit: 2 }]) { route { seq name } arrival { minutes stops } } }
"""

private func boundLabel(stationID: String, fallback: String) -> String {
    let nameKey = "subway.station." + stationID.lowercased()
    let localizedName = String(localized: LocalizedStringResource(stringLiteral: nameKey))
    let stationName = (localizedName == nameKey) ? fallback : localizedName
    return String(format: String(localized: "transit.terminal.bound"), stationName)
}

private let subwayLineMap: [String: (nameKey: String, colorKey: String)] = [
    "K449": ("subway.line4", "line4"),
    "K251": ("subway.suin",  "suin")
]

// MARK: - Provider

struct TransferProvider: TimelineProvider {
    func placeholder(in context: Context) -> TransferEntry {
        TransferEntry(
            date: .now,
            stopDisplayName: "기숙사",
            stopID: "dormitory_o",
            shuttleGroups: [
                ShuttleDestinationGroup(destination: "한대앞", times: ["15:30", "16:00"]),
                ShuttleDestinationGroup(destination: "예술인", times: ["15:45"])
            ],
            transitArrivals: [
                TransitArrival(name: "4호선", colorKey: "line4", upEntries: [TransitEntry(terminal: "당고개", minutes: 3)], downEntries: [TransitEntry(terminal: "오이도", minutes: 12)]),
                TransitArrival(name: "수인선", colorKey: "suin", upEntries: [TransitEntry(terminal: "수원", minutes: 7)], downEntries: [TransitEntry(terminal: "인천", minutes: 22)]),
                TransitArrival(name: "50번(KTX광명)", colorKey: "bus", upEntries: [TransitEntry(terminal: "", minutes: 8), TransitEntry(terminal: "", minutes: 31)], downEntries: [])
            ],
            errorState: .none
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TransferEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { completion(await fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransferEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let next = Calendar.current.date(byAdding: .minute, value: 5, to: Foundation.Date.now)!
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> TransferEntry {
        let fetcher = WidgetLocationFetcher()
        guard let location = await fetcher.getCurrentLocation() else {
            return TransferEntry(date: .now, stopDisplayName: "", stopID: "", shuttleGroups: [], transitArrivals: [], errorState: .noLocation)
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let currentTimeStr = timeFormatter.string(from: Foundation.Date.now)

        do {
            let shuttleResp: ShuttleWidgetResponse = try await widgetGraphQL(
                query: shuttleQuery,
                variables: ["after": currentTimeStr]
            )
            let stops = shuttleResp.shuttle.stops
            guard !stops.isEmpty else {
                return TransferEntry(date: .now, stopDisplayName: "", stopID: "", shuttleGroups: [], transitArrivals: [], errorState: .noData)
            }

            let nearestStop = stops.min {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: location)
                < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: location)
            }!

            func makeShuttleGroups(_ timetable: ShuttleWidgetResponse.Shuttle.Stop.Timetable) -> [ShuttleDestinationGroup] {
                timetable.destination.compactMap { g in
                    let times = g.entries.prefix(4).map { formatTime($0.time) }
                    guard !times.isEmpty else { return nil }
                    return ShuttleDestinationGroup(destination: destinationDisplayName(for: g.destination), times: Array(times))
                }
            }

            var shuttleGroups = makeShuttleGroups(nearestStop.timetable)
            var displayName = stopDisplayName(for: nearestStop.name)
            var stopID = nearestStop.name

            if nearestStop.name == "shuttlecock_o" || nearestStop.name == "shuttlecock_i" {
                let companion = nearestStop.name == "shuttlecock_o" ? "shuttlecock_i" : "shuttlecock_o"
                if let other = stops.first(where: { $0.name == companion }) {
                    shuttleGroups += makeShuttleGroups(other.timetable)
                }
                displayName = String(localized: "stop.shuttlecock")
                stopID = nearestStop.name
            }

            let weekday = widgetWeekday()
            let transitArrivals = await fetchTransit(for: stopID, weekday: weekday)

            return TransferEntry(
                date: .now,
                stopDisplayName: displayName,
                stopID: stopID,
                shuttleGroups: shuttleGroups,
                transitArrivals: transitArrivals,
                errorState: .none
            )
        } catch {
            return TransferEntry(date: .now, stopDisplayName: "", stopID: "", shuttleGroups: [], transitArrivals: [], errorState: .noData)
        }
    }

    private func fetchTransit(for stopID: String, weekday: String) async -> [TransitArrival] {
        switch stopID {
        case "dormitory_o", "shuttlecock_o", "shuttlecock_i":
            async let subwayTask = fetchSubway(weekday: weekday)
            async let busTask = fetchDormBus()
            let (subway, bus) = await (subwayTask, busTask)
            return subway + bus
        case "terminal":
            return await fetchTerminalBus()
        case "station", "jungang_stn":
            return []  // 미 표출
        default:
            return []
        }
    }

    private func fetchSubway(weekday: String) async -> [TransitArrival] {
        guard let data: SubwayTransferResponse = try? await widgetGraphQL(
            query: dormitorySubwayQuery, variables: ["weekday": weekday]
        ) else { return [] }

        return data.subway.compactMap { station -> TransitArrival? in
            let info = subwayLineMap[station.stationID] ?? ("subway.line4", "line4")
            let name = String(localized: LocalizedStringResource(stringLiteral: info.nameKey))
            let up = station.arrival.first(where: { $0.direction == "up" })?.entries.prefix(1)
                .map { TransitEntry(terminal: boundLabel(stationID: $0.terminal.stationID, fallback: $0.terminal.name), minutes: $0.minutes) } ?? []
            let down = station.arrival.first(where: { $0.direction == "down" })?.entries.prefix(1)
                .map { TransitEntry(terminal: boundLabel(stationID: $0.terminal.stationID, fallback: $0.terminal.name), minutes: $0.minutes) } ?? []
            guard !up.isEmpty || !down.isEmpty else { return nil }
            return TransitArrival(name: name, colorKey: info.colorKey, upEntries: Array(up), downEntries: Array(down))
        }
    }

    private func fetchDormBus() async -> [TransitArrival] {
        guard let data: BusTransferResponse = try? await widgetGraphQL(
            query: dormitoryBusQuery, variables: [:]
        ) else { return [] }
        let entries = data.bus.flatMap { $0.arrival }.prefix(2).compactMap { arrival -> TransitEntry? in
            guard let m = arrival.minutes else { return nil }
            let stopsStr = (arrival.stops ?? 0) > 0
                ? String(format: String(localized: "transit.stops.format"), arrival.stops!)
                : ""
            return TransitEntry(terminal: stopsStr, minutes: m)
        }
        guard !entries.isEmpty else { return [] }
        return [TransitArrival(name: String(localized: "bus.to.kwangmyeong"), colorKey: "bus", upEntries: Array(entries), downEntries: [])]
    }

    private func fetchTerminalBus() async -> [TransitArrival] {
        guard let data: BusTransferResponse = try? await widgetGraphQL(
            query: terminalBusQuery, variables: [:]
        ) else { return [] }
        let entries = data.bus.flatMap { $0.arrival }.prefix(2).compactMap { arrival -> TransitEntry? in
            guard let m = arrival.minutes else { return nil }
            let stopsStr = (arrival.stops ?? 0) > 0
                ? String(format: String(localized: "transit.stops.format"), arrival.stops!)
                : ""
            return TransitEntry(terminal: stopsStr, minutes: m)
        }
        guard !entries.isEmpty else { return [] }
        return [TransitArrival(name: String(localized: "bus.to.ansan"), colorKey: "bus", upEntries: Array(entries), downEntries: [])]
    }
}

// MARK: - Response type reuse from ShuttleWidget

private struct ShuttleWidgetResponse: Decodable {
    let shuttle: Shuttle
    struct Shuttle: Decodable {
        let stops: [Stop]
        struct Stop: Decodable {
            let latitude: Double
            let longitude: Double
            let name: String
            let timetable: Timetable
            struct Timetable: Decodable {
                let destination: [DestGroup]
                struct DestGroup: Decodable {
                    let destination: String
                    let entries: [Entry]
                    struct Entry: Decodable { let time: String }
                }
            }
        }
    }
}


// MARK: - Views

struct TransferWidgetView: View {
    let entry: TransferEntry

    var body: some View {
        TransferLargeView(entry: entry)
    }
}

private struct TransferHeader: View {
    let entry: TransferEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.swap")
                .foregroundStyle(Color("hanyangBlue"))
                .font(.subheadline)
            Text("widget.transfer.title")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color("hanyangBlue"))
            if !entry.stopDisplayName.isEmpty {
                Text("· \(entry.stopDisplayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Button(intent: RefreshTransferIntent()) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TransferLargeView: View {
    let entry: TransferEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TransferHeader(entry: entry)
            Divider()

            switch entry.errorState {
            case .noLocation:
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "location.slash.fill").font(.title2).foregroundStyle(.secondary)
                    Text("shuttle.location.required").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            case .noData:
                Spacer()
                Text("shuttle.no.data").font(.body).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            case .none:
                ShuttleSectionView(groups: entry.shuttleGroups)

                if !entry.transitArrivals.isEmpty {
                    Divider()
                    TransitSectionView(arrivals: entry.transitArrivals, stopID: entry.stopID)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(12)
    }
}

// MARK: - Shared Column Views

struct TransitSectionView: View {
    let arrivals: [TransitArrival]
    let stopID: String

    var body: some View {
        let subwayArrivals = arrivals.filter { $0.isSubway }
        let busArrivals = arrivals.filter { !$0.isSubway }

        VStack(alignment: .leading, spacing: 4) {
            if !subwayArrivals.isEmpty {
                SectionHeader(
                    icon: "tram.fill",
                    title: "transit.header.subway",
                    subtitle: String(localized: "stop.station")
                )
                TransitArrivalColumn(arrivals: subwayArrivals, maxRows: 4)
            }
            if !busArrivals.isEmpty && !subwayArrivals.isEmpty {
                Divider().padding(.vertical, 2)
            }
            if !busArrivals.isEmpty {
                SectionHeader(
                    icon: "bus.doubledecker.fill",
                    title: "transit.header.bus",
                    subtitle: String(localized: "stop.terminal")
                )
                TransitArrivalColumn(arrivals: busArrivals, maxRows: 3)
            }
        }
    }
}

struct ShuttleSectionView: View {
    let groups: [ShuttleDestinationGroup]

    private let maxTimes = maxTimesInWidth(314)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(icon: "bus.fill", title: "shuttle.title")
            if groups.isEmpty {
                Text("shuttle.no.data").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(groups) { group in
                    HStack(spacing: 0) {
                        Text(group.destination)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 80, alignment: .leading)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(group.times.prefix(maxTimes), id: \.self) { t in
                                Text(t).font(.caption).fontWeight(.semibold).monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct SectionHeader: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: String?

    init(icon: String, title: LocalizedStringKey, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color("hanyangBlue"))
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("hanyangBlue"))
            if let subtitle {
                Text("· \(subtitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct TransitShuttleColumn: View {
    let groups: [ShuttleDestinationGroup]
    let maxGroups: Int
    let maxTimes: Int

    var body: some View {
        if groups.isEmpty {
            Text("shuttle.no.data")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(groups.prefix(maxGroups)) { group in
                    HStack(spacing: 0) {
                        Text(group.destination)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 80, alignment: .leading)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(group.times.prefix(maxTimes), id: \.self) { t in
                                Text(t)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}

private func transitLineColor(_ colorKey: String) -> Color {
    switch colorKey {
    case "line4": return Color(red: 0, green: 160/255, blue: 233/255)
    case "suin":  return Color(red: 250/255, green: 190/255, blue: 0)
    default:      return Color("busGreen")
    }
}

struct TransitArrivalColumn: View {
    let arrivals: [TransitArrival]
    let maxRows: Int

    private var minSuffix: String { String(localized: "transit.minutes.suffix") }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(arrivals) { arrival in
                if arrival.isSubway {
                    let hasUp = !arrival.upEntries.isEmpty
                    ForEach(arrival.upEntries.prefix(1)) { e in
                        ArrivalRow(
                            lineName: arrival.name,
                            colorKey: arrival.colorKey,
                            nameWidth: 65,
                            timeLabel: "\(e.minutes)\(minSuffix)(\(e.terminal))"
                        )
                    }
                    ForEach(arrival.downEntries.prefix(1)) { e in
                        ArrivalRow(
                            lineName: hasUp ? nil : arrival.name,
                            colorKey: arrival.colorKey,
                            nameWidth: 65,
                            timeLabel: "\(e.minutes)\(minSuffix)(\(e.terminal))"
                        )
                    }
                } else {
                    ForEach(arrival.upEntries.prefix(2)) { e in
                        ArrivalRow(
                            lineName: arrival.name,
                            colorKey: arrival.colorKey,
                            nameWidth: 200,
                            timeLabel: "\(e.minutes)\(minSuffix)\(e.terminal)"
                        )
                    }
                }
            }
        }
    }
}

private struct ArrivalRow: View {
    let lineName: String?
    let colorKey: String
    let nameWidth: CGFloat
    let timeLabel: String

    var body: some View {
        HStack(spacing: 4) {
            Text(lineName ?? "")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(lineName != nil ? transitLineColor(colorKey) : .clear)
                .lineLimit(1)
                .frame(maxWidth: nameWidth, alignment: .leading)
            Spacer()
            Text(timeLabel)
                .font(.caption2)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}

// MARK: - Widget

struct TransferWidget: Widget {
    let kind = "TransferWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TransferProvider()) { entry in
            TransferWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(entry.stopID.isEmpty ? nil : URL(string: "hyuabot://shuttle?stop=\(entry.stopID)"))
        }
        .configurationDisplayName("widget.transfer.name")
        .description("widget.transfer.description")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Preview

private let transferPreviewEntry = TransferEntry(
    date: .now,
    stopDisplayName: "기숙사",
    stopID: "dormitory_o",
    shuttleGroups: [
        ShuttleDestinationGroup(destination: "한대앞", times: ["15:30", "16:00"]),
        ShuttleDestinationGroup(destination: "예술인", times: ["15:45", "16:15"]),
        ShuttleDestinationGroup(destination: "중앙역", times: ["16:10"])
    ],
    transitArrivals: [
        TransitArrival(name: "4호선", colorKey: "line4", upEntries: [TransitEntry(terminal: "당고개", minutes: 3)], downEntries: [TransitEntry(terminal: "오이도", minutes: 12)]),
        TransitArrival(name: "수인선", colorKey: "suin", upEntries: [TransitEntry(terminal: "수원", minutes: 7)], downEntries: [TransitEntry(terminal: "인천", minutes: 22)]),
        TransitArrival(name: "50번(KTX광명)", colorKey: "bus", upEntries: [TransitEntry(terminal: "", minutes: 8)], downEntries: [])
    ],
    errorState: .none
)

#Preview("Large", as: .systemLarge) {
    TransferWidget()
} timeline: { transferPreviewEntry }
