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
    private lazy var helpButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = Self.actionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "questionmark.circle")?.withConfiguration(UIImage.SymbolConfiguration(
            pointSize: 16,
            weight: .semibold
        ))
        config.attributedTitle = AttributedString(String(localized: "common.help"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 14, weight: .bold)
        ]))
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 12)
        $0.configuration = config
        $0.accessibilityLabel = String(localized: "bus.help")
        $0.accessibilityIdentifier = "bus.open_help"
        $0.addTarget(self, action: #selector(openHelpVC), for: .touchUpInside)
    }

    private lazy var helpBar = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.borderWidth = 1 / UIScreen.main.scale
        $0.layer.borderColor = UIColor.separator.cgColor
    }

    private lazy var helpBarLabel = UILabel().then {
        $0.text = String(localized: "bus.action_bar.title")
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
            id: "bus.help",
            targetView: helpButton,
            title: String(localized: "coach.bus.help.title"),
            message: String(localized: "coach.bus.help.message")
        ))
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
        view.addSubview(helpBar)
        helpBar.addSubview(helpBarLabel)
        helpBar.addSubview(helpButton)
        viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.helpBar.snp.top)
        }
        helpBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(54)
        }
        helpBarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        helpButton.snp.makeConstraints { make in
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
        guard let location = locations.last, !didSelectBusStop else { return }
        let stops: [(id: Int, lat: Double, lng: Double)] = [
            (216_000_379, 37.2935, 126.8368),
            (216_000_381, 37.2953, 126.8382),
            (216_000_383, 37.2966, 126.8394)
        ]
        let nearest = stops.min {
            let d1 = pow(location.coordinate.latitude - $0.lat, 2) + pow(location.coordinate.longitude - $0.lng, 2)
            let d2 = pow(location.coordinate.latitude - $1.lat, 2) + pow(location.coordinate.longitude - $1.lng, 2)
            return d1 < d2
        }
        if let stop = nearest {
            UserDefaults.standard.set(stop.id, forKey: "busStopID")
            BusRealtimeData.shared.selectedBusStopID.onNext(Int32(stop.id))
            didSelectBusStop = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Use default stop (216000379) on location failure
    }

    private func observeSubjects() {
        BusRealtimeData.shared.busRealtimeData.subscribe(onNext: { [weak self] result in
            guard let self else { return }
            let isLoading = (try? BusRealtimeData.shared.isLoading.value()) ?? false
            if isLoading, result.isEmpty {
                return
            }
            let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216_000_379 : UserDefaults.standard
                .integer(forKey: "busStopID"))
            // City bus (10-1) — always update regardless of Seoul bus availability
            let cityFromCampus = result.first(where: { $0.stop.seq == selectedStopID && $0.route.seq == 216_000_068 })
            BusRealtimeData.shared.busRealtimeCityFromCampus.onNext(
                cityFromCampus.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            let cityFromStation = result.first(where: { $0.stop.seq == 216_000_138 && $0.route.seq == 216_000_068 })
            BusRealtimeData.shared.busRealtimeCityFromStation.onNext(
                cityFromStation.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            // Seoul bus (3102) — may not serve all stops, set empty if not available
            let seoulFromCampus = result.first(where: { $0.stop.seq == selectedStopID && $0.route.seq == 216_000_061 })
            BusRealtimeData.shared.busRealtimeSeoulFromCampus.onNext(
                seoulFromCampus.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            // Other fixed-stop buses
            let gunpoFromCampus = result
                .filter {
                    $0.stop
                        .seq == 216_000_719 && ($0.route.seq == 216_000_096 || $0.route.seq == 216_000_026 || $0.route.seq == 216_000_043)
                }
            BusRealtimeData.shared.busRealtimeGunpoFromCampus.onNext(
                gunpoFromCampus.flatMap { route in route.arrival.map { BusArrivalItem(route: route.route.name, item: $0) } }.sorted()
            )
            let suwonFromCampus = result
                .filter { $0.stop.seq == 216_000_070 && ($0.route.seq == 216_000_104 || $0.route.seq == 200_000_015) }
            BusRealtimeData.shared.busRealtimeSuwonFromCampus.onNext(
                suwonFromCampus.flatMap { route in route.arrival.map { BusArrivalItem(route: route.route.name, item: $0) } }.sorted()
            )
            let ktxFromCampus = result.first(where: { $0.stop.seq == 216_000_759 && $0.route.seq == 216_000_075 })
            BusRealtimeData.shared.busRealtimeKTXFromCampus.onNext(
                ktxFromCampus.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            let ktxFromStation = result.first(where: { $0.stop.seq == 213_000_487 && $0.route.seq == 216_000_075 })
            BusRealtimeData.shared.busRealtimeKTXFromStation.onNext(
                ktxFromStation.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
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
        Task {
            let response = try? await Network.shared.client.fetch(
                query: BusRealtimePageQuery(language: noticeLanguage),
                cachePolicy: .networkOnly
            )
            await MainActor.run {
                if let data = response?.data {
                    BusRealtimeData.shared.busRealtimeData.onNext(data.bus)
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

    @objc func openHelpVC() {
        AnalyticsManager.logSelect(.busOpenHelp)
        let vc = BusHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true, completion: nil)
    }
}
