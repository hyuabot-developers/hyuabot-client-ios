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
        Observable.combineLatest(
            ShuttleRealtimeData.shared.firstItem,
            ShuttleRealtimeData.shared.secondItem,
            ShuttleRealtimeData.shared.thirdItem,
            ShuttleRealtimeData.shared.fourthItem
        ).subscribe(onNext: { [weak self] first, second, third, fourth in
            guard let self = self else { return }
            let items = [first, second, third, fourth].compactMap { $0 }
            self.items = items
        }).disposed(by: disposeBag)
    }
    
    private let stop: String
    private let disposeBag = DisposeBag()
    @Published var items: [ShuttleRealtimePageWatchQuery.Data.Shuttle.Stop.Timetable.Destination.Entry] = []
    @Published var isLoading: Bool = false
}
