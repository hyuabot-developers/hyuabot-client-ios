import Api
import Combine
import Foundation

@MainActor
final class DepartureListViewModel: ObservableObject {
    enum LoadState {
        case loading
        case loaded
        case empty
        case failed
    }

    @Published private(set) var items: [ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order] = []
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

            let fetchedItems: [ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order]
            switch selectedStop.id {
            case "dormitory":
                fetchedItems = data.shuttle.stops.first(where: { $0.name == "dormitory_o" })?.timetable.order ?? []
            case "shuttlecock":
                let outgoing = data.shuttle.stops.first(where: { $0.name == "shuttlecock_o" })?.timetable.order ?? []
                let incoming = data.shuttle.stops.first(where: { $0.name == "shuttlecock_i" })?.timetable.order ?? []
                fetchedItems = outgoing + incoming
            case "station":
                fetchedItems = data.shuttle.stops.first(where: { $0.name == "station" })?.timetable.order ?? []
            case "terminal":
                fetchedItems = data.shuttle.stops.first(where: { $0.name == "terminal" })?.timetable.order ?? []
            case "jungang":
                fetchedItems = data.shuttle.stops.first(where: { $0.name == "jungang_stn" })?.timetable.order ?? []
            default:
                fetchedItems = []
            }

            items = fetchedItems.sorted(by: { $0.time < $1.time })
            loadState = items.isEmpty ? .empty : .loaded
        } catch {
            if items.isEmpty { loadState = .failed }
        }
    }
}
