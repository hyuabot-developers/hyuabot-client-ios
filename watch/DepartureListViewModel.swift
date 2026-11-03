import Api
import Combine
import Foundation

struct WatchDepartureItem: Hashable {
    let order: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order
    let labelKey: String?
}

@MainActor
final class DepartureListViewModel: ObservableObject {
    enum LoadState {
        case loading
        case loaded
        case empty
        case failed
    }

    @Published private(set) var items: [WatchDepartureItem] = []
    @Published private(set) var loadState: LoadState = .loading

    private let selectedStop: WatchShuttleStop
    private var pollingTask: Task<Void, Never>?

    init(stop: WatchShuttleStop) {
        selectedStop = stop
    }

    func start() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetch()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func retry() {
        loadState = .loading
        Task { await fetch() }
    }

    private func fetch() async {
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let response = try await Network.shared.client.fetch(query: ShuttleRealtimePageWatchQuery(
                stops: selectedStop.queryStops.map {
                    ShuttleStopInput(name: $0, limit: ShuttleLimitInput(destination: 1))
                },
                after: GraphQLNullable.some(formatter.string(from: .now))
            ))
            guard let data = response.data else {
                if items.isEmpty { loadState = .failed }
                return
            }

            var fetchedItems: [WatchDepartureItem] = []
            for queryStop in selectedStop.queryStops {
                let orders = data.shuttle.stops.first(where: { $0.name == queryStop })?.timetable.order ?? []
                for order in orders {
                    let after = WatchDestination.stopsAfter(queryStop, in: order.stops.map(\.stop))
                    guard WatchDestination.isDeparture(queryStop: queryStop, stopsAfterCurrent: after) else { continue }
                    fetchedItems.append(WatchDepartureItem(
                        order: order,
                        labelKey: WatchDestination.labelKey(
                            stopID: selectedStop.id,
                            queryStop: queryStop,
                            tag: order.route.tag,
                            stopsAfterCurrent: after
                        )
                    ))
                }
            }

            items = fetchedItems.sorted(by: { $0.order.time < $1.order.time })
            loadState = items.isEmpty ? .empty : .loaded
        } catch {
            if items.isEmpty { loadState = .failed }
        }
    }
}
