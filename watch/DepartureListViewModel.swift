import Api
import RxSwift
import SwiftUI

class DepartureListViewModel: ObservableObject {
    init(stop: WatchShuttleStop) {
        self.stop = stop
        ShuttleRealtimeData.shared.isLoading
            .subscribe(onNext: { [weak self] loading in
                guard let self else { return }
                isLoading = loading
            })
            .disposed(by: disposeBag)
        ShuttleRealtimeData.shared.result
            .subscribe(onNext: { [weak self] result in
                if let result {
                    self?.items = result
                }
            }).disposed(by: disposeBag)
    }

    private let stop: WatchShuttleStop
    private let disposeBag = DisposeBag()
    @Published var items: [ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order] = []
    @Published var isLoading: Bool = false
}
