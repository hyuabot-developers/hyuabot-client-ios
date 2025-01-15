import UIKit
import RxSwift
import QueryAPI

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
        BusRealtimeData.shared.busRealtimeData.subscribe(onNext: { [weak self] busData in
            guard let busData = busData else { return }
            // Get the data for each bus
            let campusData: [BusRealtimePageQuery.Data.Bus.Route] = busData.first { $0.id == 216000379 }?.routes ?? []
            let sangnoksuData: [BusRealtimePageQuery.Data.Bus.Route] = busData.first { $0.id == 216000138 }?.routes ?? []
            let mainGateData: [BusRealtimePageQuery.Data.Bus.Route] = busData.first { $0.id == 216000719 }?.routes ?? []
            let junctionData: [BusRealtimePageQuery.Data.Bus.Route] = busData.first { $0.id == 216000070 }?.routes ?? []
            let ansanData: [BusRealtimePageQuery.Data.Bus.Route] = busData.first { $0.id == 216000759 }?.routes ?? []
            let gwangmyeongData: [BusRealtimePageQuery.Data.Bus.Route] = busData.first { $0.id == 213000487 }?.routes ?? []
            // Filter the data
            let campusToSangnoksu: [BusRealtimePageQuery.Data.Bus.Route] = campusData.filter { $0.info.id == 216000068 }
            let sangnoksuToCampus: [BusRealtimePageQuery.Data.Bus.Route] = sangnoksuData.filter { $0.info.id == 216000068 }
            let campusToSeoul: [BusRealtimePageQuery.Data.Bus.Route] = campusData.filter { $0.info.id == 216000061 }
            let mainGateToSeoul: [BusRealtimePageQuery.Data.Bus.Route] = mainGateData.filter {
                $0.info.id == 216000026 || $0.info.id == 216000043 || $0.info.id == 216000096
            }
            let mainGateToSuwon: [BusRealtimePageQuery.Data.Bus.Route] = mainGateData.filter {
                $0.info.id == 216000070
            }
            let junctionToSuwon: [BusRealtimePageQuery.Data.Bus.Route] = junctionData.filter {
                $0.info.id == 217000014 || $0.info.id == 216000070 || $0.info.id == 216000104 || $0.info.id == 200000015
            }
            let ansanToGwangmyeong: [BusRealtimePageQuery.Data.Bus.Route] = ansanData.filter { $0.info.id == 216000075 }
            let gwangmyeongToAnsan: [BusRealtimePageQuery.Data.Bus.Route] = gwangmyeongData.filter { $0.info.id == 216000075 }
            // Combine the data
            BusRealtimeData.shared.cityBusCampusData.onNext(self?.combineArrivalData(campusToSangnoksu) ?? [])
            BusRealtimeData.shared.cityBusStationData.onNext(self?.combineArrivalData(sangnoksuToCampus) ?? [])
            BusRealtimeData.shared.seoulBusCampusData.onNext(self?.combineArrivalData(campusToSeoul) ?? [])
            BusRealtimeData.shared.seoulBusMainGateData.onNext(self?.combineArrivalData(mainGateToSeoul) ?? [])
            BusRealtimeData.shared.suwonBusCampusData.onNext(self?.combineArrivalData(mainGateToSuwon) ?? [])
            BusRealtimeData.shared.suwonBusJunctionData.onNext(self?.combineArrivalData(junctionToSuwon) ?? [])
            BusRealtimeData.shared.otherBusAnsanData.onNext(self?.combineArrivalData(ansanToGwangmyeong) ?? [])
            BusRealtimeData.shared.otherBusGwangmyeongStationData.onNext(self?.combineArrivalData(gwangmyeongToAnsan) ?? [])
            // Reload the table view
            self?.cityBusTabVC.reload()
            self?.seoulBusTabVC.reload()
            self?.suwonBusTabVC.reload()
            self?.otherBusTabVC.reload()
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
    
    private func combineArrivalData(_ routes: [BusRealtimePageQuery.Data.Bus.Route]) -> [BusRealtimeItem] {
        var realtimeData: [BusRealtimeItem] = []
        var timetableData: [BusRealtimeItem] = []
        routes.forEach { route in
            route.realtime.forEach { realtimeItem in
                realtimeData.append(BusRealtimeItem(routeName: route.info.name, realtime: realtimeItem))
            }
            route.timetable.forEach { timetableItem in
                timetableData.append(BusRealtimeItem(routeName: route.info.name, timetable: timetableItem))
            }
        }
        return realtimeData.sorted(
            by: { $0.realtime?.time ?? 0 < $1.realtime?.time ?? 0 }
        ) + timetableData.sorted(
            by: { $0.timetable?.time ?? "00:00:00" < $1.timetable?.time ?? "00:00:00" }
        )
    }
        
    
    private func fetchBusRealtimeData() {
        let timeFormatter = DateFormatter().then {
            $0.dateFormat = "HH:mm"
        }
        let time = timeFormatter.string(from: Date.now)
        Network.shared.client.fetch(query: BusRealtimePageQuery(busStart: time)) { result in
            if case .success(let data) = result {
                BusRealtimeData.shared.isLoading.onNext(false)
                BusRealtimeData.shared.busRealtimeData.onNext(data.data?.bus ?? [])
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
    
    private func moveToEntireTimetable(_ stopID: Int, _ routes: [Int]) {
        guard let nc = self.navigationController as? BusNC else { return }
        nc.moveToTimetableVC(stopID: stopID, routes: routes)
    }
    
    private func openDepartureLogSheet(_ stopID: Int, _ routes: [Int]) {
        let vc = BusLogVC(stopID: stopID, routes: routes)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func openBusStopVC(_ stopID: Int) {
        let vc = BusStopInfoVC(stopID: stopID)
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
