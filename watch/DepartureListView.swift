import SwiftUI
import RxSwift
import Api
import RxSwift

struct DepartureListView: View {
    let stop: String
    let disposeBag = DisposeBag()
    @ObservedObject var viewModel: DepartureListViewModel
    
    init(stop: String) {
        self.stop = stop
        self.viewModel = DepartureListViewModel(stop: stop)
    }
    
    var body: some View {
        Group {
            if (viewModel.isLoading) {
                ProgressView()
            } else {
                if (viewModel.items.isEmpty) {
                    Text("도착 예정인 셔틀이 없습니다.")
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
                stops: getStops().map({ ShuttleStopInput(name: $0, limit: ShuttleLimitInput(destination: 1)) }),
                after: GraphQLNullable.some(timeFormatter.string(from: now)),
            ))
            if let data = response?.data {
                if data.shuttle.stops.isEmpty { return }
                if (self.stop == "기숙사") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "dormitory_o" })
                    dataDelegate.firstItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "STATION" })?.entries.first)
                    dataDelegate.secondItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "TERMINAL" })?.entries.first)
                    dataDelegate.thirdItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "JUNGANG" })?.entries.first)
                    dataDelegate.fourthItem.onNext(nil)
                } else if (self.stop == "셔틀콕") {
                    let stop1 = data.shuttle.stops.first(where: { $0.name == "shuttlecock_o" })
                    let stop2 = data.shuttle.stops.first(where: { $0.name == "shuttlecock_i" })
                    dataDelegate.firstItem.onNext(stop1?.timetable.destination.first(where: { $0.destination == "STATION" })?.entries.first)
                    dataDelegate.secondItem.onNext(stop1?.timetable.destination.first(where: { $0.destination == "TERMINAL" })?.entries.first)
                    dataDelegate.thirdItem.onNext(stop1?.timetable.destination.first(where: { $0.destination == "JUNGANG" })?.entries.first)
                    dataDelegate.fourthItem.onNext(stop2?.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.first)
                } else if (self.stop == "한대앞") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "station" })
                    dataDelegate.firstItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.first)
                    dataDelegate.secondItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "TERMINAL" })?.entries.first)
                    dataDelegate.thirdItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "JUNGANG" })?.entries.first)
                    dataDelegate.fourthItem.onNext(nil)
                } else if (self.stop == "예술인") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "terminal" })
                    dataDelegate.firstItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.first)
                    dataDelegate.secondItem.onNext(nil)
                    dataDelegate.thirdItem.onNext(nil)
                    dataDelegate.fourthItem.onNext(nil)
                } else if (self.stop == "중앙역") {
                    let stop = data.shuttle.stops.first(where: { $0.name == "jungang_stn" })
                    dataDelegate.firstItem.onNext(stop?.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.first)
                    dataDelegate.secondItem.onNext(nil)
                    dataDelegate.thirdItem.onNext(nil)
                    dataDelegate.fourthItem.onNext(nil)
                }
            }
            dataDelegate.isLoading.onNext(false)
        }
    }
    
    func setRouteName(item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> String {
        if (self.stop == "기숙사" || self.stop == "셔틀콕") {
            if (item.route.tag == "DH") { return "한대앞" }
            else if (item.route.tag == "DY") { return "예술인" }
            else if (item.route.tag == "DJ") { return "중앙역" }
            else if (item.route.tag == "C") { return "순환" }
        } else if (self.stop == "한대앞") {
            if (item.route.tag == "C") { return "순환" }
            else if (item.route.tag == "DH") { return "직행" }
            else if (item.route.tag == "DJ") { return "중앙역" }
        } else if (self.stop == "예술인" || self.stop == "중앙역") {
            return "직행"
        } else if (self.stop == "셔틀콕 건너편") {
            if (item.route.name.hasSuffix("D")) { return "기숙사" }
            else if (item.route.name.hasSuffix("S")) { return "셔틀콕" }
        }
        return ""
    }
    
    private func isAfterNow(item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date.now
        let nowString = dateFormatter.string(from: now)
        return nowString < item.time
    }
    
    private func getStops() -> [String] {
        switch self.stop {
            case "기숙사":
                return ["dormitory_o"]
            case "셔틀콕":
                return ["shuttlecock_o", "shuttlecock_i"]
            case "한대앞":
                return ["station"]
            case "예술인":
                return ["terminal"]
            case "중앙역":
                return ["jungang_stn"]
            default:
                return []
        }
    }
    
    private func setUITimeLabel(item: ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: item.time)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        return String(format: "%02d시 %02d분", hour, minute)
    }
}
