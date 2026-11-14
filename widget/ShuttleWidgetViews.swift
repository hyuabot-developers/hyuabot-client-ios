//
//  ShuttleWidgetViews.swift
//  hyuabot
//

import AppIntents
import SwiftUI
import WidgetKit

struct ShuttleWidgetView: View {
    @Environment(\.widgetFamily)
    private var family
    let entry: ShuttleEntry

    private var titleText: String {
        entry.stopDisplayName.isEmpty ? String(localized: "shuttle.title") : entry.stopDisplayName
    }

    var body: some View {
        Group {
            switch entry.errorState {
            case .noLocation:
                state(.locationRequired, title: String(localized: "shuttle.title"), date: nil)
            case .error:
                state(.error, title: titleText, date: nil)
            case .ended:
                state(.ended(message: "shuttle.state.ended"), title: titleText, date: entry.date)
            case .none:
                if ShuttleDepartureMath.upcoming(in: entry.groups, now: entry.date).isEmpty {
                    state(.ended(message: "shuttle.state.ended"), title: titleText, date: entry.date)
                } else {
                    switch family {
                    case .systemMedium: ShuttleMediumView(entry: entry)
                    case .systemLarge: ShuttleLargeView(entry: entry)
                    default: ShuttleSmallView(entry: entry)
                    }
                }
            }
        }
        .padding(HYUWidgetMetrics.contentPadding)
        .foregroundStyle(HYUWidgetColor.foreground)
    }

    private func state(_ kind: WidgetStateKind, title: String, date: Date?) -> some View {
        WidgetStateView(title: title, refreshDate: date, kind: kind, retryIntent: RefreshShuttleIntent())
    }
}

struct ShuttleSmallView: View {
    let entry: ShuttleEntry

    private var departures: [ShuttleDeparture] {
        ShuttleDepartureMath.nextPerGroup(in: entry.groups, now: entry.date)
    }

    private var upcoming: [ShuttleDeparture] {
        ShuttleDepartureMath.upcoming(in: entry.groups, now: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShuttleSmallHeader(entry: entry)
            if let hero = departures.first ?? upcoming.first {
                ShuttleSmallHeroRow(departure: hero)
                MinutesText(minutes: hero.minutes, size: 34, imminent: hero.minutes <= HYUWidgetMetrics.imminentMinutes)
                    .padding(.top, 4)
                Spacer(minLength: 4)
                ShuttleSmallRows(departures: Array((departures.dropFirst().isEmpty ? upcoming.dropFirst() : departures.dropFirst())
                        .prefix(2)))
            }
        }
    }
}

private struct ShuttleSmallHeader: View {
    let entry: ShuttleEntry
    var body: some View {
        HStack(spacing: 6) {
            Text(entry.stopDisplayName.isEmpty ? String(localized: "shuttle.title") : entry.stopDisplayName)
                .font(.godo(size: 13, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            WidgetRefreshStamp(date: entry.date, intent: RefreshShuttleIntent())
        }
        .frame(minHeight: HYUWidgetMetrics.headerMinHeight)
    }
}

private struct ShuttleSmallHeroRow: View {
    let departure: ShuttleDeparture
    var body: some View {
        HStack(spacing: 6) {
            DestinationDot(color: HYUWidgetColor.destination(forKey: departure.destinationKey))
            Text(departure.destination).font(.godo(size: 12, weight: .semibold)).lineLimit(1)
            Text(departure.time).font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
        }
        .padding(.top, 10)
    }
}

private struct ShuttleSmallRows: View {
    let departures: [ShuttleDeparture]
    var body: some View {
        VStack(spacing: 5) {
            ForEach(departures) { departure in
                HStack(spacing: 6) {
                    DestinationDot(color: HYUWidgetColor.destination(forKey: departure.destinationKey))
                    Text(departure.destination).font(.godo(size: 12, weight: .semibold)).lineLimit(1)
                    Spacer(minLength: 4)
                    InlineMinutesText(minutes: departure.minutes, size: 12)
                }
            }
        }
    }
}

struct ShuttleBoardContent: View {
    let groups: [ShuttleDestinationGroup]
    let now: Date
    /// Not direction specific: circular runs form one 순환 column instead of appearing under 한대앞 and 예술인.
    var mergesCircularRuns = false

    private var columns: [[ShuttleDeparture]] {
        let departures = mergesCircularRuns
            ? ShuttleDepartureMath.upcomingByLabel(in: groups, now: now)
            : ShuttleDepartureMath.upcomingByGroup(in: groups, now: now)
        return Array(departures.prefix(4))
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                    ShuttleBoardColumn(departures: column, count: columns.count >= 4 ? 1 : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private struct ShuttleBoardColumn: View {
    let departures: [ShuttleDeparture]
    let count: Int
    private var first: ShuttleDeparture {
        departures[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                DestinationDot(color: HYUWidgetColor.destination(forKey: first.destinationKey))
                Text(first.destination).font(.godo(size: 12, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            MinutesText(minutes: first.minutes, size: 30, imminent: first.minutes <= HYUWidgetMetrics.imminentMinutes)
            Text(departures.prefix(count).map(\.time).joined(separator: " · "))
                .font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).lineLimit(1)
        }
    }
}

struct ShuttleMediumView: View {
    let entry: ShuttleEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(entry.stopDisplayName.isEmpty ? String(localized: "shuttle.title") : entry.stopDisplayName)
                    .font(.godo(size: 15, weight: .bold)).foregroundStyle(HYUWidgetColor.brand).lineLimit(1)
                Text("shuttle.nearest.stop").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).lineLimit(1)
                Spacer(minLength: 4)
                WidgetRefreshStamp(date: entry.date, intent: RefreshShuttleIntent())
            }
            .frame(minHeight: HYUWidgetMetrics.headerMinHeight)
            ShuttleBoardContent(groups: entry.groups, now: entry.date)
        }
    }
}

struct ShuttleLargeView: View {
    let entry: ShuttleEntry
    private var all: [ShuttleDeparture] {
        ShuttleDepartureMath.upcoming(in: entry.groups, now: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ShuttleLargeHeader(entry: entry)
            if let hero = all.first {
                ShuttleLargeHero(departure: hero).heroBlock().padding(.top, 10)
                ShuttleLargeRows(departures: Array(all.dropFirst().prefix(6))).padding(.top, 6)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct ShuttleLargeHeader: View {
    let entry: ShuttleEntry
    var body: some View {
        HStack(spacing: 6) {
            Text("shuttle.title").font(.godo(size: 13, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
            Text(verbatim: "· " + entry.stopDisplayName).font(.godo(size: 13, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                .lineLimit(1)
            Spacer(minLength: 4)
            WidgetRefreshStamp(date: entry.date, intent: RefreshShuttleIntent())
        }
        .frame(minHeight: HYUWidgetMetrics.headerMinHeight)
    }
}

private struct ShuttleLargeHero: View {
    let departure: ShuttleDeparture
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("shuttle.next").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
            HStack(alignment: .center, spacing: 6) {
                DestinationDot(color: HYUWidgetColor.destination(forKey: departure.destinationKey))
                Text(departure.destination).font(.godo(size: 17, weight: .bold)).lineLimit(1)
                Text(String(format: String(localized: "shuttle.departs.format"), departure.time))
                    .font(.godo(size: 12, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).lineLimit(1)
                Spacer(minLength: 4)
                MinutesText(minutes: departure.minutes, size: 30, imminent: departure.minutes <= HYUWidgetMetrics.imminentMinutes)
            }
        }
    }
}

private struct ShuttleLargeRows: View {
    let departures: [ShuttleDeparture]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(departures.enumerated()), id: \.element.id) { index, departure in
                ShuttleLargeRow(departure: departure)
                if index < departures.count - 1 {
                    WidgetSeparator()
                }
            }
        }
    }
}

private struct ShuttleLargeRow: View {
    let departure: ShuttleDeparture
    var body: some View {
        HStack(spacing: 8) {
            Text(departure.time).font(.godo(size: 14, weight: .semibold)).monospacedDigit().frame(width: 42, alignment: .leading)
            DestinationDot(color: HYUWidgetColor.destination(forKey: departure.destinationKey))
            Text(departure.destination).font(.godo(size: 14, weight: .regular)).lineLimit(1)
            Spacer(minLength: 4)
            Text("\(departure.minutes)" + String(localized: "transit.minutes.suffix"))
                .font(.godo(size: 13, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).monospacedDigit()
        }
        .frame(height: 31)
    }
}
