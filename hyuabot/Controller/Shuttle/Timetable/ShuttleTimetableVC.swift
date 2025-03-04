import UIKit
import RxSwift
import QueryAPI

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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
        ShuttleTimetableData.shared.options.onNext(ShuttleTimetableOptions(
            start: self.stopID,
            end: self.destination,
            date: Date.now,
            period: nil
        ))
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
            var stopID: String = ""
            var tags: [String] = []
            if options.start == "shuttle.stop.dormitory.out" {
                stopID = "dormitory_o"
                if options.end == "shuttle.destination.shorten.station" {
                    tags = ["DH", "DJ", "C"]
                } else if options.end == "shuttle.destination.shorten.jungang_station" {
                    tags = ["DJ"]
                } else if options.end == "shuttle.destination.shorten.terminal" {
                    tags = ["DY", "C"]
                }
            } else if options.start == "shuttle.stop.shuttlecock.out" {
                stopID = "shuttlecock_o"
                if options.end == "shuttle.destination.shorten.station" {
                    tags = ["DH", "DJ", "C"]
                } else if options.end == "shuttle.destination.shorten.jungang_station" {
                    tags = ["DJ"]
                } else if options.end == "shuttle.destination.shorten.terminal" {
                    tags = ["DY", "C"]
                }
            } else if options.start == "shuttle.stop.station" {
                stopID = "station"
                if options.end == "shuttle.destination.shorten.campus" {
                    tags = ["DH", "DJ", "C"]
                } else if options.end == "shuttle.destination.shorten.jungang_station" {
                    tags = ["DJ"]
                } else if options.end == "shuttle.destination.shorten.terminal" {
                    tags = ["C"]
                }
            } else if options.start == "shuttle.stop.terminal" {
                stopID = "terminal"
                tags = ["DY", "C"]
            } else if options.start == "shuttle.stop.jungang.station" {
                stopID = "jungang_stn"
                tags = ["DJ"]
            } else if options.start == "shuttle.stop.shuttlecock.in" {
                stopID = "shuttlecock_i"
                tags = ["DH", "DY", "DJ", "C"]
            }
            if options.period == nil {
                guard let date = options.date else { return }
                let dateFormatter = DateFormatter().then {
                    $0.dateFormat = "yyyy-MM-dd"
                }
                ShuttleTimetableData.shared.isLoading.onNext(true)
                Network.shared.client.fetch(query: ShuttleTimetablePeriodQuery(shuttleDate: dateFormatter.string(from: date))) { periodQuery in
                    if case .success(let response) = periodQuery {
                        let periods = response.data?.shuttle.period.map { $0.type } ?? []
                        Network.shared.client.fetch(query: ShuttleTimetablePageQuery(period: periods, stopID: stopID, tag: tags)) { timetableQuery in
                            if case .success(let response) = timetableQuery {
                                ShuttleTimetableData.shared.timetable.onNext(response.data?.shuttle.timetable ?? [])
                            }
                        }
                    }
                }
            } else {
                var period = ""
                if options.period == "shuttle.period.semester" {
                    period = "semester"
                } else if options.period == "shuttle.period.vacation" {
                    period = "vacation"
                } else if options.period == "shuttle.period.vacation_session" {
                    period = "vacation_session"
                }
                ShuttleTimetableData.shared.isLoading.onNext(true)
                Network.shared.client.fetch(query: ShuttleTimetablePageQuery(period: [period], stopID: stopID, tag: tags)) { timetableQuery in
                    if case .success(let response) = timetableQuery {
                        ShuttleTimetableData.shared.timetable.onNext(response.data?.shuttle.timetable ?? [])
                    }
                }
            }
        }).disposed(by: disposeBag)
        ShuttleTimetableData.shared.timetable.subscribe(onNext: { timetable in
            ShuttleTimetableData.shared.weekdays.onNext(timetable.filter { $0.weekdays })
            ShuttleTimetableData.shared.weekends.onNext(timetable.filter { !$0.weekdays })
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
    
    private func openShuttleViaVC(_ item: ShuttleTimetablePageQuery.Data.Shuttle.Timetable) {
        let vc = ShuttleViaVC(timetableItem: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func openFilterVC() {
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
