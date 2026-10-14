import SwiftUI
import WidgetKit

struct ShuttleComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: ComplicationSnapshot

    var body: some View {
        content
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(snapshot.stopID.map(ComplicationStore.deepLink(for:)))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .accessoryCorner: corner
        default: circular
        }
    }

    // MARK: - Circular: countdown and line name

    private var circular: some View {
        ZStack {
            switch snapshot.status {
            case .departures, .placeholder:
                if let next = snapshot.upcoming.first {
                    let countdown = Countdown(departure: next, at: snapshot.date)
                    VStack(spacing: 1) {
                        Text(countdown.short)
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        // Two lines under the countdown: stop, then route. Blank lines keep the height fixed
                        // so the countdown does not move.
                        VStack(spacing: 0) {
                            Text(stopLine.isEmpty ? " " : stopLine)
                                .font(.system(size: 8, weight: .regular))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Text(label(for: next).isEmpty ? " " : label(for: next))
                                .font(.system(size: 9, weight: .semibold))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                    }
                    .widgetAccentable()
                }
            case .noStop:
                Image(systemName: "mappin.and.ellipse").font(.title3)
            case .offline:
                Image(systemName: "wifi.slash").font(.title3)
            case .empty:
                Image(systemName: "moon.zzz.fill").font(.title3)
            case .unknown, .expired:
                Image(systemName: "arrow.triangle.2.circlepath").font(.title3)
            }
            if snapshot.isStale {
                staleBadge
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
        }
    }

    private var staleBadge: some View {
        Image(systemName: "clock.badge.exclamationmark")
            .font(.system(size: 9))
            .widgetAccentable()
    }

    // MARK: - Rectangular: clock time and route

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(stopName)
                .font(.headline)
                .lineLimit(1)
            switch snapshot.status {
            case .departures, .placeholder:
                if let next = snapshot.upcoming.first {
                    Text("\(ShuttleClock.displayTime(next.date)) \(label(for: next))")
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    Text(Countdown(departure: next, at: snapshot.date).long)
                        .font(.caption)
                }
                if let second = snapshot.upcoming.dropFirst().first {
                    Text("\(ShuttleClock.displayTime(second.date)) \(label(for: second))")
                        .font(.caption2)
                        .lineLimit(1)
                }
            case .noStop:
                Text(ComplicationText.text("noStop")).font(.caption).lineLimit(2)
            case .offline:
                Text(ComplicationText.text("offline")).font(.caption)
            case .empty:
                Text(ComplicationText.text("empty")).font(.caption)
            case .unknown, .expired:
                Text(ComplicationText.text("updating")).font(.caption)
            }
            if snapshot.isStale {
                Text(ComplicationText.text("stale")).font(.caption2)
            }
        }
    }

    // MARK: - Inline: one line

    private var inline: some View {
        Text(inlineText)
    }

    private var inlineText: String {
        var text: String
        switch snapshot.status {
        case .departures, .placeholder:
            if let next = snapshot.upcoming.first {
                // Leads with stop▶route; rows without a route label fall back to the departure time.
                let route = stopRouteLabel(for: next)
                let head = route.isEmpty ? ShuttleClock.displayTime(next.date) : route
                text = "\(head) · \(Countdown(departure: next, at: snapshot.date).short)"
            } else {
                text = ComplicationText.text("updating")
            }
        case .noStop: text = ComplicationText.text("noStop")
        case .offline: text = ComplicationText.text("offline")
        case .empty: text = ComplicationText.text("empty")
        case .unknown, .expired: text = ComplicationText.text("updating")
        }
        if snapshot.isStale {
            text += " · " + ComplicationText.text("stale")
        }
        return text
    }

    // MARK: - Corner: countdown on the curve, detail as the label

    private var corner: some View {
        Group {
            switch snapshot.status {
            case .departures, .placeholder:
                if let next = snapshot.upcoming.first {
                    let countdown = Countdown(departure: next, at: snapshot.date)
                    Text(countdown.short)
                        .font(.title3.bold())
                        .widgetCurvesContent()
                        .widgetLabel {
                            // Countdown is the curved text; the label is one line, stop▶route.
                            // Rows without a route label fall back to the departure time so the label is not blank.
                            let route = stopRouteLabel(for: next)
                            Text(cornerLabel(route.isEmpty ? ShuttleClock.displayTime(next.date) : route))
                        }
                }
            case .noStop:
                Image(systemName: "mappin.and.ellipse")
                    .widgetLabel { Text(cornerLabel(ComplicationText.text("noStop"))) }
            case .offline:
                Image(systemName: "wifi.slash")
                    .widgetLabel { Text(cornerLabel(ComplicationText.text("offline"))) }
            case .empty:
                Image(systemName: "moon.zzz.fill")
                    .widgetLabel { Text(cornerLabel(ComplicationText.text("empty"))) }
            case .unknown, .expired:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .widgetLabel { Text(cornerLabel(ComplicationText.text("updating"))) }
            }
        }
    }

    private func cornerLabel(_ text: String) -> String {
        snapshot.isStale ? "\(text) · \(ComplicationText.text("stale"))" : text
    }

    // MARK: - Helpers

    /// Circular's stop line: "정류장▶" so the arrow leads into the route line below, or "" when no stop is selected.
    private var stopLine: String {
        snapshot.stopID.map { "\(ComplicationText.stopName($0)) ▶" } ?? ""
    }

    private var stopName: String {
        snapshot.stopID.map { ComplicationText.stopName($0) } ?? ComplicationText.text("placeholder")
    }

    private func label(for departure: Departure) -> String {
        if snapshot.status == .placeholder {
            return ComplicationText.text("route.circular")
        }
        guard let stopID = snapshot.stopID else { return "" }
        return ComplicationText.routeLabel(
            stopID: stopID, routeTag: departure.routeTag, routeName: departure.routeName
        )
    }

    /// Corner and inline: "정류장▶노선명". Rows without a route label stay empty.
    private func stopRouteLabel(for departure: Departure) -> String {
        let routeLabel = label(for: departure)
        guard !routeLabel.isEmpty, let stopID = snapshot.stopID else { return routeLabel }
        return "\(ComplicationText.stopName(stopID)) ▶ \(routeLabel)"
    }
}

extension ComplicationStore {
    static func deepLink(for stopID: String) -> URL {
        URL(string: "hyuabot-watch://stop/\(stopID)")!
    }
}

#Preview("Circular", as: .accessoryCircular) {
    ShuttleComplication()
} timeline: {
    ShuttleComplicationEntry(snapshot: .placeholder(at: .now))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(
        date: .now, status: .departures, stopID: "station",
        upcoming: [Departure(date: .now.addingTimeInterval(240), routeTag: "C", routeName: "순환")],
        isStale: false
    ))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(date: .now, status: .empty, stopID: "station", upcoming: [], isStale: false))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(date: .now, status: .offline, stopID: "station", upcoming: [], isStale: false))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(date: .now, status: .expired, stopID: "station", upcoming: [], isStale: false))
}

#Preview("Rectangular", as: .accessoryRectangular) {
    ShuttleComplication()
} timeline: {
    ShuttleComplicationEntry(snapshot: .placeholder(at: .now))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(
        date: .now, status: .departures, stopID: "dormitory",
        upcoming: [
            Departure(date: .now.addingTimeInterval(240), routeTag: "C", routeName: "순환"),
            Departure(date: .now.addingTimeInterval(1500), routeTag: "DH", routeName: "직행")
        ],
        isStale: true
    ))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(date: .now, status: .unknown, stopID: "dormitory", upcoming: [], isStale: true))
}

#Preview("Inline", as: .accessoryInline) {
    ShuttleComplication()
} timeline: {
    ShuttleComplicationEntry(snapshot: .placeholder(at: .now))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(
        date: .now, status: .departures, stopID: "terminal",
        upcoming: [Departure(date: .now.addingTimeInterval(240), routeTag: "C", routeName: "순환")],
        isStale: false
    ))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(date: .now, status: .empty, stopID: "terminal", upcoming: [], isStale: false))
}

#Preview("Corner", as: .accessoryCorner) {
    ShuttleComplication()
} timeline: {
    ShuttleComplicationEntry(snapshot: .placeholder(at: .now))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(
        date: .now, status: .departures, stopID: "jungang",
        upcoming: [Departure(date: .now.addingTimeInterval(240), routeTag: "C", routeName: "순환")],
        isStale: true
    ))
    ShuttleComplicationEntry(snapshot: ComplicationSnapshot(date: .now, status: .noStop, stopID: nil, upcoming: [], isStale: false))
}
