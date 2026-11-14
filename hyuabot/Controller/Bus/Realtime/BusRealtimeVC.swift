//
//  BusRealtimeVC.swift
//  hyuabot
//

import Api
import CoreLocation
import RxSwift
import UIKit

private struct BusStopCoordinate {
    let seq: Int32
    let latitude: Double
    let longitude: Double
}

// swiftlint:disable:next type_body_length
class BusRealtimeVC: UIViewController, @preconcurrency CLLocationManagerDelegate {
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastNearestSelectionLocation: CLLocation?
    private let nearestStopReselectDistance: CLLocationDistance = 75
    private var lastAppliedRequestGeneration = 0
    private var hasLoadedInitialNotices = false
    private var isFetchingCoordinates = false
    private var latestRequestGeneration = 0
    private var lastAppliedBusInput: [BusRouteStopInput]?
    private var lastAppliedNoticeLanguage: String?
    /// False once the backend rejected logLimit/logAfter as unknown input fields; never reset for this controller.
    private var serverSupportsLogWindow = true
    private var selectedTab: BusRealtimeType = .city
    private let contentView = BusRealtimeContentView()
    private var subscription: Disposable?
    private var noticeView: NoticeCarouselView { contentView.noticeBar.carousel }

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
                targetView: contentView.segmentView,
                title: String(localized: "coach.bus.tabs.title"),
                message: String(localized: "coach.bus.tabs.message")
            )
        ]
        if !contentView.noticeBar.isHidden {
            items.append(CoachMarkItem(
                id: "bus.notice",
                targetView: contentView.noticeBar,
                title: String(localized: "coach.bus.notice.title"),
                message: String(localized: "coach.bus.notice.message")
            ))
        }
        items.append(CoachMarkItem(
            id: "bus.header.location",
            targetViewProvider: { [weak self] in self?.contentView.firstCard?.stopInfoButton },
            title: String(localized: "coach.bus.header.location.title"),
            message: String(localized: "coach.bus.header.location.message")
        ))
        items.append(CoachMarkItem(
            id: "bus.footer.timetable",
            targetViewProvider: { [weak self] in self?.contentView.firstCard?.timetableButton },
            title: String(localized: "coach.bus.footer.timetable.title"),
            message: String(localized: "coach.bus.footer.timetable.message")
        ))
        items.append(CoachMarkItem(
            id: "bus.footer.log",
            targetViewProvider: { [weak self] in self?.contentView.firstCard?.logButton },
            title: String(localized: "coach.bus.footer.log.title"),
            message: String(localized: "coach.bus.footer.log.message")
        ))
        presentCoachMarks(pageId: "bus.realtime", items: items)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
        BusRealtimeData.shared.isLoading.distinctUntilChanged().observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.render() })
            .disposed(by: disposeBag)
        render()
        navigationItem.backButtonTitle = String(localized: "tabbar.bus")
        // Pushed screens (e.g. the timetable) show only the back chevron.
        navigationItem.backButtonDisplayMode = .minimal
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()

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
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        locationManager.stopUpdatingLocation()
        stopPolling()

    }

    private func setupUI() {
        view.backgroundColor = SettingsStyle.Color.background
        view.addSubview(contentView)
        contentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.onSelectTab = { [weak self] in self?.selectedTab = $0; self?.render() }
        contentView.onRefresh = { [weak self] in
            AnalyticsManager.logSelect(.busRefresh)
            self?.fetchBusRealtimeData()
        }
        contentView.onSettingsTap = { [weak self] in self?.openQuickSettings() }
        contentView.onStopInfoTap = { [weak self] in self?.openBusStopVC($0.stopID, $0.routes) }
        contentView.onLogTap = { [weak self] in self?.openDepartureLogSheet($0.stopID, $0.routes) }
        contentView.onTimetableTap = { [weak self] spec in
            self?.moveToEntireTimetable(spec)
        }
        contentView.noticeBar.carousel.onNoticeTapped = { [weak self] url in
            guard let url = URL(string: url) else { return }
            let vc = BusNoticeVC(url: url)
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
            self?.present(vc, animated: true)
        }
    }

    private func render() {
        let isLoading = (try? BusRealtimeData.shared.isLoading.value()) ?? false
        let specs = BusRealtimeSections.specs(for: selectedTab)
        let showSecondary = BusRealtimeDisplaySettings.showsSecondaryEta
        let contents = specs.enumerated().map { index, spec in
            BusSectionContent(
                routeNames: spec.routeNames,
                stopName: spec.stopName,
                rows: isLoading ? [] : Array(((try? BusRealtimeSections.subject(for: selectedTab, index: index)?.value()) ?? [])
                    .compactMap { $0.rowModel(showSecondary: showSecondary) }
                    .prefix(BusRealtimeSections.rowLimit(for: selectedTab))),
                isLoading: isLoading
            )
        }
        contentView.render(tab: selectedTab, specs: specs, contents: contents)

    }

    private func selectNearestBusStop() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        } else if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
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
        guard let location = lastLocation else { return }
        guard let allBuses = try? BusRealtimeData.shared.busStopCoordinatesData.value(), !allBuses.isEmpty else { return }
        let movedDistance = lastNearestSelectionLocation.map { location.distance(from: $0) } ?? .infinity
        if movedDistance < nearestStopReselectDistance { return }
        lastNearestSelectionLocation = location

        func coordinate(_ seq: Int32) -> (lat: Double, lng: Double)? {
            if let match = allBuses.first(where: { $0.stop.seq == seq }) {
                return (match.stop.latitude, match.stop.longitude)
            }
            return BusStopFallbackCoordinate.coordinate(for: seq)
        }

        func nearest(_ candidates: [Int32]) -> Int32? {
            let withCoords = candidates.compactMap { seq -> BusStopCoordinate? in
                guard let coord = coordinate(seq) else { return nil }
                return BusStopCoordinate(seq: seq, latitude: coord.lat, longitude: coord.lng)
            }
            return withCoords.min {
                let d1 = pow(location.coordinate.latitude - $0.latitude, 2) + pow(location.coordinate.longitude - $0.longitude, 2)
                let d2 = pow(location.coordinate.latitude - $1.latitude, 2) + pow(location.coordinate.longitude - $1.longitude, 2)
                return d1 < d2
            }?.seq
        }

        let campusStops: [Int32] = [216_000_379, 216_000_381, 216_000_383]
        let seoulRemoteStops: [Int32] = [121_000_060, 121_000_929, 121_000_974, 121_000_970, 121_000_220]

        var selectionChanged = false
        func emitIfChanged(_ subject: BehaviorSubject<Int32>, defaultsKey: String, value: Int32) {
            guard (try? subject.value()) != value else { return }
            selectionChanged = true
            UserDefaults.standard.set(value, forKey: defaultsKey)
            subject.onNext(value)
        }

        guard let cityStop = nearest(campusStops) else { return }
        emitIfChanged(BusRealtimeData.shared.selectedBusStopID, defaultsKey: "busStopID", value: cityStop)

        if let seoulFirst = nearest(campusStops + seoulRemoteStops) {
            emitIfChanged(BusRealtimeData.shared.seoulFirstSelectedStopID, defaultsKey: "bus.seoulFirstStopID", value: seoulFirst)
        }
        if let seoulSecond = nearest([216_000_719] + seoulRemoteStops) {
            emitIfChanged(BusRealtimeData.shared.seoulSecondSelectedStopID, defaultsKey: "bus.seoulSecondStopID", value: seoulSecond)
        }
        if let suwon = nearest([216_000_070, 202_000_106]) {
            emitIfChanged(BusRealtimeData.shared.suwonSelectedStopID, defaultsKey: "bus.suwonStopID", value: suwon)
        }
        if selectionChanged { fetchBusRealtimeData() }
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

            let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216_000_379 : UserDefaults.standard
                .integer(forKey: "busStopID"))
            // City bus (10-1) — always update regardless of Seoul bus availability
            let cityFromCampus = result.first(where: { $0.stop.seq == selectedStopID && $0.route.seq == 216_000_068 })
            BusRealtimeData.shared.busRealtimeCityFromCampus.onNext(
                cityFromCampus.map { arrivalItems(for: $0, destinationStop: 216_000_138, showSecondary: showSecondary) } ?? []
            )
            let cityFromStation = result.first(where: { $0.stop.seq == 216_000_138 && $0.route.seq == 216_000_068 })
            BusRealtimeData.shared.busRealtimeCityFromStation.onNext(
                cityFromStation.map { arrivalItems(for: $0, destinationStop: 216_000_378, showSecondary: showSecondary) } ?? []
            )
            // Seoul bus section 1 (3102) — primary stop widened to campus or one of 5 Seoul-bound stops
            let seoulFirstStopID = (try? BusRealtimeData.shared.seoulFirstSelectedStopID.value()) ?? 216_000_379
            let seoulFirstSecondaryStop: Int32 = seoulRemoteStops.contains(seoulFirstStopID) ? 216_000_378 : seoulTarget.stopID
            let seoulFromCampus = result.first(where: { $0.stop.seq == seoulFirstStopID && $0.route.seq == 216_000_061 })
            BusRealtimeData.shared.busRealtimeSeoulFromCampus.onNext(
                seoulFromCampus.map {
                    arrivalItems(for: $0, destinationStop: seoulFirstSecondaryStop, showSecondary: showSecondary)
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
                    BusArrivalDeduplication.uniqueItems(gunpoFromCampus.flatMap { route in
                        arrivalItems(for: route, destinationStop: seoulSecondSecondaryStop, showSecondary: showSecondary)
                    }).sorted().prefix(4)
                )
            )
            // Suwon bus (7070/9090) — primary stop widened to campus entrance or Suwon station
            let suwonStopID = (try? BusRealtimeData.shared.suwonSelectedStopID.value()) ?? 216_000_070
            let suwonSecondaryStop: Int32 = suwonStopID == 202_000_106 ? 216_000_141 : 202_000_208
            let suwonFromCampus = result
                .filter { $0.stop.seq == suwonStopID && ($0.route.seq == 216_000_104 || $0.route.seq == 200_000_015) }
            BusRealtimeData.shared.busRealtimeSuwonFromCampus.onNext(
                BusArrivalDeduplication.uniqueItems(suwonFromCampus.flatMap { route in
                    arrivalItems(for: route, destinationStop: suwonSecondaryStop, showSecondary: showSecondary)
                }).sorted()
            )
            let ktxFromCampus = result.first(where: { $0.stop.seq == 216_000_759 && $0.route.seq == 216_000_075 })
            BusRealtimeData.shared.busRealtimeKTXFromCampus.onNext(
                ktxFromCampus.map { arrivalItems(for: $0, destinationStop: 213_000_487, showSecondary: showSecondary) } ?? []
            )
            let ktxFromStation = result.first(where: { $0.stop.seq == 213_000_487 && $0.route.seq == 216_000_075 })
            BusRealtimeData.shared.busRealtimeKTXFromStation.onNext(
                ktxFromStation.map { arrivalItems(for: $0, destinationStop: 216_000_117, showSecondary: showSecondary) } ?? []
            )
            render()
            // Set the loading state to false
            BusRealtimeData.shared.isLoading.onNext(false)
            render()
            contentView.endRefreshing()
        }).disposed(by: disposeBag)
        BusRealtimeData.shared.notices.subscribe(onNext: { [weak self] notices in
            guard let self else { return }
            let isLoading = !self.hasLoadedInitialNotices && notices.isEmpty
            self.contentView.noticeBar.isHidden = notices.isEmpty && !isLoading
            if isLoading {
                self.contentView.noticeBar.carousel.setLoading(true)
            } else {
                self.contentView.noticeBar.carousel.setupUI(with: notices.map { Notice(title: $0.title, url: $0.url) })
            }
        }).disposed(by: disposeBag)
    }

    private func estimatedArrivalTime(for arrival: BusRealtimePageQuery.Data.Bus.Arrival) -> Api.LocalTime? {
        if let arrivalTime = arrival.arrivalTime { return arrivalTime }
        guard arrival.isRealtime, let minutes = arrival.minutes else { return nil }
        return Date.now.addingTimeInterval(Double(minutes) * 60).toLocalTimeString()
    }

    private func secondaryArrivalTime(
        primaryArrivalTime: Api.LocalTime?,
        arrival: BusRealtimePageQuery.Data.Bus.Arrival?,
        destinationStop: Int32,
        showSecondary: Bool
    ) -> Api.LocalTime? {
        guard showSecondary,
              let primaryArrivalTime,
              let primaryDate = primaryArrivalTime.toLocalTimeOrNil(),
              let arrival,
              let minutes = arrival.destinationTravelMinutes.first(where: {
                  $0.destinationStopId == destinationStop
              })?.minutes
        else { return nil }
        return primaryDate.addingTimeInterval(Double(minutes) * 60).toLocalTimeString()
    }

    private struct FutureLogCandidate {
        let log: BusRealtimePageQuery.Data.Bus.Log
        let time: Foundation.Date
        let serviceDate: Foundation.Date
    }

    // swiftlint:disable:next function_body_length
    private func arrivalItems(
        for bus: BusRealtimePageQuery.Data.Bus,
        destinationStop: Int32,
        showSecondary: Bool
    ) -> [BusArrivalItem] {
        let now = Foundation.Date.now
        // Scheduled arrivals can carry an arrivalTime while marked non-realtime.
        // Keep them so the next scheduled bus is shown instead of a much later log.
        let liveArrivals = bus.arrival
        let liveItems = liveArrivals.map { arrival in
            BusArrivalItem(
                route: bus.route.name,
                item: arrival,
                secondaryArrivalTime: secondaryArrivalTime(
                    primaryArrivalTime: estimatedArrivalTime(for: arrival),
                    arrival: arrival,
                    destinationStop: destinationStop,
                    showSecondary: showSecondary
                ),
                destinationStopID: destinationStop
            )
        }
        // Parse each log time once and reuse it for both dispatch-interval detection and
        // the future-log candidate list below.
        let parsedLogs: [(BusRealtimePageQuery.Data.Bus.Log, Foundation.Date)] = bus.log.compactMap { log in
            guard let time = log.time.toLocalTimeOrNil() else { return nil }
            return (log, time)
        }
        let logTimesByDate = Dictionary(grouping: parsedLogs, by: { $0.0.date })
        let logDerivedDispatchMinutes = logTimesByDate.values
            .map { entries in
                let times = BusLogMerging.merged(entries.map(\.1), time: { $0 })
                return zip(times, times.dropFirst())
                    .map { current, next in next.timeIntervalSince(current) }
                    .filter { $0 > 0 }
                    .min()
            }
            .compactMap { $0 }
            .min()
            .map { Int($0 / 60) }
        let currentWeekday = switch Calendar.current.component(.weekday, from: now) {
        case 1: "sunday"
        case 7: "saturday"
        default: "weekdays"
        }
        let dispatchMinutes = bus.minimumDispatchIntervals
            .first(where: { $0.weekday == currentWeekday })?.minutes
            ?? logDerivedDispatchMinutes
            ?? 0
        let lastLiveArrivalDate = liveArrivals.compactMap { arrival -> Foundation.Date? in
            estimatedArrivalTime(for: arrival)?.toLocalTimeOrNil()
        }.max()
        var seenLogTimes = Set(liveArrivals.compactMap { estimatedArrivalTime(for: $0)?.toLocalTimeOrNil() })
        let futureLogCandidates: [FutureLogCandidate] = parsedLogs
            .compactMap { log, time in
                guard let serviceDate = self.serviceDate(for: time, now: now), serviceDate > now else { return nil }
                return FutureLogCandidate(log: log, time: time, serviceDate: serviceDate)
            }
        let selectedLogs = BusLogMerging.realtimeTabLogs(
            candidates: futureLogCandidates,
            serviceDate: { $0.serviceDate },
            dispatchMinutes: dispatchMinutes,
            lastLiveArrival: lastLiveArrivalDate,
            now: now
        )
        let logItems = selectedLogs.compactMap { candidate -> (BusArrivalItem, Foundation.Date)? in
            let log = candidate.log
            let time = candidate.time
            let serviceDate = candidate.serviceDate
            guard seenLogTimes.insert(time).inserted else { return nil }
            // A historical log is valid even when realtime has no row with the same
            // clock value. Reuse an arrival only as a rendering template; scheduledTime
            // remains the source of truth for this row's ETA.
            guard let arrival = bus.arrival.first(where: {
                $0.time?.toLocalTimeOrNil() == time || $0.arrivalTime?.toLocalTimeOrNil() == time
            }) ?? bus.arrival.first(where: {
                $0.destinationTravelMinutes.contains { $0.destinationStopId == destinationStop }
            }) ?? bus.arrival.first else { return nil }
            let item = BusArrivalItem(
                route: bus.route.name,
                item: arrival,
                secondaryArrivalTime: secondaryArrivalTime(
                    primaryArrivalTime: log.time,
                    arrival: arrival,
                    destinationStop: destinationStop,
                    showSecondary: showSecondary
                ),
                scheduledTime: log.time,
                destinationStopID: destinationStop
            )
            return (item, serviceDate)
        }
        // Realtime entries are ordered by their remaining minutes. Log entries are
        // selected by BusLogMerging.realtimeTabLogs (at least max(dispatch interval, 15 min)
        // apart from the preceding live/log entry).
        return BusArrivalDeduplication.uniqueItems(liveItems.sorted() + logItems.sorted { $0.1 < $1.1 }.map(\.0))
    }

    private func busRealtimeInput(dates: [Api.Date]) -> [BusRouteStopInput] {
        let seoulRemoteStops: [Int32] = [121_000_060, 121_000_929, 121_000_974, 121_000_970, 121_000_220]
        let showSecondary = (try? BusRealtimeData.shared.showSecondaryEta.value()) ?? true
        let seoulTarget = (try? BusRealtimeData.shared.seoulTargetStop.value()) ?? .gangnam
        let selectedCityStop = (try? BusRealtimeData.shared.selectedBusStopID.value()) ?? 216_000_379
        let seoulFirstStop = (try? BusRealtimeData.shared.seoulFirstSelectedStopID.value()) ?? 216_000_379
        let seoulSecondStop = (try? BusRealtimeData.shared.seoulSecondSelectedStopID.value()) ?? 216_000_719
        let suwonStop = (try? BusRealtimeData.shared.suwonSelectedStopID.value()) ?? 216_000_070

        func input(_ route: Int32, _ stop: Int32, _ destinations: [Int32] = []) -> BusRouteStopInput {
            BusRouteStopInput(
                route: route,
                stop: stop,
                destinationStops: showSecondary && !destinations.isEmpty ? .some(destinations) : .none,
                limit: .some(3),
                dates: .some(dates)
            )
        }

        // Request only the stops used by the current selections. The log field is still
        // requested for the selected stops because it is used as the fallback ETA source.
        var inputs: [BusRouteStopInput] = [
            input(216_000_068, selectedCityStop, [216_000_138]),
            input(216_000_068, 216_000_138, [216_000_378]),
            input(
                216_000_061,
                seoulFirstStop,
                [seoulRemoteStops.contains(seoulFirstStop) ? 216_000_378 : seoulTarget.stopID]
            ),
            input(
                216_000_104,
                suwonStop,
                [suwonStop == 202_000_106 ? 216_000_141 : 202_000_208]
            ),
            input(
                200_000_015,
                suwonStop,
                [suwonStop == 202_000_106 ? 216_000_141 : 202_000_208]
            ),
            input(216_000_075, 216_000_759, [213_000_487]),
            input(216_000_075, 213_000_487, [216_000_117])
        ]

        // The second Seoul section contains three routes but shares one selected stop.
        inputs += [216_000_043, 216_000_026, 216_000_096].map {
            input(
                $0,
                seoulSecondStop,
                [seoulRemoteStops.contains(seoulSecondStop) ? 216_000_048 : seoulTarget.stopID]
            )
        }
        return inputs
    }

    private func serviceDate(for time: Foundation.Date, now: Foundation.Date) -> Foundation.Date? {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let today = calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            second: 0,
            of: now
        ) ?? time
        if today > now { return today }
        guard calendar.component(.hour, from: time) < 4 else { return nil }
        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    private func fetchBusStopCoordinates() {
        guard !isFetchingCoordinates,
              ((try? BusRealtimeData.shared.busStopCoordinatesData.value()) ?? []).isEmpty else { return }
        isFetchingCoordinates = true
        Task {
            let response = try? await Network.shared.client.fetch(
                query: BusStopCoordinatesQuery(busInput: BusLocationInputs.inputs), cachePolicy: .networkOnly
            )
            await MainActor.run {
                isFetchingCoordinates = false
                guard let coordinates = response?.data?.bus, !coordinates.isEmpty else { return }
                BusRealtimeData.shared.busStopCoordinatesData.onNext(coordinates)
                attemptNearestStopSelection()
            }
        }
    }

    private func fetchBusRealtimeData() {
        fetchBusStopCoordinates()
        latestRequestGeneration += 1
        let requestGeneration = latestRequestGeneration
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
        let busInput = busRealtimeInput(dates: dates)
        if lastAppliedBusInput != busInput || lastAppliedNoticeLanguage != noticeLanguage {
            BusRealtimeData.shared.isLoading.onNext(true)
        }
        let logAfter = BusRealtimeLogRequest.logAfter(now: Foundation.Date())
        Task {
            let outcome = await BusRealtimeLogRequest.fetch(
                input: busInput,
                logAfter: logAfter,
                supportsLogWindow: serverSupportsLogWindow
            ) { input in
                await self.fetchBusRealtimePage(input: input, language: noticeLanguage)
            }
            await MainActor.run {
                if !outcome.supportsLogWindow {
                    serverSupportsLogWindow = false
                }
                // Timer ticks issue newer requests with identical inputs; keep applying a slow response unless the
                // selected stops changed or a newer response was already rendered.
                guard requestGeneration > lastAppliedRequestGeneration,
                      busInput == busRealtimeInput(dates: dates) else { return }
                if let data = outcome.data {
                    lastAppliedRequestGeneration = requestGeneration
                    lastAppliedBusInput = busInput
                    lastAppliedNoticeLanguage = noticeLanguage
                    BusRealtimeData.shared.busRealtimeData.onNext(data.bus)
                    self.hasLoadedInitialNotices = true
                    BusRealtimeData.shared.notices.onNext(data.notices.flatMap(\.notices))
                    self.render()
                    if data.bus.isEmpty {
                        BusRealtimeData.shared.isLoading.onNext(false)
                    }
                } else {
                    BusRealtimeData.shared.isLoading.onNext(false)
                }
            }
        }
    }

    private func fetchBusRealtimePage(
        input: [BusRouteStopInput], language: String
    ) async -> BusRealtimeLogRequest.Attempt<BusRealtimePageQuery.Data> {
        do {
            let response = try await Network.shared.client.fetch(
                query: BusRealtimePageQuery(language: language, busInput: input),
                cachePolicy: .networkOnly
            )
            return BusRealtimeLogRequest.Attempt(
                data: response.data,
                errorMessages: response.errors?.compactMap(\.message) ?? []
            )
        } catch {
            return BusRealtimeLogRequest.Attempt(
                data: nil,
                errorMessages: BusRealtimeLogRequest.graphQLErrorMessages(in: error)
            )
        }
    }

    private func startPolling() {
        stopPolling()
        fetchBusRealtimeData()
        subscription = Observable<Int>.interval(.seconds(15), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.fetchBusRealtimeData()
            })
    }

    private func stopPolling() {
        subscription?.dispose()
    }

    private func moveToEntireTimetable(_ spec: BusRealtimeSectionSpec) {
        guard let nc = navigationController as? BusNC else { return }
        nc.moveToTimetableVC(
            stopID: spec.stopID, routes: spec.routes, routeNames: spec.routeNames, stopName: spec.stopName
        )
    }

    private func openDepartureLogSheet(_ stopID: Int32, _ routes: [Int32]) {
        let spec = BusRealtimeSections.specs(for: selectedTab).first { $0.stopID == stopID && $0.routes == routes }
        let vc = BusLogVC(stopID: stopID, routes: routes, routeNames: spec?.routeNames ?? [], stopName: spec?.stopName ?? "")
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

    @objc
    func appDidEnterBackground() {
        stopPolling()
    }

    @objc
    func appWillEnterForeground() {
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
            self.render()
            BusRealtimeData.shared.showSecondaryEta.onNext(isOn)
            self.fetchBusRealtimeData()
            self.render()
            BusRealtimeData.shared.busRealtimeData.onNext((try? BusRealtimeData.shared.busRealtimeData.value()) ?? [])
        }
        vc.updateSeoulTarget = { target in
            BusRealtimeDisplaySettings.seoulTargetStop = target
            self.render()
            BusRealtimeData.shared.seoulTargetStop.onNext(target)
            self.fetchBusRealtimeData()
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
