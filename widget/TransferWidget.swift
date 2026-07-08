import Api
import Apollo
import AppIntents
import CoreLocation
import SwiftUI
import WidgetKit

// MARK: - Shared Transfer Badge (used by ShuttleWidget too)

struct TransferBadge: View {
    let stopID: String

    var body: some View {
        if let info = transferInfo(for: stopID) {
            HStack(spacing: 3) {
                Image(systemName: info.icon)
                    .font(.godoCaption2)
                    .foregroundStyle(.secondary)
                Text(info.label)
                    .font(.godoCaption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func transferInfo(for stopID: String) -> (icon: String, label: String)? {
        switch stopID {
        case "dormitory_o", "shuttlecock_o":
            ("arrow.triangle.swap", String(localized: "transfer.badge.all"))
        case "station", "jungang_stn":
            ("tram.fill", String(localized: "transfer.badge.subway"))
        case "terminal":
            ("bus.doubledecker.fill", String(localized: "transfer.badge.bus50"))
        default:
            nil
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

    var isSubway: Bool {
        !downEntries.isEmpty
    }
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

private func boundLabel(stationID: String, fallback: String) -> String {
    let nameKey = "subway.station." + stationID.lowercased()
    let localizedName = String(localized: LocalizedStringResource(stringLiteral: nameKey))
    let stationName = (localizedName == nameKey) ? fallback : localizedName
    return String(format: String(localized: "transit.terminal.bound"), stationName)
}

private let subwayLineMap: [String: (nameKey: String, colorKey: String)] = [
    "K449": ("subway.line4", "line4"),
    "K251": ("subway.suin", "suin")
]

private let transferRouteLabelFont: Font = .godoCaptionSemibold

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
                TransitArrival(
                    name: "4호선",
                    colorKey: "line4",
                    upEntries: [TransitEntry(terminal: "당고개", minutes: 3)],
                    downEntries: [TransitEntry(terminal: "오이도", minutes: 12)]
                ),
                TransitArrival(
                    name: "수인선",
                    colorKey: "suin",
                    upEntries: [TransitEntry(terminal: "수원", minutes: 7)],
                    downEntries: [TransitEntry(terminal: "인천", minutes: 22)]
                ),
                TransitArrival(
                    name: "50번",
                    colorKey: "bus",
                    upEntries: [TransitEntry(terminal: "", minutes: 8), TransitEntry(terminal: "", minutes: 31)],
                    downEntries: []
                )
            ],
            errorState: .none
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TransferEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        Task { await completion(fetchEntry()) }
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
            return TransferEntry(
                date: .now,
                stopDisplayName: "",
                stopID: "",
                shuttleGroups: [],
                transitArrivals: [],
                errorState: .noLocation
            )
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let currentTimeStr = timeFormatter.string(from: Foundation.Date.now)
        let logDates = busLogReferenceDates()

        do {
            let response = try await WidgetNetwork.shared.fetch(
                query: ShuttleTransferWidgetQuery(
                    after: GraphQLNullable(stringLiteral: currentTimeStr),
                    weekday: widgetWeekday(),
                    logDates: .some(logDates)
                )
            )

            guard let data = response.data else {
                return TransferEntry(
                    date: .now,
                    stopDisplayName: "",
                    stopID: "",
                    shuttleGroups: [],
                    transitArrivals: [],
                    errorState: .noData
                )
            }

            let stops = data.shuttle.stops
            guard !stops.isEmpty else {
                return TransferEntry(
                    date: .now,
                    stopDisplayName: "",
                    stopID: "",
                    shuttleGroups: [],
                    transitArrivals: [],
                    errorState: .noData
                )
            }

            let nearestStop = stops.min {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: location)
                    < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: location)
            }!

            func makeShuttleGroups(_ timetable: ShuttleTransferWidgetQuery.Data.Shuttle.Stop.Timetable) -> [ShuttleDestinationGroup] {
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

            let transitArrivals = buildTransit(for: stopID, data: data)

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

    private func buildTransit(for stopID: String, data: ShuttleTransferWidgetQuery.Data) -> [TransitArrival] {
        switch stopID {
        case "dormitory_o", "shuttlecock_o", "shuttlecock_i":
            buildSubway(data.subway) + buildBus(data.transferBus, stopSeq: 216_000_759, label: String(localized: "bus.to.kwangmyeong"))
        case "terminal":
            buildBus(data.transferBus, stopSeq: 216_000_117, label: String(localized: "bus.to.ansan"))
        case "station", "jungang_stn":
            [] // 미 표출
        default:
            []
        }
    }

    private func buildSubway(_ subway: [ShuttleTransferWidgetQuery.Data.Subway]) -> [TransitArrival] {
        subway.compactMap { station -> TransitArrival? in
            let info = subwayLineMap[station.stationID] ?? ("subway.line4", "line4")
            let name = String(localized: LocalizedStringResource(stringLiteral: info.nameKey))
            let up = station.arrival.first(where: { $0.direction == "up" })?.entries.prefix(1)
                .map {
                    TransitEntry(terminal: boundLabel(stationID: $0.terminal.stationID, fallback: $0.terminal.name), minutes: $0.minutes)
                } ??
                []
            let down = station.arrival.first(where: { $0.direction == "down" })?.entries.prefix(1)
                .map {
                    TransitEntry(terminal: boundLabel(stationID: $0.terminal.stationID, fallback: $0.terminal.name), minutes: $0.minutes)
                } ??
                []
            guard !up.isEmpty || !down.isEmpty else { return nil }
            return TransitArrival(name: name, colorKey: info.colorKey, upEntries: Array(up), downEntries: Array(down))
        }
    }

    private func buildBus(_ buses: [ShuttleTransferWidgetQuery.Data.TransferBus], stopSeq: Int, label: String) -> [TransitArrival] {
        let matchingBuses = buses.filter { $0.stop.seq == stopSeq }
        let entries = matchingBuses.flatMap(\.arrival).prefix(2).compactMap { arrival -> TransitEntry? in
            guard let m = arrival.minutes else { return nil }
            let stopsStr = (arrival.stops ?? 0) > 0
                ? String(format: String(localized: "transit.stops.format"), arrival.stops!)
                .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                : ""
            return TransitEntry(terminal: stopsStr, minutes: m)
        }
        let fallbackEntries = matchingBuses.flatMap(\.log)
            .compactMap { minutesUntilLogTime($0.time) }
            .filter { $0 >= 0 }
            .sorted()
            .prefix(2)
            .map { TransitEntry(terminal: String(localized: "transit.estimated"), minutes: $0) }
        let displayEntries = entries.isEmpty ? Array(fallbackEntries) : Array(entries)
        guard !displayEntries.isEmpty else { return [] }
        return [TransitArrival(name: label, colorKey: "bus", upEntries: displayEntries, downEntries: [])]
    }

    private func busLogReferenceDates() -> [Api.Date] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "yyyy-MM-dd"
        return [
            Foundation.Date.now.addingTimeInterval(-60 * 60 * 24 * 7),
            Foundation.Date.now.addingTimeInterval(-60 * 60 * 24 * 2),
            Foundation.Date.now.addingTimeInterval(-60 * 60 * 24)
        ].map(formatter.string)
    }

    private func minutesUntilLogTime(_ time: Api.LocalTime) -> Int? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "HH:mm:ss"
        guard let parsedTime = formatter.date(from: time) else { return nil }

        let calendar = Calendar(identifier: .iso8601)
        let now = Foundation.Date.now
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: parsedTime)
        guard let timeZone = TimeZone(identifier: "Asia/Seoul") else { return nil }
        let todayComponents = calendar.dateComponents(in: timeZone, from: now)
        var logComponents = DateComponents()
        logComponents.calendar = calendar
        logComponents.timeZone = TimeZone(identifier: "Asia/Seoul")
        logComponents.year = todayComponents.year
        logComponents.month = todayComponents.month
        logComponents.day = todayComponents.day
        logComponents.hour = timeComponents.hour
        logComponents.minute = timeComponents.minute
        logComponents.second = timeComponents.second
        guard let logDate = logComponents.date else { return nil }
        return Int(ceil(logDate.timeIntervalSince(now) / 60))
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
                .font(.godoSubheadline)
            Text("widget.transfer.title")
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
            Button(intent: RefreshTransferIntent()) {
                Image(systemName: "arrow.clockwise")
                    .font(.godoCaption2)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TransferLargeView: View {
    let entry: TransferEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TransferHeader(entry: entry)
            Divider()

            switch entry.errorState {
            case .noLocation:
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "location.slash.fill").font(.title2).foregroundStyle(.secondary)
                    Text("shuttle.location.required").font(.godoSubheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            case .noData:
                Spacer()
                Text("shuttle.no.data").font(.godoBody).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            case .none:
                ShuttleSectionView(groups: entry.shuttleGroups, maxGroups: 3, maxTimes: 3)

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
        let subwayArrivals = arrivals.filter(\.isSubway)
        let busArrivals = arrivals.filter { !$0.isSubway }
        let showsBusSection = !busArrivals.isEmpty || supportsBusTransfer

        VStack(alignment: .leading, spacing: 6) {
            if !subwayArrivals.isEmpty {
                SectionHeader(
                    icon: "tram.fill",
                    title: "transit.header.subway",
                    subtitle: String(localized: "stop.station")
                )
                TransitArrivalColumn(arrivals: subwayArrivals, maxRows: 4)
            }
            if showsBusSection, !subwayArrivals.isEmpty {
                Divider().padding(.vertical, 2)
            }
            if showsBusSection {
                SectionHeader(
                    icon: "bus.doubledecker.fill",
                    title: "transit.header.bus",
                    subtitle: String(localized: "stop.terminal")
                )
                if busArrivals.isEmpty {
                    Text("transit.no.arrivals")
                        .font(.godoCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    TransitArrivalColumn(arrivals: busArrivals, maxRows: 3)
                }
            }
        }
    }

    private var supportsBusTransfer: Bool {
        switch stopID {
        case "dormitory_o", "shuttlecock_o", "shuttlecock_i", "terminal":
            true
        default:
            false
        }
    }
}

struct ShuttleSectionView: View {
    let groups: [ShuttleDestinationGroup]
    let maxGroups: Int
    let maxTimes: Int

    init(groups: [ShuttleDestinationGroup], maxGroups: Int = 3, maxTimes: Int = 2) {
        self.groups = groups
        self.maxGroups = maxGroups
        self.maxTimes = maxTimes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(icon: "bus.fill", title: "shuttle.title")
            if groups.isEmpty {
                Text("shuttle.no.data").font(.godoCaption).foregroundStyle(.secondary)
            } else {
                ForEach(groups.prefix(maxGroups)) { group in
                    HStack(spacing: 8) {
                        Text(group.destination)
                            .font(transferRouteLabelFont)
                            .foregroundStyle(.secondary)
                            .frame(width: 86, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 8)
                        HStack(spacing: 6) {
                            ForEach(group.times.prefix(maxTimes), id: \.self) { t in
                                Text(t)
                                    .font(.godoSubheadlineSemibold)
                                    .monospacedDigit()
                                    .lineLimit(1)
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
                .font(.godoCaption2)
                .foregroundStyle(Color("hanyangBlue"))
            Text(title)
                .font(.godoCaptionSemibold)
                .foregroundStyle(Color("hanyangBlue"))
            if let subtitle {
                Text("· \(subtitle)")
                    .font(.godoCaption)
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
                .font(.godoCaption2)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(groups.prefix(maxGroups)) { group in
                    HStack(spacing: 0) {
                        Text(group.destination)
                            .font(.godoCaption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 80, alignment: .leading)
                            .lineLimit(1)
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(group.times.prefix(maxTimes), id: \.self) { t in
                                Text(t)
                                    .font(.godoCaptionSemibold)
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
    case "line4": Color(red: 0, green: 160 / 255, blue: 233 / 255)
    case "suin": Color(red: 250 / 255, green: 190 / 255, blue: 0)
    default: Color("busGreen")
    }
}

struct TransitArrivalColumn: View {
    let arrivals: [TransitArrival]
    let maxRows: Int

    private var minSuffix: String {
        String(localized: "transit.minutes.suffix")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(rows.prefix(maxRows).enumerated()), id: \.offset) { _, row in
                ArrivalRow(row: row, minSuffix: minSuffix)
            }
        }
    }

    private var rows: [ArrivalDisplayRow] {
        arrivals.flatMap { arrival -> [ArrivalDisplayRow] in
            if arrival.isSubway {
                return [
                    ArrivalDisplayRow(
                        lineName: arrival.name,
                        colorKey: arrival.colorKey,
                        subwayUp: arrival.upEntries.first,
                        subwayDown: arrival.downEntries.first,
                        busEntry: nil
                    )
                ]
            }
            return arrival.upEntries.prefix(2).map {
                ArrivalDisplayRow(
                    lineName: arrival.name,
                    colorKey: arrival.colorKey,
                    subwayUp: nil,
                    subwayDown: nil,
                    busEntry: $0
                )
            }
        }
    }
}

private struct ArrivalDisplayRow {
    let lineName: String
    let colorKey: String
    let subwayUp: TransitEntry?
    let subwayDown: TransitEntry?
    let busEntry: TransitEntry?

    var isSubway: Bool {
        busEntry == nil
    }
}

private struct ArrivalRow: View {
    let row: ArrivalDisplayRow
    let minSuffix: String

    var body: some View {
        if row.isSubway {
            HStack(spacing: 6) {
                Text(row.lineName)
                    .font(transferRouteLabelFont)
                    .foregroundStyle(transitLineColor(row.colorKey))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 56, alignment: .leading)
                HStack(spacing: 4) {
                    SubwayArrivalText(entry: row.subwayUp, minSuffix: minSuffix)
                    Text("|")
                        .font(.godoCaption)
                        .foregroundStyle(.tertiary)
                    SubwayArrivalText(entry: row.subwayDown, minSuffix: minSuffix)
                }
                .lineLimit(1)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 2)
        } else if let busEntry = row.busEntry {
            HStack(spacing: 6) {
                Text(row.lineName)
                    .font(transferRouteLabelFont)
                    .foregroundStyle(transitLineColor(row.colorKey))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: 56, alignment: .leading)
                Spacer(minLength: 4)
                BusArrivalText(entry: busEntry, minSuffix: minSuffix)
            }
            .padding(.vertical, 2)
        }
    }
}

private struct SubwayArrivalText: View {
    let entry: TransitEntry?
    let minSuffix: String

    var body: some View {
        if let entry {
            HStack(spacing: 4) {
                Text("\(entry.minutes)\(minSuffix)")
                    .font(.godoSubheadlineSemibold)
                    .monospacedDigit()
                Text(entry.terminal)
                    .font(.godoCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .fixedSize(horizontal: true, vertical: false)
        } else {
            Text("-")
                .font(.godoSubheadline)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct BusArrivalText: View {
    let entry: TransitEntry
    let minSuffix: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(entry.minutes)\(minSuffix)")
                .font(.godoSubheadlineSemibold)
                .monospacedDigit()
            if !entry.terminal.isEmpty {
                Text(entry.terminal)
                    .font(.godoCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
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
        TransitArrival(
            name: "4호선",
            colorKey: "line4",
            upEntries: [TransitEntry(terminal: "당고개", minutes: 3)],
            downEntries: [TransitEntry(terminal: "오이도", minutes: 12)]
        ),
        TransitArrival(
            name: "수인선",
            colorKey: "suin",
            upEntries: [TransitEntry(terminal: "수원", minutes: 7)],
            downEntries: [TransitEntry(terminal: "인천", minutes: 22)]
        ),
        TransitArrival(name: "50번", colorKey: "bus", upEntries: [TransitEntry(terminal: "(2 전)", minutes: 8)], downEntries: [])
    ],
    errorState: .none
)

#Preview("Large", as: .systemLarge) {
    TransferWidget()
} timeline: { transferPreviewEntry }
