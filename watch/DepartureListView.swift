import SwiftUI
import RxSwift
import Api

struct DepartureListView: View {
    let stop: WatchShuttleStop
    let disposeBag = DisposeBag()
    @ObservedObject var viewModel: DepartureListViewModel
    
    init(stop: WatchShuttleStop) {
        self.stop = stop
        self.viewModel = DepartureListViewModel(stop: stop)
    }
    
    var body: some View {
        Group {
            if (viewModel.isLoading) {
                ProgressView()
            } else {
                if (viewModel.items.isEmpty) {
                    Text(WatchLocalization.text("no.scheduled.shuttle"))
                        .foregroundColor(.gray)
                        .font(.godo(size: 16, weight: .bold))
                        .padding()
                } else {
                    List {
                        ForEach(Array(viewModel.items.sorted(by: { $0.time < $1.time }).prefix(4)), id: \.self) { item in
                            HStack {
                                Text(setRouteName(item: item))
                                    .font(.godo(size: 16, weight: .bold))
                                Spacer()
                                Text(setUITimeLabel(item: item))
                                    .font(.godo(size: 16, weight: .regular))
                            }
                        }
                    }
                }
            }
        }.onAppear(perform: {
            self.startPolling()
        })
        .onDisappear(perform: {
            self.stopPolling()
        })
    }
    
    private func startPolling() {
        self.fetchShuttleRealtimeData()
        ShuttleRealtimeData.shared.subscription = Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.fetchShuttleRealtimeData()
            })
    }
    
    private func stopPolling() {
        ShuttleRealtimeData.shared.subscription?.dispose()
    }
    
    private func fetchShuttleRealtimeData() {
        let now = Date.now
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm" }
        let dataDelegate = ShuttleRealtimeData.shared
        Task {
            let response = try? await Network.shared.client.fetch(query: ShuttleRealtimePageWatchQuery(
                stops: stop.queryStops.map({ ShuttleStopInput(name: $0, limit: ShuttleLimitInput(destination: 1)) }),
                after: GraphQLNullable.some(timeFormatter.string(from: now)),
            ))
            if let data = response?.data {
                if data.shuttle.stops.isEmpty { return }
                if (self.stop.id == "dormitory") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "dormitory_o" })
                    dataDelegate.result.onNext(stop?.timetable.order)
                } else if (self.stop.id == "shuttlecock") {
                    let stop1 = data.shuttle.stops.first(where: { $0.name == "shuttlecock_o" })
                    let stop2 = data.shuttle.stops.first(where: { $0.name == "shuttlecock_i" })
                    dataDelegate.result.onNext((stop1?.timetable.order ?? []) + (stop2?.timetable.order ?? []))
                } else if (self.stop.id == "station") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "station" })
                    dataDelegate.result.onNext(stop?.timetable.order)
                } else if (self.stop.id == "terminal") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "terminal" })
                    dataDelegate.result.onNext(stop?.timetable.order)
                } else if (self.stop.id == "jungang") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "jungang_stn" })
                    dataDelegate.result.onNext(stop?.timetable.order)
                }
            }
            dataDelegate.isLoading.onNext(false)
        }
    }
    
    func setRouteName(item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order) -> String {
        if (self.stop.id == "dormitory" || self.stop.id == "shuttlecock") {
            if (item.route.tag == "DH") { return WatchLocalization.text("stop.station") }
            else if (item.route.tag == "DY") { return WatchLocalization.text("stop.terminal") }
            else if (item.route.tag == "DJ") { return WatchLocalization.text("stop.jungang") }
            else if (item.route.tag == "C") { return WatchLocalization.text("route.circular") }
        } else if (self.stop.id == "station") {
            if (item.route.tag == "C") { return WatchLocalization.text("route.circular") }
            else if (item.route.tag == "DH") { return WatchLocalization.text("route.direct") }
            else if (item.route.tag == "DJ") { return WatchLocalization.text("stop.jungang") }
        } else if (self.stop.id == "terminal" || self.stop.id == "jungang") {
            return WatchLocalization.text("route.direct")
        }
        return ""
    }
    
    private func isAfterNow(item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date.now
        let nowString = dateFormatter.string(from: now)
        return nowString < item.time
    }
    
    private func setUITimeLabel(item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        guard let departureTime = dateFormatter.date(from: item.time) else { return item.time }
        return departureTime.formatted(date: .omitted, time: .shortened)
    }
}
