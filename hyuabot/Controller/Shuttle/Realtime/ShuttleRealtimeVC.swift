//
//  ShuttleRealtimeVC.swift
//  hyuabot
//

import Api
import CoreLocation
import RxSwift
import SnapKit
import UIKit

private struct ShuttleStopPoint {
    let name: String
    let latitude: Double
    let longitude: Double
}

private struct ShuttleBusRouteOption {
    let bus: ShuttleRealtimePageQuery.Data.AlternativeBus?
    let routeName: String
    let color: UIColor
}

// swiftlint:disable:next type_body_length
class ShuttleRealtimeVC: UIViewController {
    private static let presenceStopIds = [
        "dormitory_o",
        "shuttlecock_o",
        "station",
        "terminal",
        "jungang_stn",
        "shuttlecock_i"
    ]

    private let initialStopID: String?
    private let initialDestinationID: String?
    private var appDelegate: AppDelegate? {
        UIApplication.shared.delegate as? AppDelegate
    }

    private let disposeBag = DisposeBag()
    private lazy var locationManager = CLLocationManager().then {
        $0.delegate = self
    }

    private let stopLocation = [
        CLLocation(latitude: 37.29339607529377, longitude: 126.83630604103446),
        CLLocation(latitude: 37.29875417910844, longitude: 126.83784054072336),
        CLLocation(latitude: 37.309700971618255, longitude: 126.85207173389148),
        CLLocation(latitude: 37.319338173415936, longitude: 126.8455263115596),
        CLLocation(latitude: 37.31487247528457, longitude: 126.83963540399434),
        CLLocation(latitude: 37.29869328231496, longitude: 126.8377767466817)
    ]
    private let stopTitleKeys: [String.LocalizationValue] = [
        "shuttle.stop.dormitory.out",
        "shuttle.stop.shuttlecock.out",
        "shuttle.stop.station",
        "shuttle.stop.terminal",
        "shuttle.stop.jungang.station",
        "shuttle.stop.shuttlecock.in"
    ]
    private lazy var stopTitles = stopTitleKeys.map { String(localized: $0) }
    private lazy var titleBar = ShuttleRealtimeTitleBar()
    private lazy var listHeader = ShuttleRealtimeListHeaderView(stopTitles: stopTitles)
    private let pager = ContentView()
    private let headerContainer = UIView()
    private var appliedHeaderHeight: CGFloat = 0
    private static let tabBarClearance: CGFloat = 64
    private var tabVCs: [ShuttleRealtimeTabVC] {
        [dormitoryOutTabVC, shuttlecockOutTabVC, stationTabVC, terminalTabVC, jungangStationTabVC, shuttlecockInTabVC]
    }

    private var noticeView: NoticeCarouselView {
        listHeader.noticeBar.carousel
    }

    private lazy var dormitoryOutTabVC = ShuttleRealtimeTabVC(
        stopID: .dormiotryOut,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC,
        showBusAlternativeStop: openBusAlternativeStopVC,
        showAlarmVC: openShuttleAlarmVC
    )
    private lazy var shuttlecockOutTabVC = ShuttleRealtimeTabVC(
        stopID: .shuttlecockOut,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC,
        showBusAlternativeStop: openBusAlternativeStopVC,
        showAlarmVC: openShuttleAlarmVC
    )
    private lazy var stationTabVC = ShuttleRealtimeTabVC(
        stopID: .station,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC,
        showBusAlternativeStop: openBusAlternativeStopVC,
        showAlarmVC: openShuttleAlarmVC
    )
    private lazy var terminalTabVC = ShuttleRealtimeTabVC(
        stopID: .terminal,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC,
        showBusAlternativeStop: openBusAlternativeStopVC,
        showAlarmVC: openShuttleAlarmVC
    )
    private lazy var jungangStationTabVC = ShuttleRealtimeTabVC(
        stopID: .jungangStation,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC,
        showBusAlternativeStop: openBusAlternativeStopVC,
        showAlarmVC: openShuttleAlarmVC
    )
    private lazy var shuttlecockInTabVC = ShuttleRealtimeTabVC(
        stopID: .shuttlecockIn,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC,
        showBusAlternativeStop: openBusAlternativeStopVC,
        showAlarmVC: openShuttleAlarmVC
    )
    private var isShowingCoachMarks = false
    private var coachMarkRetryWorkItem: DispatchWorkItem?
    private var pendingGPSTabIndex: Int?
    private var lastAppliedPayloadSelection: ShuttlePayloadSelection?
    private var lastAppliedNoticeLanguage: String?
    private var lastAppliedSubwayLanguage: String?
    private var pendingInitialStopLocation: CLLocation?
    private var initialStopRules: [ShuttleInitialStopRuleCandidate]?
    private var hasCompletedInitialLocationSelection = false
    private var hasManualStopSelection = false
    private var hasLoadedInitialShuttlePageData = false
    private var hasLoadedInitialBusAlternativeData = false
    private var hasLoadedInitialNotices = false
    private var subscription: Disposable?
    private var presenceSubscription: Disposable?
    private var latestPresenceViewerCounts: [String: Int]?
    private var selectedPresenceIndex = 0
    private var latestDataRequest = 0
    private var lastAppliedDataRequest = 0
    init(
        initialStopID: String? = nil,
        initialDestinationID: String? = nil
    ) {
        self.initialStopID = initialStopID
        self.initialDestinationID = initialDestinationID
        hasManualStopSelection = initialStopID != nil
        selectedPresenceIndex = Self.presenceStopIds.firstIndex(of: initialStopID ?? "") ?? 0
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let initialStopID {
            scrollToStop(initialStopID)
        }
        if let initialDestinationID {
            selectedStopTabVC.scrollToDestination(initialDestinationID)
        }
        logScreenView(.shuttleRealtime)
        scheduleCoachMarksIfNeeded()
        // `viewWillAppear`'s presence report is skipped because `view.window` is
        // still nil at that point, so trigger the first heartbeat here once the
        // view is attached to a window and the count can render immediately.
        reportPresence()
    }

    func retryCoachMarksIfNeeded() {
        scheduleCoachMarksIfNeeded()
    }

    private func scheduleCoachMarksIfNeeded(attempt: Int = 0) {
        guard hasLoadedInitialCoachMarkData else { return }
        guard CoachMarkManager.shared.shouldShowPage("shuttle.realtime") else { return }
        coachMarkRetryWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard coachMarkOverlayIsAbsent else { return }
            if !showCoachMarksIfNeeded(), attempt < 8 {
                scheduleCoachMarksIfNeeded(attempt: attempt + 1)
            }
        }
        coachMarkRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempt == 0 ? 0.1 : 0.25), execute: workItem)
    }

    private var hasLoadedInitialCoachMarkData: Bool {
        hasLoadedInitialShuttlePageData && hasLoadedInitialBusAlternativeData
    }

    @MainActor
    private func markInitialShuttlePageDataLoaded() {
        hasLoadedInitialShuttlePageData = true
        ShuttleRealtimeData.shared.isLoading.onNext(false)
        scheduleCoachMarksIfNeeded()
    }

    @MainActor
    private func markInitialBusAlternativeDataLoaded() {
        hasLoadedInitialBusAlternativeData = true
        scheduleCoachMarksIfNeeded()
    }

    private var coachMarkOverlayIsAbsent: Bool {
        guard let window = view.window else { return true }
        return !window.subviews.contains(where: { $0 is CoachMarkView })
    }

    @discardableResult
    private func showCoachMarksIfNeeded() -> Bool { // swiftlint:disable:this function_body_length
        guard CoachMarkManager.shared.shouldShowPage("shuttle.realtime") else { return false }
        guard view.window != nil else { return false }
        view.layoutIfNeeded()

        isShowingCoachMarks = true
        dormitoryOutTabVC.forceShowBusAlternative = true
        dormitoryOutTabVC.reloadSection0()
        selectStop(at: 0)

        var items: [CoachMarkItem] = [
            CoachMarkItem(
                id: "shuttle.tabs",
                targetView: listHeader.segmentView,
                title: String(localized: "coach.shuttle.tabs.title"),
                message: String(localized: "coach.shuttle.tabs.message")
            ),
            CoachMarkItem(
                id: "shuttle.quickSettings",
                targetView: titleBar.settingsButton,
                title: String(localized: "shuttle.quick_settings.button"),
                message: String(localized: "coach.shuttle.quick_settings.message")
            ),
            CoachMarkItem(
                id: "shuttle.sectionHelp",
                targetViewProvider: { [weak self] in self?.dormitoryOutTabVC.firstSectionHeaderHelpView },
                title: String(localized: "coach.shuttle.help.title"),
                message: String(localized: "coach.shuttle.help.message")
            ),
            CoachMarkItem(
                id: "shuttle.row",
                targetView: dormitoryOutTabVC.visibleTableView,
                title: String(localized: "coach.shuttle.row.title"),
                message: String(localized: "coach.shuttle.row.message")
            ),
            CoachMarkItem(
                id: "shuttle.busAlternative",
                targetViewProvider: { [weak self] in
                    guard let self else { return nil }
                    dormitoryOutTabVC.reloadSection0()
                    dormitoryOutTabVC.scrollToTop()
                    return dormitoryOutTabVC.busAlternativeView
                },
                title: String(localized: "coach.shuttle.busAlternative.title"),
                message: String(localized: "coach.shuttle.busAlternative.message")
            )
        ]

        if !listHeader.noticeBar.isHidden {
            items.append(CoachMarkItem(
                id: "shuttle.notice",
                targetView: listHeader.noticeBar,
                title: String(localized: "coach.shuttle.notice.title"),
                message: String(localized: "coach.shuttle.notice.message")
            ))
        }

        let didPresent = presentCoachMarks(
            pageId: "shuttle.realtime",
            items: items,
            shouldMarkAsShown: false,
            onSkip: { [weak self] in self?.finishCoachMarks() },
            onComplete: { [weak self] in self?.showFooterCoachMarksWhenReady() }
        )
        if !didPresent {
            isShowingCoachMarks = false
            dormitoryOutTabVC.forceShowBusAlternative = false
            dormitoryOutTabVC.reloadSection0()
        }
        return didPresent
    }

    private func showFooterCoachMarksWhenReady() {
        dormitoryOutTabVC.forceShowBusAlternative = false
        dormitoryOutTabVC.reloadSection0()
        let scroll: () -> Void = { [weak self] in
            guard let self else { return }
            dormitoryOutTabVC.scrollToFooter()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.presentFooterCoachMarks()
            }
        }
        let isLoaded = (try? ShuttleRealtimeData.shared.arrival.value())?.isEmpty == false
        if isLoaded {
            scroll()
        } else {
            ShuttleRealtimeData.shared.arrival
                .filter { !$0.isEmpty }
                .take(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { _ in
                    DispatchQueue.main.async { scroll() }
                })
                .disposed(by: disposeBag)
        }
    }

    private func presentFooterCoachMarks() {
        var items: [CoachMarkItem] = []
        if let transferView = dormitoryOutTabVC.transferInfoView {
            items.append(CoachMarkItem(
                id: "shuttle.transfer",
                targetView: transferView,
                title: String(localized: "coach.shuttle.transfer.title"),
                message: String(localized: "coach.shuttle.transfer.message")
            ))
        }
        items.append(contentsOf: [
            CoachMarkItem(
                id: "shuttle.footer.timetable",
                targetViewProvider: { [weak self] in self?.dormitoryOutTabVC.lastSectionFooterTimetableButton },
                title: String(localized: "coach.shuttle.footer.timetable.title"),
                message: String(localized: "coach.shuttle.footer.timetable.message")
            ),
            CoachMarkItem(
                id: "shuttle.footer.stopModal",
                targetView: listHeader.stopInfoButton,
                title: String(localized: "coach.shuttle.footer.title"),
                message: String(localized: "coach.shuttle.footer.message")
            )
        ])
        let validItems = items.filter { item in
            guard let targetView = item.targetView else { return false }
            return targetView.window != nil && !targetView.isHidden
        }
        guard !validItems.isEmpty,
              let window = view.window,
              !window.subviews.contains(where: { $0 is CoachMarkView })
        else {
            return
        }
        let overlay = CoachMarkView()
        overlay.frame = window.bounds
        window.addSubview(overlay)
        overlay.onComplete = { [weak self] in self?.finishCoachMarks() }
        overlay.present(items: validItems)
    }

    private func finishCoachMarks() {
        CoachMarkManager.shared.markPageShown("shuttle.realtime")
        dormitoryOutTabVC.forceShowBusAlternative = false
        dormitoryOutTabVC.reloadSection0()
        isShowingCoachMarks = false
        if let pendingIndex = pendingGPSTabIndex, !hasManualStopSelection {
            pendingGPSTabIndex = nil
            selectStop(at: pendingIndex)
            showToastMessage(
                image: UIImage(systemName: "checkmark.circle.fill"),
                message: String(
                    format: String(localized: "toast.success.shuttle.realtime.location.%@"),
                    stopTitles[pendingIndex]
                )
            )
        }
        checkUserDeviceLocationServiceAuthorization()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderInset()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
        checkBirthdayDialog()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
        startPresenceUpdates()
        noticeView.resumeAutoScroll()
        navigationController?.setNavigationBarHidden(true, animated: false)
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
        NotificationCenter.default.addObserver(self, selector: #selector(coachMarksDidReset), name: .coachMarkReset, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .coachMarkReset, object: nil)
        stopPolling()
        stopPresenceUpdates()
        noticeView.stopAutoScroll()
    }

    @objc
    func appDidEnterBackground() {
        stopPolling()
        stopPresenceUpdates()
    }

    @objc
    func appWillEnterForeground() {
        startPolling()
        startPresenceUpdates()
    }

    private func startPresenceUpdates() {
        stopPresenceUpdates()
        guard showsPresenceStatus else { return }
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            let previewCount = arguments.firstIndex(of: "-shuttlePresencePreview").flatMap { index in
                arguments.indices.contains(index + 1) ? Int(arguments[index + 1]) : nil
            }
            if let count = previewCount {
                updatePresenceStatus(viewerCount: count)
                return
            }
        #endif
        reportPresence()
        presenceSubscription = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.reportPresence() })
    }

    private func stopPresenceUpdates() {
        presenceSubscription?.dispose()
        presenceSubscription = nil
        updatePresenceStatus(viewerCount: nil)
    }

    private func reportPresence() {
        guard showsPresenceStatus,
              view.window != nil,
              Self.presenceStopIds.indices.contains(selectedPresenceIndex)
        else { return }
        let requestedIndex = selectedPresenceIndex
        let stopId = Self.presenceStopIds[requestedIndex]
        Task { [weak self] in
            async let count = ShuttlePresenceService.shared.heartbeat(stopId: stopId)
            async let counts = ShuttlePresenceService.shared.viewerCounts()
            let (viewerCount, viewerCounts) = await (count, counts)
            await MainActor.run {
                guard let self, self.selectedPresenceIndex == requestedIndex else { return }
                self.updatePresenceStatus(viewerCount: viewerCount, viewerCounts: viewerCounts)
            }
        }
    }

    private func updatePresenceStatus(viewerCount: Int?, viewerCounts: [String: Int]? = nil) {
        if let viewerCounts {
            latestPresenceViewerCounts = viewerCounts
        }
        guard showsPresenceStatus, stopTitles.indices.contains(selectedPresenceIndex), let viewerCount else {
            listHeader.setPresence(text: nil, accessibilityLabel: nil, dotColor: nil)
            return
        }
        let visualStyle = ShuttlePresenceVisualStyle(
            viewerCount: viewerCount,
            availableSeats: estimatedAvailableSeats(
                for: Self.presenceStopIds[selectedPresenceIndex],
                viewerCounts: viewerCounts ?? latestPresenceViewerCounts
            )
        )
        let accessibilityLabel = String(
            format: String(localized: "shuttle.presence.viewer.count"),
            locale: Locale.current,
            viewerCount
        )
        let dotColor: UIColor = switch visualStyle {
        case .low: SettingsStyle.Color.levelGood
        case .medium: SettingsStyle.Color.levelMid
        case .high: SettingsStyle.Color.levelFull
        }
        listHeader.setPresence(
            text: String(format: String(localized: "shuttle.presence.pill.%lld"), locale: Locale.current, viewerCount),
            accessibilityLabel: accessibilityLabel,
            dotColor: dotColor
        )
    }

    private func estimatedAvailableSeats(for stopID: String, viewerCounts: [String: Int]?) -> Int? {
        guard let viewerCounts,
              let routeStops = nextRouteStopIDs(for: stopID),
              let stopIndex = routeStops.firstIndex(of: stopID)
        else { return nil }
        let onboard = routeStops.prefix(stopIndex).reduce(into: 0) { onboard, previousStopID in
            if previousStopID == "station" {
                onboard = 0
            }
            onboard += viewerCounts[previousStopID, default: 0]
        }
        return max(45 - onboard, 0)
    }

    private func nextRouteStopIDs(for stopID: String) -> [String]? {
        guard let stop = try? ShuttleRealtimeData.shared.arrival.value().first(where: { $0.name == stopID }) else { return nil }
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm:ss" }
        let now = timeFormatter.string(from: .now)
        return stop.timetable.order.first(where: { $0.time > now })?.stops.map(\.stop)
    }

    @objc
    private func coachMarksDidReset() {
        guard view.window != nil else { return }
        isShowingCoachMarks = false
        scheduleCoachMarksIfNeeded()
    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        view.addSubview(titleBar)
        view.addSubview(listHeader)
        view.addSubview(pager)
        pager.pages = tabVCs.map(\.view)
        pager.delegate = self
        listHeader.setLocationSource(isManual: initialStopID != nil)
        titleBar.onSettingsTap = { [weak self] in self?.openQuickSettings() }
        listHeader.onSelectStop = { [weak self] index in
            self?.handleUserStopSelection(index, fromSwipe: false)
        }
        listHeader.onReturnToNearestTap = { [weak self] in self?.returnToNearestStop() }
        listHeader.onStopInfoTap = { [weak self] in
            guard let self, tabVCs.indices.contains(pager.currentIndex) else { return }
            openShuttleStopVC(tabVCs[pager.currentIndex].stopID)
        }
        // Title bar and list header stay pinned above the pager; only the lists scroll.
        view.sendSubviewToBack(pager)
        view.addSubview(headerContainer)
        headerContainer.addSubview(titleBar)
        headerContainer.addSubview(listHeader)
        titleBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        listHeader.snp.makeConstraints { make in
            make.top.equalTo(titleBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        headerContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        pager.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        noticeView.onNoticeTapped = { [weak self] url in
            guard let url = URL(string: url) else { return }
            let vc = NoticeWebVC(url: url)
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            self?.present(vc, animated: true, completion: nil)
        }
        updatePresenceStatus(viewerCount: nil)
        let showRemainingTime = UserDefaults.standard.bool(forKey: "showRemainingTime")
        ShuttleRealtimeData.shared.showRemainingTime.onNext(showRemainingTime)
        let showArrivalByTime = UserDefaults.standard.bool(forKey: "showArrivalByTime")
        ShuttleRealtimeData.shared.showArrivalByTime.onNext(showArrivalByTime)
    }

    // swiftlint:disable:next function_body_length
    private func observeSubjects() {
        ShuttleRealtimeData.shared.arrival.subscribe(onNext: { data in
            let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm:ss" }
            let currentTime = timeFormatter.string(from: Date.now)
            let shared = ShuttleRealtimeData.shared
            typealias Entry = ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
            typealias Order = ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order
            // Publish every stop from the shared response and omit destination departures that have already passed.
            func publish(
                _ stopName: String,
                order: BehaviorSubject<[Order]>,
                destinations: [(String, BehaviorSubject<[Entry]>)]
            ) {
                let stop = data.first(where: { $0.name == stopName })
                // The query fetches the full day; hide departures before the current minute.
                order.onNext(stop?.timetable.order.filter { $0.time >= String(currentTime.prefix(5)) } ?? [])
                for (destination, subject) in destinations {
                    subject.onNext(
                        stop?.timetable.destination.first(where: { $0.destination == destination })?.entries
                            .filter { $0.time > currentTime } ?? []
                    )
                }
            }
            publish("dormitory_o", order: shared.shuttleDormitoryData, destinations: [
                ("STATION", shared.shuttleDormitoryToStationData),
                ("TERMINAL", shared.shuttleDormitoryToTerminalData),
                ("JUNGANG", shared.shuttleDormitoryToJungangStationData),
            ])
            publish("shuttlecock_o", order: shared.shuttleShuttlecockData, destinations: [
                ("STATION", shared.shuttleShuttlecockToStationData),
                ("TERMINAL", shared.shuttleShuttlecockToTerminalData),
                ("JUNGANG", shared.shuttleShuttlecockToJungangStationData),
            ])
            publish("station", order: shared.shuttleStationData, destinations: [
                ("CAMPUS", shared.shuttleStationToCampusData),
                ("TERMINAL", shared.shuttleStationToTerminalData),
                ("JUNGANG", shared.shuttleStationToJungangStationData),
            ])
            publish("terminal", order: shared.shuttleTerminalData, destinations: [
                ("CAMPUS", shared.shuttleTerminalToCampusData),
            ])
            publish("jungang_stn", order: shared.shuttleJungangStationData, destinations: [
                ("CAMPUS", shared.shuttleJungangStationToCampusData),
            ])
            publish("shuttlecock_i", order: shared.shuttleShuttlecockInData, destinations: [
                ("CAMPUS", shared.shuttleShuttlecockInToDormitoryData),
            ])
            self.dormitoryOutTabVC.reload()
            self.shuttlecockOutTabVC.reload()
            self.stationTabVC.reload()
            self.terminalTabVC.reload()
            self.jungangStationTabVC.reload()
            self.shuttlecockInTabVC.reload()
        }).disposed(by: disposeBag)
        ShuttleRealtimeData.shared.notices.subscribe(onNext: { notices in
            if !self.hasLoadedInitialNotices, notices.isEmpty {
                self.listHeader.setNoticeHidden(false)
                self.noticeView.setLoading(true)
            } else if notices.isEmpty {
                self.listHeader.setNoticeHidden(true)
                self.noticeView.stopAutoScroll()
            } else {
                self.listHeader.setNoticeHidden(false)
                self.noticeView.setupUI(with: notices.map { Notice(title: $0.title, url: $0.url) })
            }
        }).disposed(by: disposeBag)
    }

    private func startPolling() {
        fetchShuttleRealtimeData()
        subscription = Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.fetchShuttleRealtimeData()
            })
    }

    private func stopPolling() {
        subscription?.dispose()
    }

    private func currentPayloadSelection() -> ShuttlePayloadSelection {
        ShuttlePayloadSelection(
            byDestination: !UserDefaults.standard.bool(forKey: "showArrivalByTime"),
            showBus: ShuttleTransferDisplaySettings.showsBusTransfer,
            showSubway: ShuttleTransferDisplaySettings.showsSubwayTransfer,
            subwayDestination: ShuttleTransferDisplaySettings.subwayDestination,
            alternatives: ShuttleTransferDisplaySettings.alternativeDisplayMode
        )
    }

    // swiftlint:disable:next function_body_length
    private func fetchShuttleRealtimeData() {
        latestDataRequest += 1
        let request = latestDataRequest
        let selection = currentPayloadSelection()
        let now = Date.now
        let dataDelegate = ShuttleRealtimeData.shared
        let currentLanguage = LanguageManager.shared.apiLanguageTag
        let noticeLanguage = currentLanguage.starts(with: "ko") ? "KOREAN" : "ENGLISH"
        dataDelegate.prepareForSubwayLanguage(currentLanguage)
        let selectionChanged = lastAppliedPayloadSelection != selection
        let noticeLanguageChanged = lastAppliedNoticeLanguage != noticeLanguage
        let subwayLanguageChanged = lastAppliedSubwayLanguage != currentLanguage
        if selectionChanged || noticeLanguageChanged || subwayLanguageChanged {
            dataDelegate.isLoading.onNext(true)
        }
        Task {
            let response = try? await Network.shared.client.fetch(
                query: ShuttleRealtimePageQuery(
                    language: noticeLanguage,
                    subwayLanguage: currentLanguage,
                    after: nil,
                    shuttleStops: Self.presenceStopIds.map {
                        ShuttleStopInput(name: $0, limit: ShuttleLimitInput(order: 1000, destination: 1000))
                    },
                    subwayKeys: selection.subwayPairs.filter { $0.0 != "S26" }.map {
                        SubwayStationInput(stationID: $0.0, direction: [$0.1], weekdays: [currentWeekdayString()], limit: 12)
                    },
                    subwayTimetableKeys: selection.subwayPairs.filter { $0.0 == "S26" }.map {
                        SubwayStationInput(stationID: $0.0, direction: [$0.1], weekdays: [currentWeekdayString()])
                    },
                    transferBusInput: selection.needsBus ? [BusRouteStopInput(
                        route: 216_000_075, stop: 216_000_759, limit: 12, dates: .some(busLogReferenceDates())
                    )] : [],
                    alternativeInput: selection.alternativePairs.map { BusRouteStopInput(route: $0.0, stop: $0.1, limit: 1) }
                ),
                cachePolicy: .networkOnly
            )
            await MainActor.run {
                // Timer ticks create newer requests with the same selection, so a slow response is still applied
                // unless the selection changed or a newer response has already been rendered.
                guard request > lastAppliedDataRequest, selection == currentPayloadSelection() else { return }
                initialStopRules =
                    response?.data?.shuttle.initialStopRules.map { rule in
                        ShuttleInitialStopRuleCandidate(
                            sequence: rule.seq,
                            stopName: rule.stopName,
                            priority: rule.priority,
                            polygon: rule.polygon.map {
                                ShuttleGeoCoordinate(latitude: $0.latitude, longitude: $0.longitude)
                            }
                        )
                    } ?? []
                if let pendingInitialStopLocation {
                    self.pendingInitialStopLocation = nil
                    applyInitialStop(for: pendingInitialStopLocation)
                }
                guard selection == currentPayloadSelection() else { return }
                if let data = response?.data {
                    lastAppliedDataRequest = request
                    lastAppliedPayloadSelection = selection
                    lastAppliedNoticeLanguage = noticeLanguage
                    lastAppliedSubwayLanguage = currentLanguage
                    dataDelegate.transferData.onNext(data)
                    self.hasLoadedInitialNotices = true
                    dataDelegate.notices.onNext(data.notices.flatMap(\.notices))
                    dataDelegate.arrival.onNext(data.shuttle.stops)
                    dataDelegate.busAlternatives.onNext(Self.buildBusAlternatives(data.alternativeBus))
                }
                markInitialShuttlePageDataLoaded()
                markInitialBusAlternativeDataLoaded()
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private static func buildBusAlternatives(
        _ busList: [ShuttleRealtimePageQuery.Data.AlternativeBus]
    ) -> [String: [ShuttleBusAlternativeDisplayData]] {
        func item(routeSeq: Int, stopSeq: Int) -> ShuttleRealtimePageQuery.Data.AlternativeBus? {
            busList.first { $0.route.seq == routeSeq && $0.stop.seq == stopSeq }
        }

        func display(
            _ bus: ShuttleRealtimePageQuery.Data.AlternativeBus?,
            routeName: String,
            color: UIColor
        ) -> ShuttleBusAlternativeDisplayData? {
            guard let bus, let minutes = bus.arrival.first?.minutes else { return nil }
            return ShuttleBusAlternativeDisplayData(
                routeName: routeName,
                minutes: minutes,
                color: color,
                busStopName: bus.stop.name,
                busStopLatitude: bus.stop.latitude,
                busStopLongitude: bus.stop.longitude
            )
        }

        func bestRoute(_ options: [ShuttleBusRouteOption]) -> ShuttleBusAlternativeDisplayData? {
            options.compactMap { option in
                display(option.bus, routeName: option.routeName, color: option.color)
            }.min { lhs, rhs in
                (lhs.minutes ?? Int.max) < (rhs.minutes ?? Int.max)
            }
        }

        let green = UIColor(named: "busGreen") ?? .systemGreen
        let blue = UIColor(named: "busBlue") ?? .systemBlue

        let route10ToSangnoksu = String(localized: "shuttle.bus.alternative.route")
        let route10FromSangnoksu = String(localized: "shuttle.bus.alternative.route.campus")
        let route62Terminal = String(localized: "shuttle.bus.alternative.route.62.terminal")
        let route62Dormitory = String(localized: "shuttle.bus.alternative.route.62.dormitory")
        let route62Jungang = String(localized: "shuttle.bus.alternative.route.62.jungang")
        let route80A = String(localized: "shuttle.bus.alternative.route.80a")
        let routeN80A = String(localized: "shuttle.bus.alternative.route.n80a")
        let route80AJungang = String(localized: "shuttle.bus.alternative.route.80a.jungang")
        let routeN80AJungang = String(localized: "shuttle.bus.alternative.route.n80a.jungang")
        let route80B = String(localized: "shuttle.bus.alternative.route.80b")
        let routeN80B = String(localized: "shuttle.bus.alternative.route.n80b")

        let dormitory10 = display(item(routeSeq: 216_000_068, stopSeq: 216_000_383), routeName: route10ToSangnoksu, color: green)
        let shuttlecock10 = display(item(routeSeq: 216_000_068, stopSeq: 216_000_379), routeName: route10ToSangnoksu, color: green)
        let station10 = display(item(routeSeq: 216_000_068, stopSeq: 216_000_138), routeName: route10FromSangnoksu, color: green)
        let dormitory80 = bestRoute([
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_081, stopSeq: 216_000_028), routeName: route80A, color: blue),
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_101, stopSeq: 216_000_028), routeName: routeN80A, color: blue)
        ])
        let dormitory80Jungang = bestRoute([
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_081, stopSeq: 216_000_028), routeName: route80AJungang, color: blue),
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_101, stopSeq: 216_000_028), routeName: routeN80AJungang, color: blue)
        ])
        let shuttlecock62 = display(item(routeSeq: 216_000_016, stopSeq: 216_000_152), routeName: route62Terminal, color: green)
        let shuttlecock62Jungang = display(item(routeSeq: 216_000_016, stopSeq: 216_000_152), routeName: route62Jungang, color: green)
        let terminal80 = bestRoute([
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_082, stopSeq: 216_000_077), routeName: route80B, color: blue),
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_102, stopSeq: 216_000_077), routeName: routeN80B, color: blue)
        ])
        let terminal62 = display(item(routeSeq: 216_000_016, stopSeq: 216_000_074), routeName: route62Dormitory, color: green)
        let jungang80 = bestRoute([
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_082, stopSeq: 217_000_140), routeName: route80B, color: blue),
            ShuttleBusRouteOption(bus: item(routeSeq: 216_000_102, stopSeq: 217_000_140), routeName: routeN80B, color: blue)
        ])
        let jungang62 = display(item(routeSeq: 216_000_016, stopSeq: 217_000_264), routeName: route62Dormitory, color: green)

        return [
            "dormitory_station": [dormitory10].compactMap { $0 },
            "dormitory_terminal": [dormitory80].compactMap { $0 },
            "dormitory_jungang": [dormitory80Jungang].compactMap { $0 },
            "shuttlecock_station": [shuttlecock10].compactMap { $0 },
            "shuttlecock_terminal": [shuttlecock62].compactMap { $0 },
            "shuttlecock_jungang": [shuttlecock62Jungang].compactMap { $0 },
            "station_dormitory": [station10].compactMap { $0 },
            "terminal_dormitory": [terminal80, terminal62].compactMap { $0 },
            "jungang_dormitory": [jungang80, jungang62].compactMap { $0 }
        ]
    }

    private func moveToEntireTimetable(_ stop: ShuttleStopEnum, _ section: Int) {
        guard let nc = navigationController as? ShuttleNC else { return }
        nc.moveToTimetableVC(stop: stop, section: section)
    }

    private func openShuttleViaVCByOrder(_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                min(vc.sheetHeight, context.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    private func openShuttleViaVCByDestination(_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                min(vc.sheetHeight, context.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    private func openShuttleAlarmVC(_ stop: ShuttleStopEnum, _ context: ShuttleAlarmContext) {
        let vc = ShuttleAlarmVC(context: context)
        vc.shareJourney = { [weak self, weak vc] text in
            self?.presentJourneyShare(text, dismissing: vc)
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { resolverContext in
                min(vc.sheetHeight, resolverContext.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    private func presentJourneyShare(_ text: String, dismissing vc: UIViewController?) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityVC.modalPresentationStyle = .pageSheet
        activityVC.popoverPresentationController?.sourceView = view
        activityVC.popoverPresentationController?.sourceRect = CGRect(
            x: view.bounds.midX,
            y: view.bounds.maxY,
            width: 1,
            height: 1
        )

        let presentShare: () -> Void = { [weak self] in
            guard let self else { return }
            present(activityVC, animated: true)
        }

        guard let vc, vc.presentingViewController != nil else {
            presentShare()
            return
        }

        vc.dismiss(animated: false) {
            DispatchQueue.main.async {
                presentShare()
            }
        }
    }

    private func openShuttleStopVC(_ stop: ShuttleStopEnum) {
        let vc = ShuttleStopInfoVC(stop: stop)
        HYUSheet.configure(vc, detents: [.custom(resolver: { context in
            min(vc.sheetHeight, context.maximumDetentValue)
        })])
        present(vc, animated: true, completion: nil)
    }

    private func openBusAlternativeStopVC(_ stop: ShuttleStopEnum, _ alternative: ShuttleBusAlternativeDisplayData) {
        guard let shuttleStop = shuttleStopPoint(stop) else { return }
        let vc = BusAlternativeStopVC(
            shuttleStopName: shuttleStop.name,
            shuttleStopLatitude: shuttleStop.latitude,
            shuttleStopLongitude: shuttleStop.longitude,
            busStopName: alternative.busStopName,
            busStopLatitude: alternative.busStopLatitude,
            busStopLongitude: alternative.busStopLongitude
        )
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                min(vc.sheetHeight, context.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    private func shuttleStopPoint(_ stop: ShuttleStopEnum) -> ShuttleStopPoint? {
        let name = String(localized: String.LocalizationValue(shuttleStopLocalizationKey(stop)))
        let stops = try? ShuttleRealtimeData.shared.arrival.value()
        if let stops, let shuttleStop = stops.first(where: { $0.name == shuttleStopAPIName(stop) }) {
            return ShuttleStopPoint(name: name, latitude: shuttleStop.latitude, longitude: shuttleStop.longitude)
        }

        guard let fallbackIndex = shuttleStopFallbackIndex(stop), stopLocation.indices.contains(fallbackIndex) else {
            return nil
        }
        let fallback = stopLocation[fallbackIndex]
        return ShuttleStopPoint(name: name, latitude: fallback.coordinate.latitude, longitude: fallback.coordinate.longitude)
    }

    private func shuttleStopAPIName(_ stop: ShuttleStopEnum) -> String {
        switch stop {
        case .dormiotryOut:
            "dormitory_o"
        case .shuttlecockOut:
            "shuttlecock_o"
        case .station:
            "station"
        case .terminal:
            "terminal"
        case .jungangStation:
            "jungang_stn"
        case .shuttlecockIn:
            "shuttlecock_i"
        }
    }

    private func shuttleStopLocalizationKey(_ stop: ShuttleStopEnum) -> String {
        switch stop {
        case .dormiotryOut:
            "shuttle.stop.dormitory.out"
        case .shuttlecockOut:
            "shuttle.stop.shuttlecock.out"
        case .station:
            "shuttle.stop.station"
        case .terminal:
            "shuttle.stop.terminal"
        case .jungangStation:
            "shuttle.stop.jungang.station"
        case .shuttlecockIn:
            "shuttle.stop.shuttlecock.in"
        }
    }

    private func shuttleStopFallbackIndex(_ stop: ShuttleStopEnum) -> Int? {
        switch stop {
        case .dormiotryOut:
            0
        case .shuttlecockOut:
            1
        case .station:
            2
        case .terminal:
            3
        case .jungangStation:
            4
        case .shuttlecockIn:
            5
        }
    }

    private func isAfterNow(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date.now
        let nowString = dateFormatter.string(from: now)
        return nowString < item.time
    }

    private func isAfterNow(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date.now
        let nowString = dateFormatter.string(from: now)
        return nowString < item.time
    }

    private func checkUserDeviceLocationServiceAuthorization() {
        guard !hasCompletedInitialLocationSelection, !hasManualStopSelection else { return }
        let isAuthorized = locationManager.authorizationStatus == .authorizedWhenInUse ||
            locationManager.authorizationStatus == .authorizedAlways
        if isAuthorized {
            locationManager.startUpdatingLocation()
        } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            showToastMessage(
                image: UIImage(systemName: "exclamationmark.triangle.fill"),
                message: String(localized: "toast.error.shuttle.realtime.location")
            )
        } else if locationManager.authorizationStatus == .notDetermined {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func checkBirthdayDialog() {
        // Open Birthday Dialog on Dec 12
        let now = Date.now
        let dateTimeFormatter = DateFormatter().then {
            $0.timeZone = TimeZone(identifier: "Asia/Seoul")
            $0.dateFormat = "MM/dd"
        }
        if dateTimeFormatter.string(from: now) == "12/12" {
            guard let nc = navigationController as? ShuttleNC else { return }
            nc.openBirthdayDialog()
        }
    }

    @objc
    private func openHelpVC() {
        AnalyticsManager.logSelect(.shuttleOpenHelp)
        let vc = ShuttleHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    @objc
    private func openQuickSettings() {
        let showRemainingTime = UserDefaults.standard.bool(forKey: "showRemainingTime")
        let showArrivalByTime = UserDefaults.standard.bool(forKey: "showArrivalByTime")
        let vc = ShuttleQuickSettingsVC(
            showArrivalByTime: showArrivalByTime,
            showDepartureTime: !showRemainingTime,
            showPresenceStatus: showsPresenceStatus,
            showBusTransfer: ShuttleTransferDisplaySettings.showsBusTransfer,
            showSubwayTransfer: ShuttleTransferDisplaySettings.showsSubwayTransfer,
            subwayDestination: ShuttleTransferDisplaySettings.subwayDestination,
            alternativeDisplayMode: ShuttleTransferDisplaySettings.alternativeDisplayMode
        )
        vc.openHelp = { [weak self] in self?.openHelpVC() }
        vc.openInquiry = { [weak self] in
            self?.openInquiry()
        }
        vc.updateShowDepartureTime = { [weak self] isOn in
            self?.applyShowDepartureTime(isOn)
        }
        vc.updateShowArrivalByTime = { [weak self] isOn in
            self?.applyShowArrivalByTime(isOn)
        }
        vc.updateShowPresenceStatus = { [weak self] isOn in
            self?.applyShowPresenceStatus(isOn)
        }
        vc.updateShowBusTransfer = { [weak self] isOn in
            ShuttleTransferDisplaySettings.showsBusTransfer = isOn
            self?.reloadTransferDisplaySettings()
        }
        vc.updateShowSubwayTransfer = { [weak self] isOn in
            ShuttleTransferDisplaySettings.showsSubwayTransfer = isOn
            self?.reloadTransferDisplaySettings()
        }
        vc.updateSubwayDestination = { [weak self] destination in
            ShuttleTransferDisplaySettings.subwayDestination = destination
            self?.reloadTransferDisplaySettings()
        }
        vc.updateAlternativeDisplayMode = { [weak self] mode in
            ShuttleTransferDisplaySettings.alternativeDisplayMode = mode
            self?.reloadTransferDisplaySettings()
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom { context in
                min(vc.preferredSheetHeight, context.maximumDetentValue)
            }]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    @objc
    private func openInquiry() {
        navigationController?.pushViewController(
            InquiryChatVC(entryScreen: "shuttle", entryScreenName: "셔틀"),
            animated: true
        )
    }

    private func reloadTransferDisplaySettings() {
        fetchShuttleRealtimeData()
        [
            dormitoryOutTabVC,
            shuttlecockOutTabVC,
            stationTabVC,
            terminalTabVC,
            jungangStationTabVC,
            shuttlecockInTabVC
        ].forEach { $0.reloadTransferDisplaySettings() }
    }

    private func applyShowDepartureTime(_ isOn: Bool) {
        AnalyticsManager.logSelect(.shuttleDepartureSwitch, type: .toggle)
        ShuttleRealtimeData.shared.showRemainingTime.onNext(!isOn)
        UserDefaults.standard.set(!isOn, forKey: "showRemainingTime")
    }

    private func applyShowArrivalByTime(_ isOn: Bool) {
        AnalyticsManager.logSelect(.shuttleArrivalByTimeSwitch, type: .toggle)
        ShuttleRealtimeData.shared.showArrivalByTime.onNext(isOn)
        UserDefaults.standard.set(isOn, forKey: "showArrivalByTime")
        fetchShuttleRealtimeData()
    }

    private var showsPresenceStatus: Bool {
        ShuttlePresenceSettings.showsStatus
    }

    private func applyShowPresenceStatus(_ isOn: Bool) {
        ShuttlePresenceSettings.showsStatus = isOn
        if isOn {
            startPresenceUpdates()
        } else {
            stopPresenceUpdates()
        }
    }
}

private func currentWeekdayString() -> String {
    var calendar = Calendar.current
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? calendar.timeZone
    let weekday = calendar.component(.weekday, from: Foundation.Date.now)
    return weekday == 1 || weekday == 7 ? "weekends" : "weekdays"
}

private func busLogReferenceDates() -> [Api.Date] {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    formatter.dateFormat = "yyyy-MM-dd"
    return [
        Foundation.Date.now.addingTimeInterval(-60 * 60 * 24 * 7),
        Foundation.Date.now.addingTimeInterval(-60 * 60 * 24 * 2),
        Foundation.Date.now.addingTimeInterval(-60 * 60 * 24)
    ].map(formatter.string)
}

extension ShuttleRealtimeVC {
    private var selectedStopTabVC: ShuttleRealtimeTabVC {
        switch selectedPresenceIndex {
        case 1: shuttlecockOutTabVC
        case 2: stationTabVC
        case 3: terminalTabVC
        case 4: jungangStationTabVC
        case 5: shuttlecockInTabVC
        default: dormitoryOutTabVC
        }
    }

    func scrollToStop(_ stopID: String) {
        let index: Int
        switch stopID {
        case "dormitory_o": index = 0
        case "shuttlecock_o": index = 1
        case "station": index = 2
        case "terminal": index = 3
        case "jungang_stn": index = 4
        case "shuttlecock_i": index = 5
        default: return
        }
        hasManualStopSelection = true
        hasCompletedInitialLocationSelection = true
        pendingGPSTabIndex = nil
        pendingInitialStopLocation = nil
        locationManager.stopUpdatingLocation()
        listHeader.setLocationSource(isManual: true)
        selectStop(at: index)
    }

    /// Drops a manual stop choice and runs the nearest-stop lookup again.
    private func returnToNearestStop() {
        hasManualStopSelection = false
        hasCompletedInitialLocationSelection = false
        pendingInitialStopLocation = nil
        checkUserDeviceLocationServiceAuthorization()
    }

    private func selectStop(at index: Int) {
        guard stopTitles.indices.contains(index) else { return }
        selectedPresenceIndex = index
        listHeader.setSelectedStop(index)
        pager.moveToPage(index: index)
        updatePresenceStatus(viewerCount: nil)
        reportPresence()
    }

    private func applyInitialStop(for location: CLLocation) {
        guard !hasCompletedInitialLocationSelection,
              !hasManualStopSelection,
              let initialStopRules
        else { return }
        let configuredStopID = ShuttleInitialStopResolver.resolve(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            rules: initialStopRules
        )
        let configuredIndex = configuredStopID.flatMap(Self.presenceStopIds.firstIndex)
        let nearestIndex = stopLocation.indices.dropLast().min {
            location.distance(from: stopLocation[$0]) < location.distance(from: stopLocation[$1])
        }
        guard let position = configuredIndex ?? nearestIndex else { return }

        hasCompletedInitialLocationSelection = true
        listHeader.setLocationSource(isManual: false)
        if isShowingCoachMarks {
            pendingGPSTabIndex = position
            locationManager.stopUpdatingLocation()
            return
        }
        showToastMessage(
            image: UIImage(systemName: "checkmark.circle.fill"),
            message: String(
                format: String(localized: "toast.success.shuttle.realtime.location.%@"),
                stopTitles[position]
            )
        )
        selectStop(at: position)
        locationManager.stopUpdatingLocation()
    }
}

extension ShuttleRealtimeVC: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasCompletedInitialLocationSelection,
              !hasManualStopSelection,
              let currentLocation = locations.last
        else {
            locationManager.stopUpdatingLocation()
            return
        }
        guard initialStopRules != nil else {
            pendingInitialStopLocation = currentLocation
            locationManager.stopUpdatingLocation()
            return
        }
        applyInitialStop(for: currentLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        hasCompletedInitialLocationSelection = true
        pendingInitialStopLocation = nil
        locationManager.stopUpdatingLocation()
        showToastMessage(
            image: UIImage(systemName: "exclamationmark.triangle.fill"),
            message: String(localized: "toast.error.shuttle.realtime.location")
        )
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserDeviceLocationServiceAuthorization()
    }

    #if DEBUG
        func presentDebugQuickSettings() {
            openQuickSettings()
        }

        func presentDebugStopSheet(_ stop: ShuttleStopEnum) {
            openShuttleStopVC(stop)
        }
    #endif
}

extension ShuttleRealtimeVC {
    func updateHeaderInset() {
        // The header is pinned above the pager, so lists only need a small gap below it.
        let top: CGFloat = 8
        // The floating tab bar overlaps the bottom of the list, so keep the last rows clear of it.
        let bottom = max(view.safeAreaInsets.bottom, 34) + Self.tabBarClearance
        guard abs(bottom - appliedHeaderHeight) > 0.5 else { return }
        appliedHeaderHeight = bottom
        tabVCs.forEach { $0.setContentInsets(top: top, bottom: bottom) }
    }
}

extension ShuttleRealtimeVC: ContentViewDelegate {
    func didMoveToPage(index: Int) {
        handleUserStopSelection(index, fromSwipe: true)
    }
}

extension ShuttleRealtimeVC {
    private func handleUserStopSelection(_ index: Int, fromSwipe: Bool) {
        guard stopTitles.indices.contains(index) else { return }
        if !fromSwipe {
            pager.moveToPage(index: index)
        } else {
            listHeader.setSelectedStop(index)
        }
        hasManualStopSelection = true
        hasCompletedInitialLocationSelection = true
        pendingGPSTabIndex = nil
        locationManager.stopUpdatingLocation()
        selectedPresenceIndex = index
        updatePresenceStatus(viewerCount: nil)
        reportPresence()
        listHeader.setLocationSource(isManual: true)
    }
} // swiftlint:disable:this file_length
