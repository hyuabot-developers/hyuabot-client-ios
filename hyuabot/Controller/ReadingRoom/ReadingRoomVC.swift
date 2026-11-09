//
//  ReadingRoomVC.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit
import UserNotifications

class ReadingRoomVC: UIViewController, SettingsStyledScreen {
    let disposeBag = DisposeBag()
    private var subscription: Disposable?
    private let isLoading = BehaviorSubject<Bool>(value: false)
    private var showsSkeleton = false
    private let refreshControl = UIRefreshControl()
    let roomSubject = BehaviorSubject<[ReadingRoomPageQuery.Data.ReadingRoom]>(value: [])
    let campusPill = ContactCampusPillView()
    let statusRow = ReadingRoomStatusRowView()
    let alarmCard = ReadingRoomAlarmCardView()
    let footerView = ReadingRoomListFooterView()
    private let headerView = UIView()
    var isRefreshing = false
    var lastUpdatedAt: Foundation.Date?
    var toastContainer: UIView {
        navigationController?.view ?? view
    }

    var campusID: Int {
        UserDefaults.standard.integer(forKey: "campusID") == 0 ? 2 : UserDefaults.standard.integer(forKey: "campusID")
    }

    var campusName: String {
        String(localized: campusID == 1 ? "campus.seoul" : "campus.erica")
    }

    lazy var readingRoomView = UITableView().then {
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

    @objc
    private func openSettings() {
        navigationController?.pushViewController(SettingVC(), animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SettingsStyle.Color.background
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        navigationItem.title = String(localized: "tabbar.readingroom")
        campusPill.accessibilityIdentifier = "reading_room.campus_pill"
        let pillItem = UIBarButtonItem(customView: campusPill)
        if #available(iOS 26.0, *) {
            pillItem.hidesSharedBackground = true
        }
        navigationItem.rightBarButtonItem = pillItem
        campusPill.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        setupUI()
        observeSubjects()
        statusRow.onRefresh = { [weak self] in self?.manualRefresh() }
        alarmCard.onSchedule = { [weak self] hours in self?.scheduleLocalAlarm(hours: hours) }
        alarmCard.onCancel = { [weak self] in self?.cancelLocalAlarm() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        SettingsNavigationStyle.screenWillAppear(self)
        campusPill.setCampusName(campusName)
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
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        stopPolling()
        SettingsToastView.dismiss(in: toastContainer)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    @objc
    func appDidEnterBackground() {
        stopPolling()
    }

    @objc
    func appWillEnterForeground() {
        startPolling()
    }

    @objc
    private func refreshTableView(_ sender: UIRefreshControl) {
        isRefreshing = true
        updateStatusRow()
        AnalyticsManager.logSelect(.readingRoomRefresh)
        fetchReadingRoomData()
    }

    func manualRefresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        updateStatusRow()
        AnalyticsManager.logSelect(.readingRoomRefresh)
        fetchReadingRoomData()
    }

    func updateStatusRow() {
        statusRow.setStatus(updatedAt: lastUpdatedAt, isBusy: showsSkeleton || isRefreshing)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        readingRoomView.contactLayoutAccessoryViews()
    }

    private func setupUI() {
        readingRoomView.backgroundColor = SettingsStyle.Color.background
        readingRoomView.separatorStyle = .none
        readingRoomView.sectionHeaderTopPadding = 0
        readingRoomView.rowHeight = UITableView.automaticDimension
        readingRoomView.estimatedRowHeight = 96
        readingRoomView.contentInset.bottom = 32
        readingRoomView.showsVerticalScrollIndicator = false
        setContentScrollView(readingRoomView, for: .top)

        let stack = UIStackView(arrangedSubviews: [statusRow, alarmCard])
        stack.axis = .vertical
        stack.spacing = 12
        headerView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
            make.bottom.equalToSuperview().inset(16)
        }
        readingRoomView.tableHeaderView = headerView
        readingRoomView.tableFooterView = footerView
        view.addSubview(readingRoomView)
        readingRoomView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        Task {
            defer {
                Task { @MainActor in
                    self.refreshControl.endRefreshing()
                    self.isRefreshing = false
                    self.isLoading.onNext(false)
                    self.updateStatusRow()
                }
            }
            let response = try? await Network.shared.client.fetch(query: ReadingRoomPageQuery())
            if let data = response?.data {
                await MainActor.run {
                    let filtered = data.readingRoom.filter { $0.campus == self.campusID }
                    self.lastUpdatedAt = filtered.compactMap { $0.updatedAt.toZonedDateTimeOrNil() }.max() ?? Foundation.Date()
                    self.roomSubject.onNext(filtered)
                }
            }
        }
    }

    private func observeSubjects() {
        isLoading.subscribe(onNext: { isLoading in
            self.showsSkeleton = isLoading
            self.updateStatusRow()
            self.readingRoomView.reloadData()
            self.footerView.isHidden = isLoading || ((try? self.roomSubject.value().isEmpty) ?? true)
        }).disposed(by: disposeBag)
        roomSubject.subscribe(onNext: { [weak self] _ in
            self?.readingRoomView.reloadData()
            self?.footerView.isHidden = self?.showsSkeleton == true || ((try? self?.roomSubject.value().isEmpty) ?? true)
        }).disposed(by: disposeBag)
        observeUserDefaultsStringArray(forKey: "readingRoomNotificationArray")
            .subscribe(onNext: { _ in
                self.readingRoomView.reloadData()
                self.footerView.isHidden = self.showsSkeleton || ((try? self.roomSubject.value().isEmpty) ?? true)
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
            return ReadingRoomSkeletonCellView.rowCount
        }
        guard let items = try? roomSubject.value() else { return 0 }
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ReadingRoomSkeletonCellView.reuseIdentifier,
                for: indexPath
            ) as? ReadingRoomSkeletonCellView else { return UITableViewCell() }
            let count = ReadingRoomSkeletonCellView.rowCount
            cell.configure(index: indexPath.row, isFirst: indexPath.row == 0, isLast: indexPath.row == count - 1)
            return cell
        }
        guard let items = try? roomSubject.value() else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ReadingRoomCellView.reuseIdentifier,
            for: indexPath
        ) as? ReadingRoomCellView else { return UITableViewCell() }
        cell.setupUI(
            item: items[indexPath.row],
            isFirst: indexPath.row == 0,
            isLast: indexPath.row == items.count - 1,
            showSubscribeToastMessage: { name in
                let message = String(
                    format: String(localized: "toast.readingroom.notification.subscribed.%@"),
                    name
                )
                SettingsToastView.show(message: message, in: self.toastContainer, icon: .bell)
            },
            showUnsubscribeToastMessage: { name in
                let message = String(
                    format: String(localized: "toast.readingroom.notification.unsubscribed.%@"),
                    name
                )
                SettingsToastView.show(message: message, in: self.toastContainer, icon: .bell)
            }
        )
        return cell
    }
}
