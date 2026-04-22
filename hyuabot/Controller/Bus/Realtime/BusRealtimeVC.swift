import UIKit
import RxSwift
import Api

class BusRealtimeVC: UIViewController {
    private let disposeBag = DisposeBag()
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
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fixed(width: 125, height: 60, spacing: 0))
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
    private let loadingSpinner = UIActivityIndicatorView().then {
        $0.style = .large
        $0.color = .label
    }
    private let loadingLabel = UILabel().then {
        $0.text = String(localized: "bus.realtime.loading")
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startPolling()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopPolling()
    }
    
    private func setupUI() {
        self.view.addSubview(viewPager)
        self.view.addSubview(loadingView)
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
        self.loadingView.snp.makeConstraints { make in
            make.edges.equalTo(viewPager)
        }
    }
    
    private func observeSubjects() {
        BusRealtimeData.shared.busRealtimeData.subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            // Get the data for each bus stop and route}
            guard let busRealtimeCityFromCampus = result.first(where: { $0.stop.seq == 216000379 && $0.route.seq == 216000068 }) else { return }
            guard let busRealtimeCityFromStation = result.first(where: { $0.stop.seq == 216000138 && $0.route.seq == 216000068 }) else { return }
            guard let busRealtimeSeoulFromCampus = result.first(where: { $0.stop.seq == 216000379 && $0.route.seq == 216000061 }) else { return }
            let busRealtimeGunpoFromCampus = result.filter { $0.stop.seq == 216000719 && ($0.route.seq == 216000096 || $0.route.seq == 216000026 || $0.route.seq == 216000043) }
            let busRealtimeSuwonBusJunctionData = result.filter { $0.stop.seq == 216000070 && ($0.route.seq == 216000104 || $0.route.seq == 200000015) }
            guard let busRealtimeAnsanToGwangmyeongData = result.first(where: { $0.stop.seq == 216000759 && $0.route.seq == 216000075 }) else { return }
            guard let busRealtimeGwangmyeongToAnsanData = result.first(where: { $0.stop.seq == 213000487 && $0.route.seq == 216000075 }) else { return }
            // Combine the data
            BusRealtimeData.shared.busRealtimeCityFromCampus.onNext(busRealtimeCityFromCampus.arrival.map { BusArrivalItem(route: busRealtimeCityFromCampus.route.name, item: $0) }.sorted())
            BusRealtimeData.shared.busRealtimeCityFromStation.onNext(busRealtimeCityFromStation.arrival.map { BusArrivalItem(route: busRealtimeCityFromStation.route.name, item: $0) }.sorted())
            BusRealtimeData.shared.busRealtimeSeoulFromCampus.onNext(busRealtimeSeoulFromCampus.arrival.map { BusArrivalItem(route: busRealtimeSeoulFromCampus.route.name, item: $0) }.sorted())
            BusRealtimeData.shared.busRealtimeGunpoFromCampus.onNext(busRealtimeGunpoFromCampus.flatMap { route in route.arrival.map { BusArrivalItem(route: route.route.name, item: $0) } }.sorted())
            BusRealtimeData.shared.busRealtimeSuwonFromCampus.onNext(busRealtimeSuwonBusJunctionData.flatMap { route in route.arrival.map { BusArrivalItem(route: route.route.name, item: $0) } }.sorted())
            BusRealtimeData.shared.busRealtimeKTXFromCampus.onNext(busRealtimeAnsanToGwangmyeongData.arrival.map { BusArrivalItem(route: busRealtimeAnsanToGwangmyeongData.route.name, item: $0) }.sorted())
            BusRealtimeData.shared.busRealtimeKTXFromStation.onNext(busRealtimeGwangmyeongToAnsanData.arrival.map { BusArrivalItem(route: busRealtimeGwangmyeongToAnsanData.route.name, item: $0) }.sorted())
            // Reload the table view
            self.cityBusTabVC.reload()
            self.seoulBusTabVC.reload()
            self.suwonBusTabVC.reload()
            self.otherBusTabVC.reload()
            // Set the loading state to false
            BusRealtimeData.shared.isLoading.onNext(false)
        }).disposed(by: self.disposeBag)
        BusRealtimeData.shared.isLoading.subscribe(onNext: { isLoading in
            if (isLoading) {
                self.loadingView.isHidden = false
                self.loadingSpinner.startAnimating()
            } else {
                self.loadingView.isHidden = true
                self.loadingSpinner.stopAnimating()
            }
        }).disposed(by: disposeBag)
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
            let response = try? await Network.shared.client.fetch(query: BusRealtimePageQuery(language: noticeLanguage))
            if let data = response?.data {
                BusRealtimeData.shared.isLoading.onNext(false)
                BusRealtimeData.shared.busRealtimeData.onNext(data.bus)
                BusRealtimeData.shared.notices.onNext(data.notices.flatMap { $0.notices })
            }
        }
    }
    
    private func startPolling() {
        self.fetchBusRealtimeData()
        subscription = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
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
        let vc = BusHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
}
