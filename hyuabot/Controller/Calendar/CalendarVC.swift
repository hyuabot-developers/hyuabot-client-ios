import UIKit
import RxSwift
import RealmSwift
import QueryAPI

class CalendarVC: UIViewController {
    private let disposeBag = DisposeBag()
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private let currentMonthSubject = BehaviorSubject<Foundation.Date>(value: Date())
    private let eventSubject = BehaviorSubject<[Event]>(value: [])
    private let currentMonthEventSubject = BehaviorSubject<[Event]>(value: [])
    private let datetimeFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }
    private let dateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd"
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }
    private var notificationToken: NotificationToken?

    private lazy var calenadrView = {
        let calendarView = UICalendarView()
        calendarView.delegate = self
        calendarView.selectionBehavior = .none
        calendarView.tintColor = .plainButtonText
        return calendarView
    }()
    private let headerLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "event.header.title")
    }
    private lazy var monthEventView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(CalendarEventCellView.self, forCellReuseIdentifier: CalendarEventCellView.reuseIdentifier)
    }
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "contact.database.loading")
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
    
    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.updateEventVerion()
        self.observeSubjects()
    }
    
    private func setupUI() {
        self.view.addSubview(self.calenadrView)
        self.view.addSubview(self.loadingView)
        self.view.addSubview(self.headerLabel)
        self.view.addSubview(self.monthEventView)
        self.navigationItem.title = String(localized: "tabbar.calendar")
        self.calenadrView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(600)
        }
        self.headerLabel.snp.makeConstraints { make in
            make.top.equalTo(self.calenadrView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.monthEventView.snp.makeConstraints { make in
            make.top.equalTo(self.headerLabel.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func observeSubjects() {
        notificationToken = Database.shared.database.objects(Event.self).observe { [weak self] changes in
            switch changes {
            case .initial(let results):
                self?.eventSubject.onNext(results.map { $0 })
            case .update(_, let deletions, let insertions, let modifications):
                if deletions.count > 0 || insertions.count > 0 || modifications.count > 0 {
                    self?.eventSubject.onNext(Database.shared.database.objects(Event.self).map { $0 })
                }
            default:
                break
            }
        }
        self.eventSubject.subscribe(onNext: { [weak self] allEvents in
            guard let self = self else { return }
            guard let currentMonth = try? self.currentMonthSubject.value() else { return }
            let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentMonth))
            let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth!)
            let startOfMonthString = self.dateFormatter.string(from: startOfMonth!)
            let endOfMonthString = self.dateFormatter.string(from: endOfMonth!)
            self.currentMonthEventSubject.onNext(allEvents.filter { event in
                return event.endDate >= startOfMonthString && event.startDate < endOfMonthString
            })
        }).disposed(by: disposeBag)
        self.currentMonthEventSubject.subscribe(onNext: { [weak self] events in
            guard let self = self else { return }
            self.monthEventView.reloadData()
        }).disposed(by: disposeBag)
        self.currentMonthSubject.subscribe(onNext: { [weak self] currentMonth in
            guard let self = self else { return }
            guard let allEvents = try? self.eventSubject.value() else { return }
            let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentMonth))
            let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth!)
            let startOfMonthString = self.dateFormatter.string(from: startOfMonth!)
            let endOfMonthString = self.dateFormatter.string(from: endOfMonth!)
            self.currentMonthEventSubject.onNext(allEvents.filter { event in
                return event.endDate >= startOfMonthString && event.startDate < endOfMonthString
            })
        }).disposed(by: disposeBag)
        self.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
    }
    
    private func updateEventVerion() {
        self.loadingLabel.text = String(localized: "event.version.loading")
        self.isLoading.onNext(true)
        Network.shared.client.fetch(query: CalendarPageVersionQuery()) { result in
            if case let .success(response) = result {
                if let data = response.data {
                    let previousVersion = UserDefaults.standard.string(forKey: "calendarVersion") ?? ""
                    if data.calendar.version != previousVersion {
                        self.updateEvent()
                    }
                }
            }
        }
        self.isLoading.onNext(false)
    }
    
    private func updateEvent() {
        self.loadingLabel.text = String(localized: "event.database.loading")
        Network.shared.client.fetch(query: CalendarPageQuery()) { result in
            if case let .success(response) = result {
                if let data = response.data {
                    Event.replaceAll(with: data.calendar.data.map { Event.transform(from: $0) })
                    UserDefaults.standard.set(data.calendar.version, forKey: "calendarVersion")
                }
            }
        }
    }
}

extension CalendarVC: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents) {
        self.currentMonthSubject.onNext(calendarView.visibleDateComponents.date!)
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let allEvents = try? self.eventSubject.value() else { return nil }
        let date = dateComponents.date!
        for event in allEvents {
            if (event.title.hasSuffix("방학") || event.title.hasSuffix("계절학기")) {
                continue
            }
            if (event.startDate <= self.dateFormatter.string(from: date) && event.endDate >= self.dateFormatter.string(from: date)) {
                return UICalendarView.Decoration.default(color: .plainButtonText, size: .medium)
            }
        }
        return nil
    }
}

extension CalendarVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = try? self.currentMonthEventSubject.value() else { return 0 }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let items = try? self.currentMonthEventSubject.value() else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarEventCellView.reuseIdentifier) as? CalendarEventCellView else { return CalendarEventCellView() }
        cell.setupUI(item: items[indexPath.row])
        return cell
    }
}
