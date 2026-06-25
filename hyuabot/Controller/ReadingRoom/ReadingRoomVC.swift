import Api
import RxSwift
import UIKit
import UserNotifications

class ReadingRoomVC: UIViewController {
    private let disposeBag = DisposeBag()
    private var subscription: Disposable?
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private var showsSkeleton = false
    private let refreshControl = UIRefreshControl()
    private let roomSubject = BehaviorSubject<[ReadingRoomPageQuery.Data.ReadingRoom]>(value: [])
    /// Extend alarm UI
    private lazy var alarm3HourButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "reading_room.alarm.3hour")
        config.baseBackgroundColor = .hanyangBlue
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(alarm3HourTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var alarm4HourButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "reading_room.alarm.4hour")
        config.baseBackgroundColor = .hanyangBlue
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(alarm4HourTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var alarmCancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "reading_room.alarm.cancel")
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.isHidden = true
        btn.addTarget(self, action: #selector(alarmCancelTapped), for: .touchUpInside)
        return btn
    }()

    private let runningAlarmLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .hanyangBlue
        $0.isHidden = true
        $0.numberOfLines = 1
    }

    private lazy var readingRoomView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(ReadingRoomCellView.self, forCellReuseIdentifier: ReadingRoomCellView.reuseIdentifier)
        $0.register(ReadingRoomSkeletonCellView.self, forCellReuseIdentifier: ReadingRoomSkeletonCellView.reuseIdentifier)
        $0.refreshControl = refreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.readingRoom)
        showCoachMarksIfNeeded()
    }

    // MARK: - Alarm Actions

    @objc private func alarm3HourTapped() {
        scheduleLocalAlarm(hours: 3)
    }

    @objc private func alarm4HourTapped() {
        scheduleLocalAlarm(hours: 4)
    }

    @objc private func alarmCancelTapped() {
        cancelLocalAlarm()
    }

    private func scheduleLocalAlarm(hours: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            guard granted else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reading_room_extend_alarm"])
            let triggerMinutes = hours * 60 - 10
            let content = UNMutableNotificationContent()
            content.title = String(localized: "reading_room.alarm.notification.title")
            content.body = String(localized: "reading_room.alarm.notification.body")
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(triggerMinutes * 60), repeats: false)
            let request = UNNotificationRequest(identifier: "reading_room_extend_alarm", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            DispatchQueue.main.async {
                let alarmTime = Foundation.Date().addingTimeInterval(TimeInterval(triggerMinutes * 60))
                UserDefaults.standard.set(alarmTime.timeIntervalSince1970, forKey: "readingRoomExtendAlarmTime")
                self?.updateAlarmUI(alarmTime: alarmTime)
                AnalyticsManager.logSelect(.readingRoomAlarmToggle)
            }
        }
    }

    private func cancelLocalAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reading_room_extend_alarm"])
        UserDefaults.standard.removeObject(forKey: "readingRoomExtendAlarmTime")
        updateAlarmUI(alarmTime: nil)
        AnalyticsManager.logSelect(.readingRoomAlarmToggle)
    }

    private func updateAlarmUI(alarmTime: Foundation.Date?) {
        if let time = alarmTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            runningAlarmLabel.text = String(format: String(localized: "reading_room.alarm.running_format"), formatter.string(from: time))
            runningAlarmLabel.isHidden = false
            alarmCancelButton.isHidden = false
        } else {
            runningAlarmLabel.isHidden = true
            alarmCancelButton.isHidden = true
        }
    }

    private func restoreAlarmUI() {
        let savedTimestamp = UserDefaults.standard.double(forKey: "readingRoomExtendAlarmTime")
        guard savedTimestamp > 0 else { updateAlarmUI(alarmTime: (Foundation.Date?.none)); return }
        let alarmTime = Foundation.Date(timeIntervalSince1970: savedTimestamp)
        if alarmTime > Foundation.Date() {
            updateAlarmUI(alarmTime: alarmTime)
        } else {
            UserDefaults.standard.removeObject(forKey: "readingRoomExtendAlarmTime")
            updateAlarmUI(alarmTime: Foundation.Date?.none)
        }
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("readingroom") else { return }
        if let items = try? roomSubject.value(), !items.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.presentListCoachMark()
            }
            return
        }
        roomSubject
            .filter { !$0.isEmpty }
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.presentListCoachMark()
                }
            })
            .disposed(by: disposeBag)
    }

    private func presentListCoachMark() {
        presentCoachMarks(
            pageId: "readingroom",
            items: [
                CoachMarkItem(
                    id: "readingroom.list",
                    targetView: readingRoomView,
                    title: String(localized: "coach.readingroom.list.title"),
                    message: String(localized: "coach.readingroom.list.message")
                ),
                CoachMarkItem(
                    id: "readingroom.alarm",
                    targetViewProvider: { [weak self] in
                        let ip = IndexPath(row: 0, section: 0)
                        return (self?.readingRoomView.cellForRow(at: ip) as? ReadingRoomCellView)?.alarmButton
                    },
                    title: String(localized: "coach.readingroom.alarm.title"),
                    message: String(localized: "coach.readingroom.alarm.message")
                ),
                CoachMarkItem(
                    id: "readingroom.extend_alarm",
                    targetView: alarm3HourButton,
                    title: String(localized: "coach.readingroom.extend_alarm.title"),
                    message: String(localized: "coach.readingroom.extend_alarm.message")
                )
            ],
            shouldMarkAsShown: true,
            onComplete: { CoachMarkManager.shared.markPageShown("readingroom") }
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
        restoreAlarmUI()
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopPolling()
    }

    @objc func appDidEnterBackground() {
        stopPolling()
    }

    @objc func appWillEnterForeground() {
        startPolling()
    }

    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.readingRoomRefresh)
        fetchReadingRoomData()
    }

    private func setupUI() {
        navigationItem.title = String(localized: "tabbar.readingroom")
        // Alarm button stack
        let buttonStack = UIStackView(arrangedSubviews: [alarm3HourButton, alarm4HourButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        let alarmInfoStack = UIStackView(arrangedSubviews: [runningAlarmLabel, alarmCancelButton])
        alarmInfoStack.axis = .horizontal
        alarmInfoStack.spacing = 8
        alarmInfoStack.alignment = .center
        let alarmContainerStack = UIStackView(arrangedSubviews: [buttonStack, alarmInfoStack])
        alarmContainerStack.axis = .vertical
        alarmContainerStack.spacing = 6
        alarmContainerStack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        alarmContainerStack.isLayoutMarginsRelativeArrangement = true
        view.addSubview(alarmContainerStack)
        view.addSubview(readingRoomView)
        alarmContainerStack.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        readingRoomView.snp.makeConstraints { make in
            make.top.equalTo(alarmContainerStack.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func startPolling() {
        let hasRooms = (try? roomSubject.value().isEmpty == false) ?? false
        isLoading.onNext(!hasRooms)
        fetchReadingRoomData()
        subscription = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.fetchReadingRoomData()
            })
    }

    private func stopPolling() {
        subscription?.dispose()
    }

    private func fetchReadingRoomData() {
        let campusID = UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
        Task {
            defer {
                Task { @MainActor in
                    self.refreshControl.endRefreshing()
                    self.isLoading.onNext(false)
                }
            }
            let response = try? await Network.shared.client.fetch(query: ReadingRoomPageQuery())
            if let data = response?.data {
                await MainActor.run {
                    self.roomSubject.onNext(data.readingRoom.filter { $0.campus == campusID })
                }
            }
        }
    }

    private func observeSubjects() {
        isLoading.subscribe(onNext: { isLoading in
            self.showsSkeleton = isLoading
            self.readingRoomView.reloadData()
        }).disposed(by: disposeBag)
        roomSubject.subscribe(onNext: { [weak self] _ in
            self?.readingRoomView.reloadData()
        }).disposed(by: disposeBag)
        observeUserDefaultsStringArray(forKey: "readingRoomNotificationArray")
            .subscribe(onNext: { _ in
                self.readingRoomView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}

extension ReadingRoomVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return 6
        }
        guard let items = try? roomSubject.value() else { return 0 }
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ReadingRoomSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let items = try? roomSubject.value() else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReadingRoomCellView.reuseIdentifier) as? ReadingRoomCellView
        else { return ReadingRoomCellView() }
        cell.setupUI(
            item: items[indexPath.row],
            showSubscribeToastMessage: {
                message in self.showToastMessage(
                    image: UIImage(systemName: "checkmark.circle.fill"),
                    message: String(format: String(localized: "toast.readingroom.notification.subscribed.%@"), message)
                )
            },
            showUnsubscribeToastMessage: {
                message in self.showToastMessage(
                    image: UIImage(systemName: "checkmark.circle.fill"),
                    message: String(format: String(localized: "toast.readingroom.notification.unsubscribed.%@"), message)
                )
            }
        )
        return cell
    }
}
