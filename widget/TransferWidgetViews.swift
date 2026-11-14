//
//  TransferWidgetViews.swift
//  hyuabot
//

import AppIntents
import SwiftUI
import WidgetKit

struct TransferWidgetView: View {
    @Environment(\.widgetFamily)
    private var family
    let entry: TransferEntry

    var body: some View {
        content
            .padding(HYUWidgetMetrics.contentPadding)
            .foregroundStyle(HYUWidgetColor.foreground)
    }

    @ViewBuilder private var content: some View {
        let titleText = entry.stopDisplayName.isEmpty ? String(localized: "widget.transfer.title") : entry.stopDisplayName
        switch entry.errorState {
        case .noLocation:
            WidgetStateView(
                title: String(localized: "widget.transfer.title"),
                refreshDate: nil,
                kind: .locationRequired,
                retryIntent: RefreshTransferIntent()
            )
        case .error:
            WidgetStateView(title: titleText, refreshDate: nil, kind: .error, retryIntent: RefreshTransferIntent())
        case .ended:
            WidgetStateView(
                title: titleText,
                refreshDate: entry.date,
                kind: .ended(message: "shuttle.state.ended"),
                retryIntent: RefreshTransferIntent()
            )
        case .none:
            if !ShuttleDepartureMath.transferHasContent(
                groups: entry.shuttleGroups,
                transitArrivalCount: entry.transitArrivals.count,
                now: entry.date
            ) {
                WidgetStateView(
                    title: titleText,
                    refreshDate: entry.date,
                    kind: .ended(message: "shuttle.state.ended"),
                    retryIntent: RefreshTransferIntent()
                )
            } else if family == .systemMedium {
                TransferMediumView(entry: entry)
            } else {
                TransferLargeView(entry: entry)
            }
        }
    }
}

private struct TransferLargeView: View {
    let entry: TransferEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TransferLargeHeader(entry: entry)
            TransferShuttleList(groups: entry.shuttleGroups, now: entry.date)
            TransferLargeTransit(entry: entry)
            Spacer(minLength: 0)
            TransferFootnote(entry: entry)
        }
    }
}

private struct TransferLargeHeader: View {
    let entry: TransferEntry

    var body: some View {
        HStack(spacing: 6) {
            Text("widget.transfer.title").font(.godo(size: 13, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
            Text(verbatim: "· " + entry.stopDisplayName).font(.godo(size: 13, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                .lineLimit(1)
            Spacer(minLength: 4)
            WidgetRefreshStamp(date: entry.date, intent: RefreshTransferIntent())
        }
        .frame(minHeight: 18)
    }
}

private struct TransferShuttleList: View {
    let groups: [ShuttleDestinationGroup]
    let now: Date
    private var rows: [[ShuttleDeparture]] {
        Array(ShuttleDepartureMath.upcomingByLabel(in: groups, now: now).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("shuttle.title").font(.godo(size: 11, weight: .bold)).foregroundStyle(HYUWidgetColor.brand).padding(.top, 12)
            if rows.isEmpty {
                Text("shuttle.state.ended").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted).padding(.top, 7)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                    ForEach(rows.indices, id: \.self) { index in
                        TransferShuttleRow(departures: rows[index])
                    }
                }.padding(.top, 7)
            }
        }
    }
}

private struct TransferShuttleRow: View {
    let departures: [ShuttleDeparture]

    var body: some View {
        let first = departures[0]
        GridRow {
            DestinationDot(color: HYUWidgetColor.destination(forKey: first.destinationKey))
            Text(verbatim: first.destination).font(.godo(size: 13, weight: .semibold)).lineLimit(1).gridColumnAlignment(.leading).frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            Text(verbatim: departures.prefix(2).map(\.time).joined(separator: " · ")).font(.godo(size: 11, weight: .regular))
                .foregroundStyle(HYUWidgetColor.muted).lineLimit(1)
            InlineMinutesText(minutes: first.minutes, size: 15, imminent: first.minutes <= 5).frame(width: 40, alignment: .trailing)
        }
    }
}

private struct TransferLargeTransit: View {
    let entry: TransferEntry
    private var subway: [TransitArrival] {
        entry.transitArrivals.filter { $0.colorKey != "bus" }
    }

    private var bus: [TransitArrival] {
        entry.transitArrivals.filter { $0.colorKey == "bus" }
    }

    private var supportsBus: Bool {
        ["dormitory_o", "shuttlecock_o", "shuttlecock_i", "terminal"].contains(entry.stopID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !subway.isEmpty {
                WidgetSeparator().padding(.top, 12).padding(.bottom, 10)
                TransitGrid(
                    title: "transit.header.subway",
                    leftHeader: "transit.direction.up",
                    rightHeader: "transit.direction.down",
                    rows: subwayRows(subway),
                    badgeWidth: HYUWidgetMetrics.badgeWidth,
                    minuteSize: 15,
                    labelSize: 11,
                    rowSpacing: 7
                )
            }
            if supportsBus {
                WidgetSeparator().padding(.top, 12).padding(.bottom, 10)
                if bus.isEmpty {
                    Text("transit.header.bus").font(.godo(size: 11, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
                    Text("transit.no.arrivals").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                        .padding(.top, 7)
                } else {
                    TransitGrid(
                        title: "transit.header.bus",
                        leftHeader: "transit.bus.current",
                        rightHeader: "transit.bus.next",
                        rows: busRows(bus),
                        badgeWidth: HYUWidgetMetrics.badgeWidth,
                        minuteSize: 15,
                        labelSize: 11,
                        rowSpacing: 7
                    )
                }
            }
        }
    }
}

private struct TransferFootnote: View {
    let entry: TransferEntry
    private var subwayEmpty: Bool {
        !entry.transitArrivals.contains { $0.colorKey != "bus" }
    }

    private var noBusSupport: Bool {
        !["dormitory_o", "shuttlecock_o", "shuttlecock_i", "terminal"].contains(entry.stopID)
    }

    var body: some View {
        if entry.stopID == "terminal" {
            Text("transfer.terminal.note").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        } else if subwayEmpty, noBusSupport {
            Text("transfer.none.note").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
    }
}

private struct TransferMediumView: View {
    let entry: TransferEntry
    private var subway: [TransitArrival] {
        entry.transitArrivals.filter { $0.colorKey != "bus" }
    }

    private var bus: [TransitArrival] {
        entry.transitArrivals.filter { $0.colorKey == "bus" }
    }

    var body: some View {
        if entry.transitArrivals.isEmpty {
            TransferMediumShuttleFallback(entry: entry)
        } else {
            HStack(alignment: .top, spacing: 12) {
                TransferMediumHero(entry: entry).frame(width: 104)
                WidgetSeparator(axis: .vertical)
                TransferMediumTransit(entry: entry, subway: subway, bus: bus).frame(maxWidth: .infinity)
            }
        }
    }
}

private struct TransferMediumShuttleFallback: View {
    let entry: TransferEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(verbatim: entry.stopDisplayName).font(.godo(size: 15, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
                Text("shuttle.nearest.stop").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
                Spacer()
                WidgetRefreshStamp(date: entry.date, intent: RefreshTransferIntent())
            }.frame(minHeight: 18)
            ShuttleBoardContent(groups: entry.shuttleGroups, now: entry.date, mergesCircularRuns: true)
        }
    }
}

private struct TransferMediumHero: View {
    let entry: TransferEntry
    private var hero: ShuttleDeparture? {
        ShuttleDepartureMath.nextPerGroup(in: entry.shuttleGroups, now: entry.date).first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: entry.stopDisplayName).font(.godo(size: 13, weight: .bold)).foregroundStyle(HYUWidgetColor.brand).lineLimit(1)
                .frame(minHeight: 18, alignment: .leading)
            Spacer(minLength: 4)
            if let hero {
                HStack(spacing: 6) {
                    DestinationDot(color: HYUWidgetColor.destination(forKey: hero.destinationKey))
                    Text(verbatim: hero.destination).font(.godo(size: 12, weight: .semibold)).lineLimit(1)
                }
                MinutesText(minutes: hero.minutes, size: 32, imminent: hero.minutes <= 5).padding(.top, 4)
                Text(verbatim: String(format: String(localized: "shuttle.departs.format"), hero.time)).font(.godo(
                    size: 11,
                    weight: .regular
                )).foregroundStyle(HYUWidgetColor.muted).padding(.top, 3)
            } else {
                Text("shuttle.state.ended").font(.godo(size: 11, weight: .regular)).foregroundStyle(HYUWidgetColor.muted)
            }
            Spacer(minLength: 4)
        }
    }
}

private struct TransferMediumTransit: View {
    let entry: TransferEntry
    let subway: [TransitArrival]
    let bus: [TransitArrival]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("transfer.medium.header").font(.godo(size: 11, weight: .bold)).foregroundStyle(HYUWidgetColor.brand)
                Spacer(minLength: 4)
                WidgetRefreshStamp(date: entry.date, intent: RefreshTransferIntent())
            }.frame(minHeight: 18)
            Spacer(minLength: 4)
            TransitGrid(
                title: nil,
                leftHeader: nil,
                rightHeader: nil,
                rows: subwayRows(subway) + busRows(bus),
                badgeWidth: HYUWidgetMetrics.badgeWidth,
                minuteSize: 14,
                labelSize: 10,
                rowSpacing: 9
            )
            Spacer(minLength: 4)
        }
    }
}
