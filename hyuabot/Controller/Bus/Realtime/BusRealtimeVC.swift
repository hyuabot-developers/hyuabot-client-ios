import Api
import CoreLocation
import RxSwift
import UIKit

// swiftlint:disable:next type_body_length
class BusRealtimeVC: UIViewController, @preconcurrency CLLocationManagerDelegate {
    private static let actionButtonBackground = UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1.00)

    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var didSelectBusStop = false
    private var lastLocation: CLLocation?
    private var hasLoadedInitialNotices = false
    private lazy var cityBusTabVC = BusRealtimeTabVC(
        tabType: .city,
        refreshMethod: fetchBusRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showDepartureLog: openDepartureLogSheet,
        showStopVC: openBusStopVC
    )
    private lazy var seoulBusTabVC = BusRealtimeTabVC(
        tabType: .seoul,
        refreshMethod: fetchBusRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showDepartureLog: openDepartureLogSheet,
        showStopVC: openBusStopVC
    )
    private lazy var suwonBusTabVC = BusRealtimeTabVC(
        tabType: .suwon,
        refreshMethod: fetchBusRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showDepartureLog: openDepartureLogSheet,
        showStopVC: openBusStopVC
    )
    private lazy var otherBusTabVC = BusRealtimeTabVC(
        tabType: .other,
        refreshMethod: fetchBusRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showDepartureLog: openDepartureLogSheet,
        showStopVC: openBusStopVC
    )
    private var subscription: Disposable?
    private lazy var quickSettingsButton = UIButton(type: .system).then {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = Self.actionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "slider.horizontal.3")?.withConfiguration(UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold
        ))
        config.attributedTitle = AttributedString(
            String(localized: "shuttle.quick_settings.button"),
            attributes: AttributeContainer([
                .font: UIFont.godo(size: 14, weight: .bold)
            ])
        )
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 12)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openQuickSettings), for: .touchUpInside)
        $0.accessibilityLabel = String(localized: "bus.quick_settings.title")
        $0.accessibilityIdentifier = "bus.quick_settings"
    }

    private lazy var quickSettingsBar = UIView().then {
        $0.backgroundColor = .clear
    }

    private let quickSettingsBarTopBorder = UIView().then {
        $0.backgroundColor = .separator
    }

    private lazy var quickSettingsBarLabel = UILabel().then {
        $0.textColor = .secondaryLabel
        $0.font = .godo(size: 13, weight: .bold)
    }

    private lazy var noticeView = NoticeCarouselView().then {
        $0.isHidden = true
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 10
        $0.onNoticeTapped = { [weak self] url in
            guard let url = URL(string: url) else { return }
            let vc = NoticeWebVC(url: url)
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            self?.present(vc, animated: true, completion: nil)
        }
    }

    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(
            sizeConfiguration: .fixed(width: 125, height: 52, spacing: 0),
            optionView: nil,
            noticeView: self.noticeView
        )
        // Add the content pages to the view pager
        viewPager.contentView.pages = [
            cityBusTabVC.view,
            seoulBusTabVC.view,
            suwonBusTabVC.view,
            otherBusTabVC.view
        ]
        // Add the tab titles to the view pager
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "bus.tab.city")),
            TabItem(title: String(localized: "bus.tab.seoul")),
            TabItem(title: String(localized: "bus.tab.suwon")),
            TabItem(title: String(localized: "bus.tab.other"))
        ]
        return viewPager
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.busRealtime)
        showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("bus.realtime") else { return }
        let isLoaded = (try? BusRealtimeData.shared.isLoading.value()) == false
        if isLoaded {
            presentBusRealtimeCoachMarks()
        } else {
            BusRealtimeData.shared.isLoading
                .filter { !$0 }
                .take(1)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self?.presentBusRealtimeCoachMarks()
                    }
                })
                .disposed(by: disposeBag)
        }
    }

    private func presentBusRealtimeCoachMarks() {
        var items: [CoachMarkItem] = [
            CoachMarkItem(
                id: "bus.tabs",
                targetView: viewPager.tabView,
                title: String(localized: "coach.bus.tabs.title"),
                message: String(localized: "coach.bus.tabs.message")
            )
        ]
        if !noticeView.isHidden {
            items.append(CoachMarkItem(
                id: "bus.notice",
                targetView: noticeView,
                title: String(localized: "coach.bus.notice.title"),
                message: String(localized: "coach.bus.notice.message")
            ))
        }
        items.append(CoachMarkItem(
            id: "bus.header.location",
            targetViewProvider: { [weak self] in self?.cityBusTabVC.firstSectionHeaderLocationButton },
            title: String(localized: "coach.bus.header.location.title"),
            message: String(localized: "coach.bus.header.location.message")
        ))
        items.append(CoachMarkItem(
            id: "bus.footer.timetable",
            targetViewProvider: { [weak self] in self?.cityBusTabVC.firstSectionFooterTimetableButton },
            title: String(localized: "coach.bus.footer.timetable.title"),
            message: String(localized: "coach.bus.footer.timetable.message")
        ))
        items.append(CoachMarkItem(
            id: "bus.footer.log",
            targetViewProvider: { [weak self] in self?.cityBusTabVC.firstSectionFooterLogButton },
            title: String(localized: "coach.bus.footer.log.title"),
            message: String(localized: "coach.bus.footer.log.message")
        ))
        presentCoachMarks(pageId: "bus.realtime", items: items)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
        noticeView.resumeAutoScroll()
        selectNearestBusStop()
        navigationController?.setNavigationBarHidden(true, animated: false)
        updateQuickSettingsBarLabel()
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
        noticeView.stopAutoScroll()
    }

    private func setupUI() {
        view.addSubview(viewPager)
        view.addSubview(quickSettingsBar)
        quickSettingsBar.addSubview(quickSettingsBarTopBorder)
        quickSettingsBar.addSubview(quickSettingsBarLabel)
        quickSettingsBar.addSubview(quickSettingsButton)
        viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.quickSettingsBar.snp.top)
        }
        quickSettingsBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(54)
        }
        quickSettingsBarTopBorder.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        quickSettingsBarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(quickSettingsButton.snp.leading).offset(-12)
        }
        quickSettingsButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    private func selectNearestBusStop() {
        guard !didSelectBusStop else { return }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        attemptNearestStopSelection()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Use default stop (216000379) on location failure
    }

    /// Picks the nearest stop per tab group (city / seoul-3102 / seoul-3100-family / suwon) from the
    /// coordinates returned by the bus API. Retried both when a new location arrives and when new bus
    /// data arrives, since either one may be the last piece needed.
    private func attemptNearestStopSelection() {
        guard !didSelectBusStop, let location = lastLocation else { return }
        guard let allBuses = try? BusRealtimeData.shared.busRealtimeData.value(), !allBuses.isEmpty else { return }

        func coordinate(_ seq: Int32) -> (lat: Double, lng: Double)? {
            guard let match = allBuses.first(where: { $0.stop.seq == seq }) else { return nil }
            return (match.stop.latitude, match.stop.longitude)
        }

        func nearest(_ candidates: [Int32]) -> Int32? {
            let withCoords = candidates.compactMap { seq -> (Int32, Double, Double)? in
                guard let coord = coordinate(seq) else { return nil }
                return (seq, coord.lat, coord.lng)
            }
            return withCoords.min {
                let d1 = pow(location.coordinate.latitude - $0.1, 2) + pow(location.coordinate.longitude - $0.2, 2)
                let d2 = pow(location.coordinate.latitude - $1.1, 2) + pow(location.coordinate.longitude - $1.2, 2)
                return d1 < d2
            }?.0
        }

        let campusStops: [Int32] = [216_000_379, 216_000_381, 216_000_383]
        let seoulRemoteStops: [Int32] = [121_000_060, 121_000_929, 121_000_974, 121_000_970, 121_000_220]

        guard let cityStop = nearest(campusStops) else { return }
        didSelectBusStop = true
        UserDefaults.standard.set(cityStop, forKey: "busStopID")
        BusRealtimeData.shared.selectedBusStopID.onNext(cityStop)

        if let seoulFirst = nearest(campusStops + seoulRemoteStops) {
            UserDefaults.standard.set(seoulFirst, forKey: "bus.seoulFirstStopID")
            BusRealtimeData.shared.seoulFirstSelectedStopID.onNext(seoulFirst)
        }
        if let seoulSecond = nearest([216_000_719] + seoulRemoteStops) {
            UserDefaults.standard.set(seoulSecond, forKey: "bus.seoulSecondStopID")
            BusRealtimeData.shared.seoulSecondSelectedStopID.onNext(seoulSecond)
        }
        if let suwon = nearest([216_000_070, 202_000_106]) {
            UserDefaults.standard.set(suwon, forKey: "bus.suwonStopID")
            BusRealtimeData.shared.suwonSelectedStopID.onNext(suwon)
        }
    }

    // swiftlint:disable:next function_body_length
    private func observeSubjects() {
        BusRealtimeData.shared.busRealtimeData.subscribe(onNext: { [weak self] result in
            guard let self else { return }
            attemptNearestStopSelection()
            let isLoading = (try? BusRealtimeData.shared.isLoading.value()) ?? false
            if isLoading, result.isEmpty {
                return
            }
            let showSecondary = (try? BusRealtimeData.shared.showSecondaryEta.value()) ?? true
            let seoulTarget = (try? BusRealtimeData.shared.seoulTargetStop.value()) ?? .gangnam
            let seoulRemoteStops: Set<Int32> = [121_000_060, 121_000_929, 121_000_974, 121_000_970, 121_000_220]
            let logs = (try? BusRealtimeData.shared.busSecondaryEtaLogs.value()) ?? []

            /// Realtime (GPS-tracked) arrivals never carry `arrivalTime` — only `minutes` remaining —
            /// so derive an absolute target time from "now + minutes" to still match against time-of-day log samples.
            func estimatedArrivalTime(for arrival: BusRealtimePageQuery.Data.Bus.Arrival) -> Api.LocalTime? {
                if let arrivalTime = arrival.arrivalTime { return arrivalTime }
                guard arrival.isRealtime, let minutes = arrival.minutes else { return nil }
                return Date.now.addingTimeInterval(Double(minutes) * 60).toLocalTimeString()
            }

            func logsFor(route: Int32, stop: Int32) -> [BusRealtimePageQuery.Data.Bus.Log] {
                logs.first(where: { $0.stop.seq == stop && $0.route.seq == route })?.log ?? []
            }

            func secondaryTime(
                primaryArrivalTime: Api.LocalTime?,
                primaryRoute: Int32,
                primaryStop: Int32,
                stop: Int32,
                route: Int32
            ) -> Api.LocalTime? {
                guard showSecondary, let primaryArrivalTime else { return nil }
                let secondaryLogs = logsFor(route: route, stop: stop)
                guard !secondaryLogs.isEmpty else { return nil }
                return BusTravelTimeEstimator.secondaryArrivalTime(
                    primaryArrivalTime: primaryArrivalTime,
                    primaryLogs: logsFor(route: primaryRoute, stop: primaryStop),
                    secondaryLogs: secondaryLogs
                )
            }

            let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216_000_379 : UserDefaults.standard
                .integer(forKey: "busStopID"))
            // City bus (10-1) — always update regardless of Seoul bus availability
            let cityFromCampus = result.first(where: { $0.stop.seq == selectedStopID && $0.route.seq == 216_000_068 })
            BusRealtimeData.shared.busRealtimeCityFromCampus.onNext(
                cityFromCampus.map { item in
                    item.arrival.map { arrival in
                        BusArrivalItem(
                            route: item.route.name,
                            item: arrival,
                            secondaryArrivalTime: secondaryTime(
                                primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: 216_000_068,
                                primaryStop: selectedStopID,
                                stop: 216_000_138, route: 216_000_068
                            )
                        )
                    }.sorted()
                } ?? []
            )
            let cityFromStation = result.first(where: { $0.stop.seq == 216_000_138 && $0.route.seq == 216_000_068 })
            BusRealtimeData.shared.busRealtimeCityFromStation.onNext(
                cityFromStation.map { item in
                    item.arrival.map { arrival in
                        BusArrivalItem(
                            route: item.route.name,
                            item: arrival,
                            secondaryArrivalTime: secondaryTime(
                                primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: 216_000_068, primaryStop: 216_000_138,
                                stop: 216_000_378, route: 216_000_068
                            )
                        )
                    }.sorted()
                } ?? []
            )
            // Seoul bus section 1 (3102) — primary stop widened to campus or one of 5 Seoul-bound stops
            let seoulFirstStopID = (try? BusRealtimeData.shared.seoulFirstSelectedStopID.value()) ?? 216_000_379
            let seoulFirstSecondaryStop: Int32 = seoulRemoteStops.contains(seoulFirstStopID) ? 216_000_378 : seoulTarget.stopID
            let seoulFromCampus = result.first(where: { $0.stop.seq == seoulFirstStopID && $0.route.seq == 216_000_061 })
            BusRealtimeData.shared.busRealtimeSeoulFromCampus.onNext(
                seoulFromCampus.map { item in
                    item.arrival.map { arrival in
                        BusArrivalItem(
                            route: item.route.name,
                            item: arrival,
                            secondaryArrivalTime: secondaryTime(
                                primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: 216_000_061,
                                primaryStop: seoulFirstStopID,
                                stop: seoulFirstSecondaryStop, route: 216_000_061
                            )
                        )
                    }.sorted()
                } ?? []
            )
            // Seoul bus section 2 (3100/3101/3100N) — primary stop widened to main gate or Seoul-bound stops
            let seoulSecondStopID = (try? BusRealtimeData.shared.seoulSecondSelectedStopID.value()) ?? 216_000_719
            let seoulSecondSecondaryStop: Int32 = seoulRemoteStops.contains(seoulSecondStopID) ? 216_000_048 : seoulTarget.stopID
            let gunpoFromCampus = result
                .filter {
                    $0.stop
                        .seq == seoulSecondStopID &&
                        ($0.route.seq == 216_000_096 || $0.route.seq == 216_000_026 || $0.route.seq == 216_000_043)
                }
            BusRealtimeData.shared.busRealtimeGunpoFromCampus.onNext(
                Array(
                    gunpoFromCampus.flatMap { route in
                        route.arrival.map { arrival in
                            BusArrivalItem(
                                route: route.route.name,
                                item: arrival,
                                secondaryArrivalTime: secondaryTime(
                                    primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: Int32(route.route.seq),
                                    primaryStop: seoulSecondStopID,
                                    stop: seoulSecondSecondaryStop, route: Int32(route.route.seq)
                                )
                            )
                        }
                    }.sorted().prefix(4)
                )
            )
            // Suwon bus (7070/9090) — primary stop widened to campus entrance or Suwon station
            let suwonStopID = (try? BusRealtimeData.shared.suwonSelectedStopID.value()) ?? 216_000_070
            let suwonSecondaryStop: Int32 = suwonStopID == 202_000_106 ? 216_000_141 : 202_000_208
            let suwonFromCampus = result
                .filter { $0.stop.seq == suwonStopID && ($0.route.seq == 216_000_104 || $0.route.seq == 200_000_015) }
            BusRealtimeData.shared.busRealtimeSuwonFromCampus.onNext(
                suwonFromCampus.flatMap { route in
                    route.arrival.map { arrival in
                        BusArrivalItem(
                            route: route.route.name,
                            item: arrival,
                            secondaryArrivalTime: secondaryTime(
                                primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: Int32(route.route.seq),
                                primaryStop: suwonStopID,
                                stop: suwonSecondaryStop, route: Int32(route.route.seq)
                            )
                        )
                    }
                }.sorted()
            )
            let ktxFromCampus = result.first(where: { $0.stop.seq == 216_000_759 && $0.route.seq == 216_000_075 })
            BusRealtimeData.shared.busRealtimeKTXFromCampus.onNext(
                ktxFromCampus.map { item in
                    item.arrival.map { arrival in
                        BusArrivalItem(
                            route: item.route.name,
                            item: arrival,
                            secondaryArrivalTime: secondaryTime(
                                primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: 216_000_075, primaryStop: 216_000_759,
                                stop: 213_000_487, route: 216_000_075
                            )
                        )
                    }.sorted()
                } ?? []
            )
            let ktxFromStation = result.first(where: { $0.stop.seq == 213_000_487 && $0.route.seq == 216_000_075 })
            BusRealtimeData.shared.busRealtimeKTXFromStation.onNext(
                ktxFromStation.map { item in
                    item.arrival.map { arrival in
                        BusArrivalItem(
                            route: item.route.name,
                            item: arrival,
                            secondaryArrivalTime: secondaryTime(
                                primaryArrivalTime: estimatedArrivalTime(for: arrival), primaryRoute: 216_000_075, primaryStop: 213_000_487,
                                stop: 216_000_117, route: 216_000_075
                            )
                        )
                    }.sorted()
                } ?? []
            )
            // Reload the table view
            cityBusTabVC.reload()
            seoulBusTabVC.reload()
            suwonBusTabVC.reload()
            otherBusTabVC.reload()
            // Set the loading state to false
            BusRealtimeData.shared.isLoading.onNext(false)
        }).disposed(by: disposeBag)
        BusRealtimeData.shared.notices.subscribe(onNext: { notices in
            if !self.hasLoadedInitialNotices, notices.isEmpty {
                self.noticeView.isHidden = false
                self.noticeView.setLoading(true)
            } else if notices.isEmpty {
                self.noticeView.isHidden = true
                self.noticeView.stopAutoScroll()
            } else {
                self.noticeView.isHidden = false
                self.noticeView.setupUI(with: notices.map { Notice(title: $0.title, url: $0.url) })
            }
        }).disposed(by: disposeBag)
    }

    private func fetchBusRealtimeData() {
        var currentLanguage: String {
            Locale.current.language.languageCode?.identifier ?? "ko"
        }
        var noticeLanguage: String {
            if currentLanguage.starts(with: "ko") {
                "KOREAN"
            } else {
                "ENGLISH"
            }
        }
        let dates = BusRecentDates.sameWeekdayType(count: 4)
        Task {
            let response = try? await Network.shared.client.fetch(
                query: BusRealtimePageQuery(language: noticeLanguage, dates: dates),
                cachePolicy: .networkOnly
            )
            await MainActor.run {
                if let data = response?.data {
                    BusRealtimeData.shared.busRealtimeData.onNext(data.bus)
                    BusRealtimeData.shared.busSecondaryEtaLogs.onNext(data.bus)
                    self.hasLoadedInitialNotices = true
                    BusRealtimeData.shared.notices.onNext(data.notices.flatMap(\.notices))
                    if data.bus.isEmpty {
                        BusRealtimeData.shared.isLoading.onNext(false)
                    }
                } else {
                    BusRealtimeData.shared.isLoading.onNext(false)
                }
            }
        }
    }

    private func startPolling() {
        fetchBusRealtimeData()
        subscription = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchBusRealtimeData()
            })
    }

    private func stopPolling() {
        subscription?.dispose()
    }

    private func moveToEntireTimetable(_ stopID: Int32, _ routes: [Int32], _ title: String.LocalizationValue) {
        guard let nc = navigationController as? BusNC else { return }
        nc.moveToTimetableVC(stopID: stopID, routes: routes, title: title)
    }

    private func openDepartureLogSheet(_ stopID: Int32, _ routes: [Int32]) {
        let vc = BusLogVC(stopID: stopID, routes: routes)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    private func openBusStopVC(_ stopID: Int32, _ routes: [Int32]) {
        let vc = BusStopInfoVC(input: routes.map { BusRouteStopInput(route: $0, stop: stopID) })
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    @objc func appDidEnterBackground() {
        stopPolling()
    }

    @objc func appWillEnterForeground() {
        startPolling()
    }

    @objc
    private func openQuickSettings() {
        let vc = BusQuickSettingsVC(
            showSecondaryEta: BusRealtimeDisplaySettings.showsSecondaryEta,
            seoulTarget: BusRealtimeDisplaySettings.seoulTargetStop
        )
        vc.updateShowSecondaryEta = { isOn in
            BusRealtimeDisplaySettings.showsSecondaryEta = isOn
            self.updateQuickSettingsBarLabel()
            BusRealtimeData.shared.showSecondaryEta.onNext(isOn)
            BusRealtimeData.shared.busRealtimeData.onNext((try? BusRealtimeData.shared.busRealtimeData.value()) ?? [])
        }
        vc.updateSeoulTarget = { target in
            BusRealtimeDisplaySettings.seoulTargetStop = target
            self.updateQuickSettingsBarLabel()
            BusRealtimeData.shared.seoulTargetStop.onNext(target)
            BusRealtimeData.shared.busRealtimeData.onNext((try? BusRealtimeData.shared.busRealtimeData.value()) ?? [])
        }
        vc.openHelp = { [weak self] in self?.openHelpVC() }
        vc.openInquiry = { [weak self] in self?.openInquiry() }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom { context in
                min(vc.preferredSheetHeight, context.maximumDetentValue)
            }]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    private func updateQuickSettingsBarLabel() {
        if BusRealtimeDisplaySettings.showsSecondaryEta {
            quickSettingsBarLabel.text = String(
                format: String(localized: "bus.quick_settings.action_bar.enabled"),
                BusRealtimeDisplaySettings.seoulTargetStop.title
            )
        } else {
            quickSettingsBarLabel.text = String(localized: "bus.quick_settings.action_bar.disabled")
        }
    }

    private func openHelpVC() {
        AnalyticsManager.logSelect(.busOpenHelp)
        let vc = BusHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }

    private func openInquiry() {
        navigationController?.pushViewController(
            InquiryChatVC(entryScreen: "bus", entryScreenName: "버스"),
            animated: true
        )
    }

    #if DEBUG
        func presentDebugQuickSettings() {
            openQuickSettings()
        }

        func presentDebugDepartureLog(stopID: Int32, routes: [Int32]) {
            openDepartureLogSheet(stopID, routes)
        }

        func presentDebugBusStop(stopID: Int32, routes: [Int32]) {
            openBusStopVC(stopID, routes)
        }
    #endif
} // swiftlint:disable:this file_length
