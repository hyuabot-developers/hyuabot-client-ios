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
        self.calenadrView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(500)
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
            print(events)
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
}
