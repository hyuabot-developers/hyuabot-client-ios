import Api
import SwiftUI

struct DepartureListView: View {
    let stop: WatchShuttleStop
    let isNearest: Bool
    let onShowOtherStops: () -> Void

    @StateObject private var viewModel: DepartureListViewModel

    private static let placeholderTags: [String: [String]] = [
        "dormitory": ["C", "DH"],
        "shuttlecock": ["C", "DH"],
        "station": ["DH", "C"],
        "terminal": ["DY"],
        "jungang": ["DJ"]
    ]

    init(
        stop: WatchShuttleStop,
        isNearest: Bool = false,
        onShowOtherStops: @escaping () -> Void = {}
    ) {
        self.stop = stop
        self.isNearest = isNearest
        self.onShowOtherStops = onShowOtherStops
        _viewModel = StateObject(wrappedValue: DepartureListViewModel(stop: stop))
    }

    var body: some View {
        List {
            header
            stateRows
            otherStopsButton
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isNearest {
                HStack(spacing: 4) {
                    Circle().fill(WatchPalette.accentBlue).frame(width: 7, height: 7)
                    Text(WatchLocalization.text("nearest.stop"))
                        .font(.system(size: 11))
                        .foregroundStyle(WatchPalette.secondaryText)
                        .lineLimit(1)
                }
            }
            Text(stop.localizedName)
                .font(.system(size: 19, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .accessibilityElement(children: .combine)
        .listRowBackground(Color.clear)
    }

    @ViewBuilder private var stateRows: some View {
        switch viewModel.loadState {
        case .loading:
            loadingRows
        case .loaded:
            ForEach(Array(viewModel.items.prefix(4)), id: \.self) { item in
                TimelineView(.everyMinute) { context in
                    departureRow(for: item, now: context.date)
                }
            }
        case .empty:
            statusRow(icon: "moon.zzz.fill", color: WatchPalette.secondaryText, message: "no.scheduled.shuttle")
        case .failed:
            statusRow(icon: "exclamationmark", color: WatchPalette.warning, message: "load.failed")
            Button { viewModel.retry() } label: {
                Text(WatchLocalization.text("retry"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.plain)
            .listRowBackground(Capsule().fill(WatchPalette.primaryButton))
        }
    }

    private var loadingRows: some View {
        Group {
            ForEach(Self.placeholderTags[stop.id] ?? ["C"], id: \.self) { tag in
                DepartureRow(
                    tag: tag,
                    name: routeName(forTag: tag, fallback: ""),
                    countdown: "–",
                    clock: nil,
                    isImminent: false
                )
                .opacity(0.35)
                .accessibilityHidden(true)
                .listRowBackground(rowBackground)
            }
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    private func departureRow(
        for item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order,
        now: Foundation.Date
    ) -> some View {
        let row: DepartureRow
        if let date = WatchDepartureTime.departureDate(from: item.time, now: now) {
            let minutes = WatchDepartureTime.minutesUntil(date, now: now)
            let countdown = minutes == 0
                ? WatchLocalization.text("countdown.now")
                : String(format: WatchLocalization.text("countdown.minutes"), minutes)
            row = DepartureRow(
                tag: item.route.tag,
                name: routeName(forTag: item.route.tag, fallback: item.route.name),
                countdown: countdown,
                clock: WatchDepartureTime.clockText(date),
                isImminent: WatchDepartureTime.isImminent(minutes: minutes)
            )
        } else {
            row = DepartureRow(
                tag: item.route.tag,
                name: routeName(forTag: item.route.tag, fallback: item.route.name),
                countdown: item.time,
                clock: nil,
                isImminent: false
            )
        }
        return row.listRowBackground(rowBackground)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 13).fill(WatchPalette.rowBackground)
    }

    private func statusRow(icon: String, color: Color, message: String) -> some View {
        VStack(spacing: 10) {
            statusIcon(systemName: icon, color: color)
            Text(WatchLocalization.text(message))
                .font(.system(size: 14))
                .foregroundStyle(WatchPalette.messageText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }

    private func statusIcon(systemName: String, color: Color) -> some View {
        ZStack {
            Circle().fill(WatchPalette.rowBackground).frame(width: 34, height: 34)
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
        }
        .accessibilityHidden(true)
    }

    private var otherStopsButton: some View {
        Button { onShowOtherStops() } label: {
            Label(WatchLocalization.text("other.stops"), systemImage: "list.bullet")
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
        .listRowBackground(Capsule().fill(WatchPalette.secondaryButton))
    }

    private func routeName(forTag tag: String, fallback: String) -> String {
        if stop.id == "dormitory" || stop.id == "shuttlecock" {
            switch tag {
            case "DH": return WatchLocalization.text("stop.station")
            case "DY": return WatchLocalization.text("stop.terminal")
            case "DJ": return WatchLocalization.text("stop.jungang")
            case "C": return WatchLocalization.text("route.circular")
            default: return fallback
            }
        } else if stop.id == "station" {
            switch tag {
            case "C": return WatchLocalization.text("route.circular")
            case "DH": return WatchLocalization.text("route.direct")
            case "DJ": return WatchLocalization.text("stop.jungang")
            default: return fallback
            }
        }
        return WatchLocalization.text("route.direct")
    }
}

private struct DepartureRow: View {
    let tag: String
    let name: String
    let countdown: String
    let clock: String?
    let isImminent: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(WatchPalette.route(tag: tag)).frame(width: 8, height: 8)
            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 0) {
                Text(countdown)
                    .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(isImminent ? WatchPalette.imminent : Color.primary)
                    .lineLimit(1)
                if let clock {
                    Text(clock)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(WatchPalette.secondaryText)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(minHeight: 36)
        .accessibilityElement(children: .combine)
    }
}
