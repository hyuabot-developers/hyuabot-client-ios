import Api
import RxSwift
import UIKit

class BusTimetableVC: UIViewController {
    let stopID: Int32
    let routes: [Int32]
    let navigationTitle: String.LocalizationValue
    private let disposeBag = DisposeBag()
    private let weekdaysVC = BusTimetableTabVC(timetableEnum: .weekdays)
    private let saturdaysVC = BusTimetableTabVC(timetableEnum: .saturdays)
    private let sundaysVC = BusTimetableTabVC(timetableEnum: .sundays)
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 60, spacing: 0), navigationBarEnabled: true)
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "bus.timetable.weekdays")),
            TabItem(title: String(localized: "bus.timetable.saturdays")),
            TabItem(title: String(localized: "bus.timetable.sundays"))
        ]
        viewPager.contentView.pages = [weekdaysVC.view, saturdaysVC.view, sundaysVC.view]
        return viewPager
    }()

    required init(stopID: Int32, routes: [Int32], title: String.LocalizationValue) {
        self.stopID = stopID
        self.routes = routes
        navigationTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.busTimetable)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
        fetchBusTimetable()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func fetchBusTimetable() {
        BusTimetableData.shared.isLoading.onNext(true)
        Task {
            let response = try? await Network.shared.client.fetch(query: BusTimetablePageQuery(routeStops: self.routes.map {
                BusRouteStopInput(route: $0, stop: self.stopID)
            }))
            await MainActor.run {
                if let data = response?.data {
                    BusTimetableData.shared.timetable.onNext(data.bus.map { bus in
                        bus.timetable.map { timetable in
                            BusTimetableItem(route: bus.route.name, weekdays: timetable.weekday, time: timetable.time.toLocalTime())
                        }
                    }.flatMap {
                        $0
                    })
                } else {
                    BusTimetableData.shared.isLoading.onNext(false)
                }
            }
        }
    }

    private func setupUI() {
        view.backgroundColor = .hanyangBlue
        view.addSubview(viewPager)
        navigationItem.title = String(localized: navigationTitle)
        viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func observeSubjects() {
        BusTimetableData.shared.timetable.subscribe(onNext: { timetable in
            let isLoading = (try? BusTimetableData.shared.isLoading.value()) ?? false
            if isLoading, timetable.isEmpty {
                return
            }
            BusTimetableData.shared.weekdays.onNext(timetable.filter { $0.weekdays == "weekdays" }.sorted())
            BusTimetableData.shared.saturdays.onNext(timetable.filter { $0.weekdays == "saturday" }.sorted())
            BusTimetableData.shared.sundays.onNext(timetable.filter { $0.weekdays == "sunday" }.sorted())
            BusTimetableData.shared.isLoading.onNext(false)
        }).disposed(by: disposeBag)
        BusTimetableData.shared.weekdays.subscribe(onNext: { _ in
            self.weekdaysVC.reload()
        }).disposed(by: disposeBag)
        BusTimetableData.shared.saturdays.subscribe(onNext: { _ in
            self.saturdaysVC.reload()
        }).disposed(by: disposeBag)
        BusTimetableData.shared.sundays.subscribe(onNext: { _ in
            self.sundaysVC.reload()
        }).disposed(by: disposeBag)
    }
}
