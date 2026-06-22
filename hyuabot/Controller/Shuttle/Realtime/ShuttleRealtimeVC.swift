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
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.6
        $0.lineBreakMode = .byTruncatingTail
    }
    private let shuttleShowDepartureTimeLabel = UILabel().then {
        $0.text = String(localized: "shuttle.realtime.showDepartureTime")
        $0.textColor = .white
        $0.font = .godo(size: 14, weight: .bold)
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.6
        $0.lineBreakMode = .byTruncatingTail
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
    private lazy var helpButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .hanyangGreen
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "questionmark.circle")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        $0.configuration = config
        $0.addTarget(self, action: #selector(openHelpVC), for: .touchUpInside)
    }

    private var isShowingCoachMarks = false
    private var pendingGPSTabIndex: Int?
    private let widgetCoachMarkAnchor = UIView().then { $0.isUserInteractionEnabled = false }
    private var subscription: Disposable?
    private lazy var viewPager: ViewPager = {
        let viewPager = ViewPager(sizeConfiguration: .fixed(width: 125, height: 60, spacing: 0), optionView: self.shuttleOptionView, noticeView: self.noticeView)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.logScreenView(.shuttleRealtime)
        self.showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("shuttle.realtime") else { return }

        isShowingCoachMarks = true
        dormitoryOutTabVC.forceShowBusAlternative = true
        dormitoryOutTabVC.reloadSection0()
        viewPager.tabView.moveToTab(index: 0)
        viewPager.contentView.moveToPage(index: 0)

        var items: [CoachMarkItem] = [
            CoachMarkItem(
                id: "shuttle.tabs",
                targetView: viewPager.tabView,
                title: String(localized: "coach.shuttle.tabs.title"),
                message: String(localized: "coach.shuttle.tabs.message")
            ),
            CoachMarkItem(
                id: "shuttle.byDestination",
                targetView: shuttleShowByDestination,
                title: String(localized: "coach.shuttle.byDestination.title"),
                message: String(localized: "coach.shuttle.byDestination.message")
            ),
            CoachMarkItem(
                id: "shuttle.departureTime",
                targetView: shuttleShowDepartureTime,
                title: String(localized: "coach.shuttle.departureTime.title"),
                message: String(localized: "coach.shuttle.departureTime.message")
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
                    self.dormitoryOutTabVC.reloadSection0()
                    self.dormitoryOutTabVC.scrollToTop()
                    return self.dormitoryOutTabVC.busAlternativeView
                },
                title: String(localized: "coach.shuttle.busAlternative.title"),
                message: String(localized: "coach.shuttle.busAlternative.message")
            ),
        ]

        if let transferView = dormitoryOutTabVC.transferInfoView {
            items.append(CoachMarkItem(
                id: "shuttle.transfer",
                targetView: transferView,
                title: String(localized: "coach.shuttle.transfer.title"),
                message: String(localized: "coach.shuttle.transfer.message")
            ))
        }

        items.append(CoachMarkItem(
            id: "shuttle.widget",
            targetView: widgetCoachMarkAnchor,
            title: String(localized: "coach.shuttle.widget.title"),
            message: String(localized: "coach.shuttle.widget.message")
        ))

        if !noticeView.isHidden {
            items.append(CoachMarkItem(
                id: "shuttle.notice",
                targetView: noticeView,
                title: String(localized: "coach.shuttle.notice.title"),
                message: String(localized: "coach.shuttle.notice.message")
            ))
        }

        presentCoachMarks(
            pageId: "shuttle.realtime",
            items: items,
            shouldMarkAsShown: false,
            onSkip: { [weak self] in self?.finishCoachMarks() },
            onComplete: { [weak self] in self?.showFooterCoachMarksWhenReady() }
        )
    }

    private func showFooterCoachMarksWhenReady() {
        dormitoryOutTabVC.forceShowBusAlternative = false
        dormitoryOutTabVC.reloadSection0()
        let scroll: () -> Void = { [weak self] in
            guard let self else { return }
            self.dormitoryOutTabVC.scrollToFooter()
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
        let items: [CoachMarkItem] = [
            CoachMarkItem(
                id: "shuttle.footer.timetable",
                targetViewProvider: { [weak self] in self?.dormitoryOutTabVC.lastSectionFooterTimetableButton },
                title: String(localized: "coach.shuttle.footer.timetable.title"),
                message: String(localized: "coach.shuttle.footer.timetable.message")
            ),
            CoachMarkItem(
                id: "shuttle.footer.stopModal",
                targetView: dormitoryOutTabVC.tableFooterView1.showStopModalButton,
                title: String(localized: "coach.shuttle.footer.title"),
                message: String(localized: "coach.shuttle.footer.message")
            ),
        ]
        let validItems = items.filter { item in
            guard let v = item.targetView else { return true }
            return v.window != nil && !v.isHidden
        }
        guard !validItems.isEmpty,
              let window = view.window,
              !window.subviews.contains(where: { $0 is CoachMarkView }) else {
            finishCoachMarks()
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
        if let pendingIndex = pendingGPSTabIndex {
            pendingGPSTabIndex = nil
            viewPager.tabView.moveToTab(index: pendingIndex)
            viewPager.contentView.moveToPage(index: pendingIndex)
            showToastMessage(
                image: UIImage(systemName: "checkmark.circle.fill"),
                message: String(
                    format: String(localized: "toast.success.shuttle.realtime.location.%@"),
                    viewPager.tabView.tabs[pendingIndex].title
                )
            )
        }
    }

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
        self.noticeView.resumeAutoScroll()
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
            make.trailing.lessThanOrEqualTo(self.shuttleShowByDestination.snp.leading).offset(-6)
        }
        self.shuttleShowDepartureTimeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.shuttleOptionView.snp.centerY)
            make.leading.equalTo(self.shuttleOptionView.snp.centerX).offset(10)
            make.trailing.lessThanOrEqualTo(self.shuttleShowDepartureTime.snp.leading).offset(-6)
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
        self.viewPager.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        self.view.addSubview(widgetCoachMarkAnchor)
        widgetCoachMarkAnchor.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        ShuttleRealtimeData.shared.notices.subscribe(onNext: { notices in
            if notices.isEmpty {
                self.noticeView.isHidden = true
                self.noticeView.stopAutoScroll()
            } else {
                self.noticeView.isHidden = false
                self.noticeView.setupUI(with: notices.map { Notice(title: $0.title, url: $0.url) })
            }
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
            let response = try? await Network.shared.client.fetch(query: ShuttleRealtimePageQuery(language: noticeLanguage, after: GraphQLNullable(stringLiteral: timeFormatter.string(from: now))), cachePolicy: .networkOnly)
            if let data = response?.data {
                dataDelegate.notices.onNext(data.notices.flatMap { $0.notices })
                dataDelegate.arrival.onNext(data.shuttle.stops)
            }
        }
        Task {
            let busResponse = try? await Network.shared.client.fetch(query: ShuttleBusAlternativeQuery(), cachePolicy: .networkOnly)
            if let busData = busResponse?.data {
                dataDelegate.busAlternatives.onNext(Self.buildBusAlternatives(busData.bus))
            }
        }
    }

    private static func buildBusAlternatives(_ busList: [ShuttleBusAlternativeQuery.Data.Bus]) -> [String: [ShuttleBusAlternativeDisplayData]] {
        func item(routeSeq: Int, stopSeq: Int) -> ShuttleBusAlternativeQuery.Data.Bus? {
            busList.first { $0.route.seq == routeSeq && $0.stop.seq == stopSeq }
        }

        func display(_ bus: ShuttleBusAlternativeQuery.Data.Bus?, routeName: String, color: UIColor) -> ShuttleBusAlternativeDisplayData? {
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

        func bestRoute(_ options: [(bus: ShuttleBusAlternativeQuery.Data.Bus?, routeName: String, color: UIColor)]) -> ShuttleBusAlternativeDisplayData? {
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
        let route80A = String(localized: "shuttle.bus.alternative.route.80a")
        let routeN80A = String(localized: "shuttle.bus.alternative.route.n80a")
        let route80B = String(localized: "shuttle.bus.alternative.route.80b")
        let routeN80B = String(localized: "shuttle.bus.alternative.route.n80b")

        let dormitory10 = display(item(routeSeq: 216000068, stopSeq: 216000383), routeName: route10ToSangnoksu, color: green)
        let shuttlecock10 = display(item(routeSeq: 216000068, stopSeq: 216000379), routeName: route10ToSangnoksu, color: green)
        let station10 = display(item(routeSeq: 216000068, stopSeq: 216000138), routeName: route10FromSangnoksu, color: green)
        let dormitory80 = bestRoute([
            (item(routeSeq: 216000081, stopSeq: 216000028), route80A, blue),
            (item(routeSeq: 216000101, stopSeq: 216000028), routeN80A, blue)
        ])
        let shuttlecock62 = display(item(routeSeq: 216000016, stopSeq: 216000152), routeName: route62Terminal, color: green)
        let terminal80 = bestRoute([
            (item(routeSeq: 216000082, stopSeq: 216000077), route80B, blue),
            (item(routeSeq: 216000102, stopSeq: 216000077), routeN80B, blue)
        ])
        let terminal62 = display(item(routeSeq: 216000016, stopSeq: 216000074), routeName: route62Dormitory, color: green)
        let jungang80 = bestRoute([
            (item(routeSeq: 216000082, stopSeq: 217000140), route80B, blue),
            (item(routeSeq: 216000102, stopSeq: 217000140), routeN80B, blue)
        ])
        let jungang62 = display(item(routeSeq: 216000016, stopSeq: 217000264), routeName: route62Dormitory, color: green)

        return [
            "dormitory_station": [dormitory10].compactMap { $0 },
            "dormitory_terminal": [dormitory80].compactMap { $0 },
            "dormitory_jungang": [dormitory80].compactMap { $0 },
            "shuttlecock_station": [shuttlecock10].compactMap { $0 },
            "shuttlecock_terminal": [shuttlecock62].compactMap { $0 },
            "shuttlecock_jungang": [shuttlecock62].compactMap { $0 },
            "station_dormitory": [station10].compactMap { $0 },
            "terminal_dormitory": [terminal80, terminal62].compactMap { $0 },
            "jungang_dormitory": [jungang80, jungang62].compactMap { $0 }
        ]
    }
    
    private func moveToEntireTimetable(_ stop: ShuttleStopEnum, _ section: Int) {
        guard let nc = self.navigationController as? ShuttleNC else { return }
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
        self.present(vc, animated: true, completion: nil)
    }
    
    private func openShuttleViaVCByDestination(_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        let vc = ShuttleViaVC(item: item)
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                min(vc.sheetHeight, context.maximumDetentValue)
            })]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
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
        self.present(vc, animated: true, completion: nil)
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
            self.present(activityVC, animated: true)
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
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
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
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }

    private func shuttleStopPoint(_ stop: ShuttleStopEnum) -> (name: String, latitude: Double, longitude: Double)? {
        let name = String(localized: String.LocalizationValue(shuttleStopLocalizationKey(stop)))
        if let stops = try? ShuttleRealtimeData.shared.arrival.value(),
           let shuttleStop = stops.first(where: { $0.name == shuttleStopAPIName(stop) }) {
            return (name, shuttleStop.latitude, shuttleStop.longitude)
        }

        guard let fallbackIndex = shuttleStopFallbackIndex(stop), stopLocation.indices.contains(fallbackIndex) else {
            return nil
        }
        let fallback = stopLocation[fallbackIndex]
        return (name, fallback.coordinate.latitude, fallback.coordinate.longitude)
    }

    private func shuttleStopAPIName(_ stop: ShuttleStopEnum) -> String {
        switch stop {
        case .dormiotryOut:
            return "dormitory_o"
        case .shuttlecockOut:
            return "shuttlecock_o"
        case .station:
            return "station"
        case .terminal:
            return "terminal"
        case .jungangStation:
            return "jungang_stn"
        case .shuttlecockIn:
            return "shuttlecock_i"
        }
    }

    private func shuttleStopLocalizationKey(_ stop: ShuttleStopEnum) -> String {
        switch stop {
        case .dormiotryOut:
            return "shuttle.stop.dormitory.out"
        case .shuttlecockOut:
            return "shuttle.stop.shuttlecock.out"
        case .station:
            return "shuttle.stop.station"
        case .terminal:
            return "shuttle.stop.terminal"
        case .jungangStation:
            return "shuttle.stop.jungang.station"
        case .shuttlecockIn:
            return "shuttle.stop.shuttlecock.in"
        }
    }

    private func shuttleStopFallbackIndex(_ stop: ShuttleStopEnum) -> Int? {
        switch stop {
        case .dormiotryOut:
            return 0
        case .shuttlecockOut:
            return 1
        case .station:
            return 2
        case .terminal:
            return 3
        case .jungangStation:
            return 4
        case .shuttlecockIn:
            return 5
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
        AnalyticsManager.logSelect(.shuttleOpenHelp)
        let vc = ShuttleHelpVC()
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func onClickDepartureSwitch(sender: UISwitch) {
        AnalyticsManager.logSelect(.shuttleDepartureSwitch, type: .toggle)
        ShuttleRealtimeData.shared.showRemainingTime.onNext(!sender.isOn)
        UserDefaults.standard.set(!sender.isOn, forKey: "showRemainingTime")
    }
    
    @objc private func onClickShowArrivalByTimeSwitch(sender: UISwitch) {
        AnalyticsManager.logSelect(.shuttleArrivalByTimeSwitch, type: .toggle)
        ShuttleRealtimeData.shared.showArrivalByTime.onNext(sender.isOn)
        UserDefaults.standard.set(sender.isOn, forKey: "showArrivalByTime")
    }
}

extension ShuttleRealtimeVC {
    func scrollToStop(_ stopID: String) {
        let index: Int
        switch stopID {
        case "dormitory_o":  index = 0
        case "shuttlecock_o": index = 1
        case "station":      index = 2
        case "terminal":     index = 3
        case "jungang_stn":  index = 4
        case "shuttlecock_i": index = 5
        default: return
        }
        viewPager.tabView.moveToTab(index: index)
        viewPager.contentView.moveToPage(index: index)
    }
}

extension ShuttleRealtimeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        var distances = [CLLocationDistance]()
        for location in stopLocation {
            distances.append(currentLocation.distance(from: location))
        }
        let position = distances.firstIndex(of: distances.min()!)!
        if isShowingCoachMarks {
            pendingGPSTabIndex = position
            locationManager.stopUpdatingLocation()
            return
        }
        self.showToastMessage(
            image: UIImage(systemName: "checkmark.circle.fill"),
            message: String(
                format: String(localized: "toast.success.shuttle.realtime.location.%@"),
                self.viewPager.tabView.tabs[position].title
            )
        )
        self.viewPager.tabView.moveToTab(index: position)
        self.viewPager.contentView.moveToPage(index: position)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        self.showToastMessage(image: UIImage(systemName: "exclamationmark.triangle.fill"), message: String(localized: "toast.error.shuttle.realtime.location"))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkUserDeviceLocationServiceAuthorization()
    }
}
