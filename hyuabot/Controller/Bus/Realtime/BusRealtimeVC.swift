import UIKit
import CoreLocation
import RxSwift
import Api

class BusRealtimeVC: UIViewController, CLLocationManagerDelegate {
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var didSelectBusStop = false
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
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "questionmark.circle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openHelpVC), for: .touchUpInside)
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
        let viewPager = ViewPager(sizeConfiguration: .fixed(width: 125, height: 60, spacing: 0), optionView: nil, noticeView: self.noticeView)
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
        self.logScreenView(.busRealtime)
        self.showCoachMarksIfNeeded()
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
            ),
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
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startPolling()
        self.noticeView.resumeAutoScroll()
        self.selectNearestBusStop()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopPolling()
        self.noticeView.stopAutoScroll()
    }
    
    private func setupUI() {
        self.view.addSubview(viewPager)
        self.view.addSubview(helpButton)
        self.viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.helpButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.width.height.equalTo(50)
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
            (216000379, 37.2935, 126.8368),
            (216000381, 37.2953, 126.8382),
            (216000383, 37.2966, 126.8394)
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
            guard let self = self else { return }
            let isLoading = (try? BusRealtimeData.shared.isLoading.value()) ?? false
            if isLoading && result.isEmpty {
                return
            }
            let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216000379 : UserDefaults.standard.integer(forKey: "busStopID"))
            // City bus (10-1) — always update regardless of Seoul bus availability
            let cityFromCampus = result.first(where: { $0.stop.seq == selectedStopID && $0.route.seq == 216000068 })
            BusRealtimeData.shared.busRealtimeCityFromCampus.onNext(
                cityFromCampus.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            let cityFromStation = result.first(where: { $0.stop.seq == 216000138 && $0.route.seq == 216000068 })
            BusRealtimeData.shared.busRealtimeCityFromStation.onNext(
                cityFromStation.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            // Seoul bus (3102) — may not serve all stops, set empty if not available
            let seoulFromCampus = result.first(where: { $0.stop.seq == selectedStopID && $0.route.seq == 216000061 })
            BusRealtimeData.shared.busRealtimeSeoulFromCampus.onNext(
                seoulFromCampus.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            // Other fixed-stop buses
            let gunpoFromCampus = result.filter { $0.stop.seq == 216000719 && ($0.route.seq == 216000096 || $0.route.seq == 216000026 || $0.route.seq == 216000043) }
            BusRealtimeData.shared.busRealtimeGunpoFromCampus.onNext(
                gunpoFromCampus.flatMap { route in route.arrival.map { BusArrivalItem(route: route.route.name, item: $0) } }.sorted()
            )
            let suwonFromCampus = result.filter { $0.stop.seq == 216000070 && ($0.route.seq == 216000104 || $0.route.seq == 200000015) }
            BusRealtimeData.shared.busRealtimeSuwonFromCampus.onNext(
                suwonFromCampus.flatMap { route in route.arrival.map { BusArrivalItem(route: route.route.name, item: $0) } }.sorted()
            )
            let ktxFromCampus = result.first(where: { $0.stop.seq == 216000759 && $0.route.seq == 216000075 })
            BusRealtimeData.shared.busRealtimeKTXFromCampus.onNext(
                ktxFromCampus.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            let ktxFromStation = result.first(where: { $0.stop.seq == 213000487 && $0.route.seq == 216000075 })
            BusRealtimeData.shared.busRealtimeKTXFromStation.onNext(
                ktxFromStation.map { item in item.arrival.map { BusArrivalItem(route: item.route.name, item: $0) }.sorted() } ?? []
            )
            // Reload the table view
            self.cityBusTabVC.reload()
            self.seoulBusTabVC.reload()
            self.suwonBusTabVC.reload()
            self.otherBusTabVC.reload()
            // Set the loading state to false
            BusRealtimeData.shared.isLoading.onNext(false)
        }).disposed(by: self.disposeBag)
        BusRealtimeData.shared.notices.subscribe(onNext: { notices in
            if notices.isEmpty {
                self.noticeView.isHidden = true
                self.noticeView.stopAutoScroll()
            } else {
                self.noticeView.isHidden = false
                self.noticeView.setupUI(with: notices.map { Notice(title: $0.title, url: $0.url) })
            }
        }).disposed(by: self.disposeBag)
    }
    
    private func fetchBusRealtimeData() {
        var currentLanguage: String {
            Locale.current.language.languageCode?.identifier ?? "ko"
        }
        var noticeLanguage: String {
            if currentLanguage.starts(with: "ko") {
                return "KOREAN"
            } else if currentLanguage.starts(with: "en") {
                return "ENGLISH"
            } else {
                return "KOREAN"
            }
        }
        Task {
            let response = try? await Network.shared.client.fetch(query: BusRealtimePageQuery(language: noticeLanguage), cachePolicy: .networkOnly)
            await MainActor.run {
                if let data = response?.data {
                    BusRealtimeData.shared.busRealtimeData.onNext(data.bus)
                    BusRealtimeData.shared.notices.onNext(data.notices.flatMap { $0.notices })
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
        self.fetchBusRealtimeData()
        subscription = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchBusRealtimeData()
            })
    }
    
    private func stopPolling() {
        subscription?.dispose()
    }
    
    private func moveToEntireTimetable(_ stopID: Int32, _ routes: [Int32], _ title: String.LocalizationValue) {
        guard let nc = self.navigationController as? BusNC else { return }
        nc.moveToTimetableVC(stopID: stopID, routes: routes, title: title)
    }
    
    private func openDepartureLogSheet(_ stopID: Int32, _ routes: [Int32]) {
        let vc = BusLogVC(stopID: stopID, routes: routes)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func openBusStopVC(_ stopID: Int32, _ routes: [Int32]) {
        let vc = BusStopInfoVC(input: routes.map { BusRouteStopInput(route: $0, stop: stopID)})
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
    @objc func openHelpVC() {
        AnalyticsManager.logSelect(.busOpenHelp)
        let vc = BusHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
}
