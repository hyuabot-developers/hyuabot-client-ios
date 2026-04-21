import UIKit
import RxSwift
import Api

class SubwayTimetableVC: UIViewController {
    private let timetableTitle: String.LocalizationValue
    private let heading: SubwayHeadingEnum
    private let disposeBag = DisposeBag()
    private lazy var weekdaysVC = SubwayTimetableTabVC(heading: self.heading, isWeekdays: true)
    private lazy var weekendsVC = SubwayTimetableTabVC(heading: self.heading, isWeekdays: false)
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fillEqually(height: 60, spacing: 0), navigationBarEnabled: true)
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "subway.timetable.weekdays")),
            TabItem(title: String(localized: "subway.timetable.weekends"))
        ]
        viewPager.contentView.pages = [weekdaysVC.view, weekendsVC.view]
        return viewPager
    }()
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "subway.timetable.loading")
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
    
    init(timetableTitle: String.LocalizationValue, heading: SubwayHeadingEnum) {
        self.timetableTitle = timetableTitle
        self.heading = heading
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
        self.fetchSubwayTimetable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func fetchSubwayTimetable() {
        SubwayTimetableData.shared.isLoading.onNext(true)
        if (self.heading == .up) {
            if (self.timetableTitle == "subway.realtime.section.4.up") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K449", direction: ["up"]))
                    if let timetable = response?.data?.subway.first?.timetable {
                        SubwayTimetableData.shared.timetable.onNext(timetable)
                    }
                }
            } else if (self.timetableTitle == "subway.realtime.section.suin.up") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K251", direction: ["up"]))
                    if let timetable = response?.data?.subway.first?.timetable {
                        SubwayTimetableData.shared.timetable.onNext(timetable)
                    }
                }
            }
        } else {
            if (self.timetableTitle == "subway.realtime.section.4.down") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K449", direction: ["down"]))
                    if let timetable = response?.data?.subway.first?.timetable {
                        SubwayTimetableData.shared.timetable.onNext(timetable)
                    }
                }
            } else if (self.timetableTitle == "subway.realtime.section.suin.down") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K251", direction: ["down"]))
                    if let timetable = response?.data?.subway.first?.timetable {
                        SubwayTimetableData.shared.timetable.onNext(timetable)
                    }
                }
            }
        }
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(viewPager)
        self.view.addSubview(loadingView)
        self.navigationItem.title = String(localized: timetableTitle)
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
        SubwayTimetableData.shared.timetable.subscribe(onNext: { timetable in
            SubwayTimetableData.shared.isLoading.onNext(false)
            SubwayTimetableData.shared.timetableWeekdays.onNext(timetable.filter { $0.weekday == "weekdays" })
            SubwayTimetableData.shared.timetableWeekdays.onNext(timetable.filter { $0.weekday == "weekends" })
            self.weekdaysVC.reload()
            self.weekendsVC.reload()
        }).disposed(by: disposeBag)
        SubwayTimetableData.shared.isLoading.subscribe(onNext: { isLoading in
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
