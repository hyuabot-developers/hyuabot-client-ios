import UIKit
import CoreLocation
import RxSwift
import Api

class ShuttleRealtimeVC: UIViewController {
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let disposeBag = DisposeBag()
    private lazy var locationManager = CLLocationManager().then {
        $0.delegate = self
    }
    private let stopLocation = [
        CLLocation(latitude: 37.29339607529377, longitude: 126.83630604103446),
        CLLocation(latitude:37.29875417910844, longitude: 126.83784054072336),
        CLLocation(latitude:37.309700971618255, longitude: 126.85207173389148),
        CLLocation(latitude:37.319338173415936, longitude: 126.8455263115596),
        CLLocation(latitude:37.31487247528457, longitude: 126.83963540399434),
        CLLocation(latitude:37.29869328231496, longitude: 126.8377767466817),
    ]
    private let shuttleShowByDestinationLabel = UILabel().then {
        $0.text = String(localized: "shuttle.realtime.showByDestination")
        $0.textColor = .white
        $0.font = .godo(size: 14, weight: .bold)
    }
    private let shuttleShowDepartureTimeLabel = UILabel().then {
        $0.text = String(localized: "shuttle.realtime.showDepartureTime")
        $0.textColor = .white
        $0.font = .godo(size: 14, weight: .bold)
    }
    private lazy var shuttleShowByDestination = UISwitch().then {
        $0.subviews.first?.subviews.first?.backgroundColor = .gray
        $0.addTarget(self, action: #selector(onClickShowArrivalByTimeSwitch(sender:)), for: .valueChanged)
    }
    private lazy var shuttleShowDepartureTime = UISwitch().then {
        $0.subviews.first?.subviews.first?.backgroundColor = .gray
        $0.addTarget(self, action: #selector(onClickDepartureSwitch(sender:)), for: .valueChanged)
    }
    private lazy var shuttleOptionView = UIView().then{
        $0.backgroundColor = .hanyangBlue
        $0.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
    }
    private lazy var dormitoryOutTabVC = ShuttleRealtimeTabVC(
        stopID: .dormiotryOut,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC
    )
    private lazy var shuttlecockOutTabVC = ShuttleRealtimeTabVC(
        stopID: .shuttlecockOut,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC
    )
    private lazy var stationTabVC = ShuttleRealtimeTabVC(
        stopID: .station,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC
    )
    private lazy var terminalTabVC = ShuttleRealtimeTabVC(
        stopID: .terminal,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC
    )
    private lazy var jungangStationTabVC = ShuttleRealtimeTabVC(
        stopID: .jungangStation,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC
    )
    private lazy var shuttlecockInTabVC = ShuttleRealtimeTabVC(
        stopID: .shuttlecockIn,
        refreshMethod: fetchShuttleRealtimeData,
        showEntireTimetable: moveToEntireTimetable,
        showViaVCByOrder: openShuttleViaVCByOrder,
        showViaVCByDestination: openShuttleViaVCByDestination,
        showStopVC: openShuttleStopVC
    )
    private lazy var helpButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "questionmark.circle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openHelpVC), for: .touchUpInside)
    }

    private var subscription: Disposable?
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fixed(width: 125, height: 60, spacing: 0), optionView: self.shuttleOptionView)
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
        self.checkBirthdayDialog()
        self.checkUserDeviceLocationServiceAuthorization()
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
    
    @objc func appDidEnterBackground() { self.stopPolling() }
    @objc func appWillEnterForeground() { self.startPolling() }
    
    private func setupUI() {
        self.shuttleOptionView.addSubview(self.shuttleShowByDestinationLabel)
        self.shuttleOptionView.addSubview(self.shuttleShowDepartureTimeLabel)
        self.shuttleOptionView.addSubview(self.shuttleShowByDestination)
        self.shuttleOptionView.addSubview(self.shuttleShowDepartureTime)
        self.shuttleShowByDestinationLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.shuttleOptionView.snp.centerY)
            make.leading.equalTo(self.shuttleOptionView.snp.leading).offset(10)
        }
        self.shuttleShowDepartureTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.shuttleOptionView.snp.centerY)
            make.leading.equalTo(self.shuttleOptionView.snp.centerX).offset(10)
        }
        self.shuttleShowByDestination.snp.makeConstraints { make in
            make.centerY.equalTo(self.shuttleOptionView.snp.centerY)
            make.trailing.equalTo(self.shuttleOptionView.snp.centerX).offset(-10)
        }
        self.shuttleShowDepartureTime.snp.makeConstraints { make in
            make.centerY.equalTo(self.shuttleOptionView.snp.centerY)
            make.trailing.equalTo(self.shuttleOptionView.snp.trailing).offset(-10)
        }
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
        // Option Switch
        let showRemainingTime = UserDefaults.standard.bool(forKey: "showRemainingTime")
        self.shuttleShowDepartureTime.isOn = !showRemainingTime
        ShuttleRealtimeData.shared.showRemainingTime.onNext(showRemainingTime)
        let showArrivalByTime = UserDefaults.standard.bool(forKey: "showArrivalByTime")
        self.shuttleShowByDestination.isOn = showArrivalByTime
        ShuttleRealtimeData.shared.showArrivalByTime.onNext(showArrivalByTime)
    }
    
    private func observeSubjects() {
        ShuttleRealtimeData.shared.arrival.subscribe(onNext: { data in
            let dormitory = data.first(where: { $0.name == "dormitory_o" })
            let shuttlecockOut = data.first(where: { $0.name == "shuttlecock_o" })
            let station = data.first(where: { $0.name == "station" })
            let terminal = data.first(where: { $0.name == "terminal" })
            let jungangStation = data.first(where: { $0.name == "jungang_stn" })
            let shuttlecockIn = data.first(where: { $0.name == "shuttlecock_i" })
            guard let dormitory = dormitory, let shuttlecockOut = shuttlecockOut, let station = station, let terminal = terminal, let jungangStation = jungangStation, let shuttlecockIn = shuttlecockIn else { return }
            let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm:ss" }
            let currentTime = timeFormatter.string(from: Date.now)
            ShuttleRealtimeData.shared.shuttleDormitoryData.onNext(dormitory.timetable.order)
            ShuttleRealtimeData.shared.shuttleDormitoryToStationData.onNext(dormitory.timetable.destination.first(where: { $0.destination == "STATION" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.onNext(dormitory.timetable.destination.first(where: { $0.destination == "TERMINAL" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.onNext(dormitory.timetable.destination.first(where: { $0.destination == "JUNGANG" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleShuttlecockData.onNext(shuttlecockOut.timetable.order)
            ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.onNext(shuttlecockOut.timetable.destination.first(where: { $0.destination == "STATION" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.onNext(shuttlecockOut.timetable.destination.first(where: { $0.destination == "TERMINAL" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.onNext(shuttlecockOut.timetable.destination.first(where: { $0.destination == "JUNGANG" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleStationData.onNext(station.timetable.order)
            ShuttleRealtimeData.shared.shuttleStationToCampusData.onNext(station.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleStationToTerminalData.onNext(station.timetable.destination.first(where: { $0.destination == "TERMINAL" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleStationToJungangStationData.onNext(station.timetable.destination.first(where: { $0.destination == "JUNGANG" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleTerminalData.onNext(terminal.timetable.order)
            ShuttleRealtimeData.shared.shuttleTerminalToCampusData.onNext(terminal.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleJungangStationData.onNext(jungangStation.timetable.order)
            ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.onNext(jungangStation.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.filter({ $0.time > currentTime }) ?? [])
            ShuttleRealtimeData.shared.shuttleShuttlecockInData.onNext(shuttlecockIn.timetable.order)
            ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.onNext(shuttlecockIn.timetable.destination.first(where: { $0.destination == "CAMPUS" })?.entries.filter({ $0.time > currentTime }) ?? [])
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
        let dataDelegate = ShuttleRealtimeData.shared
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
            let response = try? await Network.shared.client.fetch(query: ShuttleRealtimePageQuery(language: noticeLanguage, after: GraphQLNullable(stringLiteral: timeFormatter.string(from: now))))
            if let data = response?.data {
                dataDelegate.notices.onNext(data.notices.flatMap { $0.notices })
                dataDelegate.arrival.onNext(data.shuttle.stops)
            }
        }
    }
    
    private func moveToEntireTimetable(_ stop: ShuttleStopEnum, _ section: Int) {
        guard let nc = self.navigationController as? ShuttleNC else { return }
        nc.moveToTimetableVC(stop: stop, section: section)
    }
    
    private func openShuttleViaVCByOrder(_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func openShuttleViaVCByDestination(_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    private func openShuttleStopVC(_ stop: ShuttleStopEnum) {
        let vc = ShuttleStopInfoVC(stop: stop)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
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
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            self.showToastMessage(image: UIImage(systemName: "exclamationmark.triangle.fill"), message: String(localized: "toast.error.shuttle.realtime.location"))
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
            guard let nc = self.navigationController as? ShuttleNC else { return }
            nc.openBirthdayDialog()
        }
    }
        
    @objc private func openHelpVC() {
        let vc = ShuttleHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func onClickDepartureSwitch(sender: UISwitch) {
        ShuttleRealtimeData.shared.showRemainingTime.onNext(!sender.isOn)
        UserDefaults.standard.set(!sender.isOn, forKey: "showRemainingTime")
    }
    
    @objc private func onClickShowArrivalByTimeSwitch(sender: UISwitch) {
        ShuttleRealtimeData.shared.showArrivalByTime.onNext(sender.isOn)
        UserDefaults.standard.set(sender.isOn, forKey: "showArrivalByTime")
    }
}

extension ShuttleRealtimeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        var distances = [CLLocationDistance]()
        for location in stopLocation {
            distances.append(currentLocation.distance(from: location))
        }
        let position = distances.firstIndex(of: distances.min()!)
        self.showToastMessage(
            image: UIImage(systemName: "checkmark.circle.fill"),
            message: String(localized: "toast.success.shuttle.realtime.location.\(self.viewPager.tabView.tabs[position!].title)" )
        )
        self.viewPager.tabView.moveToTab(index: position!)
        self.viewPager.contentView.moveToPage(index: position!)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        self.showToastMessage(image: UIImage(systemName: "exclamationmark.triangle.fill"), message: String(localized: "toast.error.shuttle.realtime.location"))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserDeviceLocationServiceAuthorization()
    }
}
