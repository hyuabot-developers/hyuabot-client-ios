import SwiftUI
import RxSwift
import QueryAPI

class DepartureListViewModel: ObservableObject {
    init(stop: String) {
        self.stop = stop
        ShuttleRealtimeData.shared.isLoading
            .subscribe(onNext: { [weak self] loading in
                guard let self = self else { return }
                self.isLoading = loading
            })
            .disposed(by: disposeBag)
        if (self.stop == "기숙사") {
            ShuttleRealtimeData.shared.shuttleDormitoryData
                .subscribe(onNext: { [weak self] shuttleData in
                    guard let self = self else { return }
                    self.items = shuttleData ?? []
                })
                .disposed(by: disposeBag)
        } else if (self.stop == "셔틀콕") {
            ShuttleRealtimeData.shared.shuttleShuttlecockData
                .subscribe(onNext: { [weak self] shuttleData in
                    guard let self = self else { return }
                    self.items = shuttleData ?? []
                })
                .disposed(by: disposeBag)
        } else if (self.stop == "한대앞") {
            ShuttleRealtimeData.shared.shuttleStationData
                .subscribe(onNext: { [weak self] shuttleData in
                    guard let self = self else { return }
                    self.items = shuttleData ?? []
                })
                .disposed(by: disposeBag)
        } else if (self.stop == "예술인") {
            ShuttleRealtimeData.shared.shuttleTerminalData
                .subscribe(onNext: { [weak self] shuttleData in
                    guard let self = self else { return }
                    self.items = shuttleData ?? []
                })
                .disposed(by: disposeBag)
        } else if (self.stop == "중앙역") {
            ShuttleRealtimeData.shared.shuttleJungangStatioData
                .subscribe(onNext: { [weak self] shuttleData in
                    guard let self = self else { return }
                    self.items = shuttleData ?? []
                })
                .disposed(by: disposeBag)
        } else if (self.stop == "셔틀콕 건너편") {
            ShuttleRealtimeData.shared.shuttleShuttlecockOppositeData
                .subscribe(onNext: { [weak self] shuttleData in
                    guard let self = self else { return }
                    self.items = shuttleData ?? []
                })
                .disposed(by: disposeBag)
        }
    }
    
    private let stop: String
    private let disposeBag = DisposeBag()
    @Published var items: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @Published var isLoading: Bool = false
}
