import UIKit
import RxSwift
import Api

class ShuttleTimetableVC: UIViewController {
    private let stopID: String.LocalizationValue
    private let destination: String.LocalizationValue
    private let disposeBag = DisposeBag()
    private lazy var weekdaysVC = ShuttleTimetableTabVC(isWeekdays: true, showViaVC: openShuttleViaVC)
    private lazy var weekendsVC = ShuttleTimetableTabVC(isWeekdays: false, showViaVC: openShuttleViaVC)
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 60, spacing: 0), navigationBarEnabled: true)
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "shuttle.timetable.weekdays")),
            TabItem(title: String(localized: "shuttle.timetable.weekends"))
        ]
        viewPager.contentView.pages = [weekdaysVC.view, weekendsVC.view]
        return viewPager
    }()
    private lazy var filterButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "line.3.horizontal.decrease")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openFilterVC), for: .touchUpInside)
    }
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
    
    
    init(stopID: String.LocalizationValue, destination: String.LocalizationValue) {
        self.stopID = stopID
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        ShuttleTimetableData.shared.options.onNext(ShuttleTimetableOptions(
            start: self.stopID,
            end: self.destination,
            date: Date.now,
            period: nil
        ))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logScreenView(.shuttleTimetable)
        self.showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("shuttle.timetable") else { return }
        let isLoaded = (try? ShuttleTimetableData.shared.weekdays.value())?.isEmpty == false
        if isLoaded {
            presentTimetableCoachMarks()
        } else {
            ShuttleTimetableData.shared.weekdays
                .filter { !$0.isEmpty }
                .take(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self?.presentTimetableCoachMarks()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    private func presentTimetableCoachMarks() {
        let items: [CoachMarkItem] = [
            CoachMarkItem(
                id: "shuttle.timetable.tabs",
                targetView: viewPager.tabView,
                title: String(localized: "coach.shuttle.timetable.tabs.title"),
                message: String(localized: "coach.shuttle.timetable.tabs.message")
            ),
            CoachMarkItem(
                id: "shuttle.timetable.row",
                targetView: viewPager.contentView,
                title: String(localized: "coach.shuttle.timetable.row.title"),
                message: String(localized: "coach.shuttle.timetable.row.message")
            ),
            CoachMarkItem(
                id: "shuttle.timetable.filter",
                targetView: filterButton,
                title: String(localized: "coach.shuttle.timetable.filter.title"),
                message: String(localized: "coach.shuttle.timetable.filter.message")
            ),
        ]
        presentCoachMarks(pageId: "shuttle.timetable", items: items)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ShuttleTimetableData.shared.options.onNext(nil)
        ShuttleTimetableData.shared.timetable.onNext([])
        ShuttleTimetableData.shared.weekdays.onNext([])
        ShuttleTimetableData.shared.weekends.onNext([])
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(viewPager)
        self.view.addSubview(filterButton)
        self.view.addSubview(loadingView)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.filterButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.width.height.equalTo(50)
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(viewPager)
        }
    }
    
    private func observeSubjects() {
        ShuttleTimetableData.shared.options.subscribe(onNext: { options in
            guard let options = options else { return }
            self.navigationItem.title = "\(String(localized: options.start)) → \(String(localized: options.end))"
            // Query the timetable data
            let (stopID, destinations) = self.resolveStopAndDestination(options: options)
            self.fetchTimetable(options: options, stopID: stopID, destinations: destinations)
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.timetable.subscribe(onNext: { timetable in
            ShuttleTimetableData.shared.weekdays.onNext(timetable.filter { $0.weekday })
            ShuttleTimetableData.shared.weekends.onNext(timetable.filter { !$0.weekday })
            ShuttleTimetableData.shared.isLoading.onNext(false)
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.weekdays.subscribe(onNext: { weekdays in
            self.weekdaysVC.reload()
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.weekends.subscribe(onNext: { weekends in
            self.weekendsVC.reload()
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
    }
    
    private func resolveStopAndDestination(options: ShuttleTimetableOptions) -> (String, [String]) {
        var stopID: String = ""
        var destinations: [String] = []
        if options.start == "shuttle.stop.dormitory.out" {
            stopID = "dormitory_o"
            if options.end == "shuttle.destination.shorten.station" {
                destinations = ["STATION"]
            } else if options.end == "shuttle.destination.shorten.jungang_station" {
                destinations = ["JUNGANG"]
            } else if options.end == "shuttle.destination.shorten.terminal" {
                destinations = ["TERMINAL"]
            }
        } else if options.start == "shuttle.stop.shuttlecock.out" {
            stopID = "shuttlecock_o"
            if options.end == "shuttle.destination.shorten.station" {
                destinations = ["STATION"]
            } else if options.end == "shuttle.destination.shorten.jungang_station" {
                destinations = ["JUNGANG"]
            } else if options.end == "shuttle.destination.shorten.terminal" {
                destinations = ["TERMINAL"]
            }
        } else if options.start == "shuttle.stop.station" {
            stopID = "station"
            if options.end == "shuttle.destination.shorten.campus" {
                destinations = ["CAMPUS"]
            } else if options.end == "shuttle.destination.shorten.jungang_station" {
                destinations = ["JUNGANG"]
            } else if options.end == "shuttle.destination.shorten.terminal" {
                destinations = ["TERMINAL"]
            }
        } else if options.start == "shuttle.stop.terminal" {
            stopID = "terminal"
            destinations = ["CAMPUS"]
        } else if options.start == "shuttle.stop.jungang.station" {
            stopID = "jungang_stn"
            destinations = ["CAMPUS"]
        } else if options.start == "shuttle.stop.shuttlecock.in" {
            stopID = "shuttlecock_i"
            destinations = ["CAMPUS"]
        }
        return (stopID, destinations)
    }
    
    private func fetchTimetable(options: ShuttleTimetableOptions, stopID: String, destinations: [String]) {
        if options.period == nil {
            guard let date = options.date else { return }
            let dateFormatter = DateFormatter().then {
                $0.dateFormat = "yyyy-MM-dd"
            }
            ShuttleTimetableData.shared.isLoading.onNext(true)
            Task {
                let response = try? await Network.shared.client.fetch(query: ShuttleTimetablePeriodQuery(date: dateFormatter.string(from: date)))
                guard let period = response?.data?.shuttle.period?.type else {
                    publishTimetable([])
                    return
                }
                let timetableResponse = try? await Network.shared.client.fetch(query: ShuttleTimetablePageQuery(period: [period], stopID: stopID, destination: destinations))
                publishTimetable(timetableResponse?.data?.shuttle.stops.first?.timetable.order ?? [])
            }
        } else {
            guard let period = resolvedPeriod(options.period) else {
                ShuttleTimetableData.shared.timetable.onNext([])
                return
            }
            ShuttleTimetableData.shared.isLoading.onNext(true)
            Task {
                let timetableResponse = try? await Network.shared.client.fetch(query: ShuttleTimetablePageQuery(period: [period], stopID: stopID, destination: destinations))
                publishTimetable(timetableResponse?.data?.shuttle.stops.first?.timetable.order ?? [])
            }
        }
    }

    private func resolvedPeriod(_ period: String.LocalizationValue?) -> String? {
        if period == "shuttle.period.semester" {
            return "semester"
        } else if period == "shuttle.period.vacation" {
            return "vacation"
        } else if period == "shuttle.period.vacation_session" {
            return "vacation_session"
        }
        return nil
    }

    private func publishTimetable(_ timetable: [ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order]) {
        DispatchQueue.main.async {
            ShuttleTimetableData.shared.timetable.onNext(timetable)
        }
    }
    
    private func openShuttleViaVC(_ item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                min(vc.sheetHeight, context.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func openFilterVC() {
        AnalyticsManager.logSelect(.shuttleOpenFilter)
        let vc = ShuttleTimetableFilterVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in
                return 800
            })]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
}
