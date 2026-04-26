import SwiftUI
import RxSwift
import Api

class DepartureListViewModel: ObservableObject {
    init(stop: String) {
        self.stop = stop
        ShuttleRealtimeData.shared.isLoading
            .subscribe(onNext: { [weak self] loading in
                guard let self = self else { return }
                self.isLoading = loading
            })
            .disposed(by: disposeBag)
        ShuttleRealtimeData.shared.result
            .subscribe(onNext: { [weak self] result in
                if let result = result {
                    self?.items = result
                }
            }).disposed(by: disposeBag)
    }
    
    private let stop: String
    private let disposeBag = DisposeBag()
    @Published var items: [ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Order] = []
    @Published var isLoading: Bool = false
}
