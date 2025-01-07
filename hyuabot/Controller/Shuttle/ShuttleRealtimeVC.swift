import UIKit
import RxSwift
import QueryAPI

class ShuttleRealtimeVC: UIViewController {
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let disposeBag = DisposeBag()
    private lazy var dormitoryOutTabVC = ShuttleRealtimeTabVC(stopID: .dormiotryOut, refreshMethod: fetchShuttleRealtimeData)
    private lazy var shuttlecockOutTabVC = ShuttleRealtimeTabVC(stopID: .shuttlecockOut, refreshMethod: fetchShuttleRealtimeData)
    private lazy var stationTabVC = ShuttleRealtimeTabVC(stopID: .station, refreshMethod: fetchShuttleRealtimeData)
    private lazy var terminalTabVC = ShuttleRealtimeTabVC(stopID: .terminal, refreshMethod: fetchShuttleRealtimeData)
    private lazy var jungangStationTabVC = ShuttleRealtimeTabVC(stopID: .jungangStation, refreshMethod: fetchShuttleRealtimeData)
    private lazy var shuttlecockInTabVC = ShuttleRealtimeTabVC(stopID: .shuttlecockIn, refreshMethod: fetchShuttleRealtimeData)
    private var subscription: Disposable?
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fixed(width: 125, height: 60, spacing: 0))
        // Add the content pages to the view pager
        viewPager.contentView.pages = [
            dormitoryOutTabVC.view,
            shuttlecockOutTabVC.view,
            stationTabVC.view,
            terminalTabVC.view,
            jungangStationTabVC.view,
            shuttlecockInTabVC.view
        ]
        // Add the tab titles to the view pager
        viewPager.tabView.tabs = [
            TabItem(title: String(localized: "shuttle.stop.dormitory.out")),
            TabItem(title: String(localized: "shuttle.stop.shuttlecock.out")),
            TabItem(title: String(localized: "shuttle.stop.station")),
            TabItem(title: String(localized: "shuttle.stop.terminal")),
            TabItem(title: String(localized: "shuttle.stop.jungang.station")),
            TabItem(title: String(localized: "shuttle.stop.shuttlecock.in"))
        ]
        return viewPager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startPolling()
        // Detect if the app is in the background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopPolling()
    }
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
    
    private func setupUI() {
        self.view.addSubview(viewPager)
        self.viewPager.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func observeSubjects() {
        ShuttleRealtimeData.shared.shuttleRealtimeData.subscribe(onNext: { data in
            ShuttleRealtimeData.shared.shuttleDormitoryToStationData.onNext(data?.filter({ $0.stop == "dormitory_o" && ($0.tag == "DH" || $0.tag == "DJ" || $0.tag == "C") }))
            ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.onNext(data?.filter({ $0.stop == "dormitory_o" && ($0.tag == "DY" || $0.tag == "C") }))
            ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.onNext(data?.filter({ $0.stop == "dormitory_o" && $0.tag == "DJ" }))
            ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.onNext(data?.filter({ $0.stop == "shuttlecock_o" && ($0.tag == "DH" || $0.tag == "DJ" || $0.tag == "C") }))
            ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.onNext(data?.filter({ $0.stop == "shuttlecock_o" && ($0.tag == "DY" || $0.tag == "C") }))
            ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.onNext(data?.filter({ $0.stop == "shuttlecock_o" && $0.tag == "DJ" }))
            ShuttleRealtimeData.shared.shuttleStationToCampusData.onNext(data?.filter({ $0.stop == "station" }))
            ShuttleRealtimeData.shared.shuttleStationToTerminalData.onNext(data?.filter({ $0.stop == "station" && $0.tag == "C" }))
            ShuttleRealtimeData.shared.shuttleStationToJungangStationData.onNext(data?.filter({ $0.stop == "station" && $0.tag == "DJ" }))
            ShuttleRealtimeData.shared.shuttleTerminalToCampusData.onNext(data?.filter({ $0.stop == "terminal" }))
            ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.onNext(data?.filter({ $0.stop == "jungang_stn" }))
            ShuttleRealtimeData.shared.shuttleShuttlecockToDormitoryData.onNext(data?.filter({ $0.stop == "shuttlecock_i" && $0.route.hasSuffix("D") }))
            self.dormitoryOutTabVC.reload()
            self.shuttlecockOutTabVC.reload()
            self.stationTabVC.reload()
            self.terminalTabVC.reload()
            self.jungangStationTabVC.reload()
            self.shuttlecockInTabVC.reload()
        }).disposed(by: self.disposeBag)
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
    
    private func fetchShuttleRealtimeData() {
        let now = Date.now
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm" }
        let dateTimeFormatter = DateFormatter().then { $0.dateFormat = "yyyy-MM-dd HH:mm" }
        let dataDelegate = ShuttleRealtimeData.shared
        Network.shared.client.fetch(query: ShuttleRealtimePageQuery(shuttleStart: timeFormatter.string(from: now), shuttleDateTime: dateTimeFormatter.string(from: now))) { result in
            if case .success(let response) = result {
                dataDelegate.shuttleRealtimeData.onNext(response.data?.shuttle.timetable.filter({ self.isAfterNow(item: $0) }))
            }
        }
    }
    
    private func isAfterNow(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date.now
        let nowString = dateFormatter.string(from: now)
        return nowString < item.time
    }
}
