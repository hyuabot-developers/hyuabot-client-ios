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
    
    init(timetableTitle: String.LocalizationValue, heading: SubwayHeadingEnum) {
        self.timetableTitle = timetableTitle
        self.heading = heading
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logScreenView(.subwayTimetable)
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
                    await MainActor.run {
                        if let timetable = response?.data?.subway.first?.timetable {
                            SubwayTimetableData.shared.timetable.onNext(timetable)
                        } else {
                            SubwayTimetableData.shared.isLoading.onNext(false)
                        }
                    }
                }
            } else if (self.timetableTitle == "subway.realtime.section.suin.up") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K251", direction: ["up"]))
                    await MainActor.run {
                        if let timetable = response?.data?.subway.first?.timetable {
                            SubwayTimetableData.shared.timetable.onNext(timetable)
                        } else {
                            SubwayTimetableData.shared.isLoading.onNext(false)
                        }
                    }
                }
            }
        } else {
            if (self.timetableTitle == "subway.realtime.section.4.down") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K449", direction: ["down"]))
                    await MainActor.run {
                        if let timetable = response?.data?.subway.first?.timetable {
                            SubwayTimetableData.shared.timetable.onNext(timetable)
                        } else {
                            SubwayTimetableData.shared.isLoading.onNext(false)
                        }
                    }
                }
            } else if (self.timetableTitle == "subway.realtime.section.suin.down") {
                Task {
                    let response = try? await Network.shared.client.fetch(query: SubwayTimetablePageQuery(station: "K251", direction: ["down"]))
                    await MainActor.run {
                        if let timetable = response?.data?.subway.first?.timetable {
                            SubwayTimetableData.shared.timetable.onNext(timetable)
                        } else {
                            SubwayTimetableData.shared.isLoading.onNext(false)
                        }
                    }
                }
            }
        }
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(viewPager)
        self.navigationItem.title = String(localized: timetableTitle)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func observeSubjects() {
        SubwayTimetableData.shared.timetable.subscribe(onNext: { [weak self] timetable in
            guard let self = self else { return }
            let isLoading = (try? SubwayTimetableData.shared.isLoading.value()) ?? false
            if isLoading && timetable.isEmpty {
                return
            }
            SubwayTimetableData.shared.timetableWeekdays.onNext(timetable.filter { $0.weekday == "weekdays" }.sorted(by: { self.sortableDepartureTime($0.time) < self.sortableDepartureTime($1.time) }))
            SubwayTimetableData.shared.timetableWeekends.onNext(timetable.filter { $0.weekday == "weekends" }.sorted(by: { self.sortableDepartureTime($0.time) < self.sortableDepartureTime($1.time) }))
            SubwayTimetableData.shared.isLoading.onNext(false)
            self.weekdaysVC.reload()
            self.weekendsVC.reload()
        }).disposed(by: disposeBag)
    }
    
    private func sortableDepartureTime(_ time: LocalTime) -> String {
        guard let date = time.toLocalTimeOrNil() else { return "99:99" }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour,
              let minute = components.minute else { return "99:99" }
        if hour < 4 {
            return String(format: "%02d:%02d", hour + 24, minute)
        }
        return String(format: "%02d:%02d", hour, minute)
    }
}
