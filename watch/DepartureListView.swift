import SwiftUI
import RxSwift
import QueryAPI

struct DepartureListView: View {
    let stop: String
    @ObservedObject var viewModel: DepartureListViewModel
    
    init(stop: String) {
        self.stop = stop
        self.viewModel = DepartureListViewModel(stop: stop)
    }
    
    var body: some View {
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
    }
    
    func setRouteName(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) -> String {
        if (self.stop == "기숙사" || self.stop == "셔틀콕") {
            if (item.tag == "DH") { return "한대앞" }
            else if (item.tag == "DY") { return "예술인" }
            else if (item.tag == "DJ") { return "중앙역" }
            else if (item.tag == "C") { return "순환" }
        } else if (self.stop == "한대앞") {
            if (item.tag == "C") { return "순환" }
            else if (item.tag == "DH") { return "직행" }
            else if (item.tag == "DJ") { return "중앙역" }
        } else if (self.stop == "예술인" || self.stop == "중앙역") {
            return "직행"
        } else if (self.stop == "셔틀콕 건너편") {
            if (item.route.hasSuffix("D")) { return "기숙사" }
            else if (item.route.hasSuffix("S")) { return "셔틀콕" }
        }
        return ""
    }
    
    func setUITimeLabel(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let departureTime = dateFormatter.date(from: item.time)
        let hour = calendar.component(.hour, from: departureTime!)
        let minute = calendar.component(.minute, from: departureTime!)
        return String(format: "%02d시 %02d분", hour, minute)
    }
}
