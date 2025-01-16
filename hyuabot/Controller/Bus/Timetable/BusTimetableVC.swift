import UIKit
import RxSwift
import QueryAPI

class BusTimetableVC: UIViewController {
    let stopID: Int
    let routes: [Int]
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
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "shuttle.timetable.loading")
        $0.font = .godo(size: 16, weight: .regular)
        $0.textColor = .label
    }
    private lazy var loadingStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [loadingSpinner, loadingLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.backgroundColor = .systemBackground
        return stackView
    }()
    private lazy var loadingView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.addSubview(loadingStackView)
        loadingStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init(stopID: Int, routes: [Int], title: String.LocalizationValue) {
        self.stopID = stopID
        self.routes = routes
        self.navigationTitle = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
        self.fetchBusTimetable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func fetchBusTimetable() {
        BusTimetableData.shared.isLoading.onNext(true)
        Network.shared.client.fetch(query: BusTimetablePageQuery(routes: self.routes, stopID: self.stopID)) { result in
            if case let .success(response) = result {
                var result: [BusTimetableItem] = []
                response.data?.bus.first?.routes.forEach { route in
                    route.timetable.forEach { timetable in
                        result.append(BusTimetableItem(routeName: route.info.name, timetable: timetable))
                    }
                }
                BusTimetableData.shared.timetable.onNext(result.sorted(by: { $0.timetable.time < $1.timetable.time }))
            }
        }
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(viewPager)
        self.view.addSubview(loadingView)
        self.navigationItem.title = String(localized: navigationTitle)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(viewPager)
        }
    }
    
    private func observeSubjects() {
        BusTimetableData.shared.timetable.subscribe(onNext: { timetable in
            BusTimetableData.shared.weekdays.onNext(timetable.filter { $0.timetable.weekdays == "weekdays" })
            BusTimetableData.shared.saturdays.onNext(timetable.filter { $0.timetable.weekdays == "saturday" })
            BusTimetableData.shared.sundays.onNext(timetable.filter { $0.timetable.weekdays == "sunday" })
            BusTimetableData.shared.isLoading.onNext(false)
        }).disposed(by: disposeBag)
        BusTimetableData.shared.weekdays.subscribe(onNext: { weekdays in
            self.weekdaysVC.reload()
        }).disposed(by: disposeBag)
        BusTimetableData.shared.saturdays.subscribe(onNext: { weekends in
            self.saturdaysVC.reload()
        }).disposed(by: disposeBag)
        BusTimetableData.shared.sundays.subscribe(onNext: { weekends in
            self.sundaysVC.reload()
        }).disposed(by: disposeBag)
        BusTimetableData.shared.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
    }
}
