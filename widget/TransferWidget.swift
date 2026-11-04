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

// MARK: - Provider

struct TransferProvider: TimelineProvider {
    func placeholder(in context: Context) -> TransferEntry {
        TransferEntry(
            date: ShuttleSampleData.referenceDate,
            stopDisplayName: "기숙사",
            stopID: "dormitory_o",
            shuttleGroups: [
                ShuttleDestinationGroup(
                    destination: "한대앞", times: ["14:04", "14:24"],
                    destinationKey: "STATION", serviceDate: ShuttleSampleData.referenceDate
                ),
                ShuttleDestinationGroup(
                    destination: "예술인", times: ["14:15", "14:45"],
                    destinationKey: "TERMINAL", serviceDate: ShuttleSampleData.referenceDate
                ),
                ShuttleDestinationGroup(
                    destination: "중앙역", times: ["14:30"],
                    destinationKey: "JUNGANG", serviceDate: ShuttleSampleData.referenceDate
                )
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
        let completion = WidgetCompletion(completion)
        Task { await completion(fetchEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TransferEntry>) -> Void) {
        let completion = WidgetCompletion(completion)
        Task {
            let entry = await fetchEntry()
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Foundation.Date.now)
                ?? Foundation.Date.now.addingTimeInterval(300)
            let entries = ShuttleDepartureMath.minuteTimelineDates(from: entry.date, count: 5).map { entry.advanced(to: $0) }
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
        }
    }

    private func fetchEntry() async -> TransferEntry {
        let fetchedAt = Foundation.Date.now
        let fetcher = WidgetLocationFetcher()
        guard let location = await fetcher.getCurrentLocation() else {
            return emptyEntry(errorState: .noLocation, date: fetchedAt)
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let currentTimeStr = timeFormatter.string(from: fetchedAt)
        let logDates = busLogReferenceDates()

        do {
            let response = try await WidgetNetwork.shared.fetch(
                query: ShuttleTransferWidgetQuery(
                    after: GraphQLNullable(stringLiteral: currentTimeStr),
                    weekday: widgetWeekday(),
                    logDates: .some(logDates),
                    language: Locale.current.language.languageCode?.identifier ?? "ko"
                )
            )

            guard let data = response.data else {
                return emptyEntry(errorState: .error, date: fetchedAt)
            }

            let stops = data.shuttle.stops
            guard !stops.isEmpty else {
                return emptyEntry(errorState: .error, date: fetchedAt)
            }

            guard let nearestStop = stops.min(by: {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: location)
                    < CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: location)
            }) else {
                return emptyEntry(errorState: .error, date: fetchedAt)
            }

            var shuttleGroups = makeShuttleGroups(nearestStop.timetable, serviceDate: fetchedAt)
            var displayName = stopDisplayName(for: nearestStop.name)
            var stopID = nearestStop.name

            if nearestStop.name == "shuttlecock_o" || nearestStop.name == "shuttlecock_i" {
                let companion = nearestStop.name == "shuttlecock_o" ? "shuttlecock_i" : "shuttlecock_o"
                if let other = stops.first(where: { $0.name == companion }) {
                    shuttleGroups += makeShuttleGroups(other.timetable, serviceDate: fetchedAt)
                }
                displayName = String(localized: "stop.shuttlecock")
                stopID = nearestStop.name
            }

            let transitArrivals = buildTransit(for: stopID, data: data)

            return TransferEntry(
                date: fetchedAt,
                stopDisplayName: displayName,
                stopID: stopID,
                shuttleGroups: shuttleGroups,
                transitArrivals: transitArrivals,
                errorState: shuttleGroups.isEmpty && transitArrivals.isEmpty ? .ended : .none
            )
        } catch {
            return emptyEntry(errorState: .error, date: fetchedAt)
        }
    }

    private func makeShuttleGroups(
        _ timetable: ShuttleTransferWidgetQuery.Data.Shuttle.Stop.Timetable,
        serviceDate: Foundation.Date
    ) -> [ShuttleDestinationGroup] {
        timetable.destination.compactMap { group in
            let times = group.entries.prefix(4).map { formatTime($0.time) }
            guard !times.isEmpty else { return nil }
            return ShuttleDestinationGroup(
                destination: destinationDisplayName(for: group.destination),
                times: Array(times),
                destinationKey: group.destination,
                serviceDate: serviceDate
            )
        }
    }

    private func emptyEntry(errorState: ShuttleErrorState, date: Foundation.Date = .now) -> TransferEntry {
        TransferEntry(
            date: date,
            stopDisplayName: "",
            stopID: "",
            shuttleGroups: [],
            transitArrivals: [],
            errorState: errorState
        )
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

extension TransferEntry {
    func advanced(to date: Foundation.Date) -> TransferEntry {
        let elapsed = max(0, Int(date.timeIntervalSince(self.date) / 60))
        let arrivals = transitArrivals.compactMap { arrival -> TransitArrival? in
            let up = arrival.upEntries
                .map { TransitEntry(terminal: $0.terminal, minutes: $0.minutes - elapsed) }
                .filter { $0.minutes >= 0 }
            let down = arrival.downEntries
                .map { TransitEntry(terminal: $0.terminal, minutes: $0.minutes - elapsed) }
                .filter { $0.minutes >= 0 }
            guard !up.isEmpty || !down.isEmpty else { return nil }
            return TransitArrival(
                name: arrival.name,
                colorKey: arrival.colorKey,
                upEntries: up,
                downEntries: down
            )
        }
        return TransferEntry(
            date: date,
            stopDisplayName: stopDisplayName,
            stopID: stopID,
            shuttleGroups: shuttleGroups,
            transitArrivals: arrivals,
            errorState: errorState
        )
    }
}

// MARK: - Widget

struct TransferWidget: Widget {
    let kind = "TransferWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TransferProvider()) { entry in
            TransferWidgetView(entry: entry)
                .containerBackground(HYUWidgetColor.background, for: .widget)
                .widgetURL(entry.stopID.isEmpty ? nil : URL(string: "hyuabot://shuttle?stop=\(entry.stopID)"))
        }
        .configurationDisplayName("widget.transfer.name")
        .description("widget.transfer.description")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

private let transferPreviewEntry = TransferEntry(
    date: ShuttleSampleData.referenceDate,
    stopDisplayName: "기숙사",
    stopID: "dormitory_o",
    shuttleGroups: [
        ShuttleDestinationGroup(
            destination: "한대앞", times: ["14:04", "14:24"],
            destinationKey: "STATION", serviceDate: ShuttleSampleData.referenceDate
        ),
        ShuttleDestinationGroup(
            destination: "예술인", times: ["14:15", "14:45"],
            destinationKey: "TERMINAL", serviceDate: ShuttleSampleData.referenceDate
        ),
        ShuttleDestinationGroup(
            destination: "중앙역", times: ["14:30"],
            destinationKey: "JUNGANG", serviceDate: ShuttleSampleData.referenceDate
        )
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

#Preview("Medium", as: .systemMedium) {
    TransferWidget()
} timeline: { transferPreviewEntry }

#Preview("Large", as: .systemLarge) {
    TransferWidget()
} timeline: { transferPreviewEntry }
