import Api
import SwiftUI

struct DepartureListView: View {
    let stop: WatchShuttleStop
    let isNearest: Bool
    let onShowOtherStops: () -> Void

    @StateObject private var viewModel: DepartureListViewModel

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
            VStack(alignment: .leading, spacing: 2) {
                if isNearest {
                    Label(WatchLocalization.text("nearest.stop"), systemImage: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(stop.localizedName)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .accessibilityElement(children: .combine)

            switch viewModel.loadState {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .loaded:
                ForEach(Array(viewModel.items.prefix(4)), id: \.self) { item in
                    HStack(spacing: 8) {
                        Text(routeName(for: item))
                            .font(.body.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(timeLabel(for: item))
                            .font(.body.monospacedDigit())
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .layoutPriority(1)
                    }
                    .accessibilityElement(children: .combine)
                }
            case .empty:
                Text(WatchLocalization.text("no.scheduled.shuttle"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            case .failed:
                VStack(spacing: 8) {
                    Text(WatchLocalization.text("load.failed"))
                        .font(.body)
                        .multilineTextAlignment(.center)
                    Button(WatchLocalization.text("retry")) {
                        viewModel.retry()
                    }
                }
            }

            Button {
                onShowOtherStops()
            } label: {
                Label(WatchLocalization.text("other.stops"), systemImage: "list.bullet")
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private func routeName(
        for item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order
    ) -> String {
        if stop.id == "dormitory" || stop.id == "shuttlecock" {
            switch item.route.tag {
            case "DH": return WatchLocalization.text("stop.station")
            case "DY": return WatchLocalization.text("stop.terminal")
            case "DJ": return WatchLocalization.text("stop.jungang")
            case "C": return WatchLocalization.text("route.circular")
            default: return item.route.name
            }
        } else if stop.id == "station" {
            switch item.route.tag {
            case "C": return WatchLocalization.text("route.circular")
            case "DH": return WatchLocalization.text("route.direct")
            case "DJ": return WatchLocalization.text("stop.jungang")
            default: return item.route.name
            }
        }
        return WatchLocalization.text("route.direct")
    }

    private func timeLabel(
        for item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        guard let departureTime = formatter.date(from: item.time) else { return item.time }
        return departureTime.formatted(date: .omitted, time: .shortened)
    }
}
