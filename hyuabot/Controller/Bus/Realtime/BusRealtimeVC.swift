//
//  BusRealtimeVC.swift
//  hyuabot
//

import Api
import CoreLocation
import RxRelay
import RxSwift
import UIKit

// swiftlint:disable:next type_body_length
class BusRealtimeVC: UIViewController, @preconcurrency CLLocationManagerDelegate {
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private var lastAppliedRequestGeneration = 0
    private var hasLoadedInitialNotices = false
    private var latestRequestGeneration = 0
    private var lastAppliedBusInput: [BusRouteStopInput]?
    private var lastAppliedNoticeLanguage: String?
    /// False once the backend rejected logLimit/logAfter as unknown input fields; never reset for this controller.
    private var serverSupportsLogWindow = true
    private var selectedTab: BusRealtimeType = .city
    private var layout: BusRealtimeLayout {
        BusRealtimeLayout.layout(
            for: BusRealtimeData.shared.busLocationGroup.value,
            seoulTarget: BusRealtimeData.shared.seoulTargetStop.value
        )
    }
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
        let isLoaded = BusRealtimeData.shared.isLoading.value == false
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
        selectedTab = layout.defaultTab
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
        let isLoading = BusRealtimeData.shared.isLoading.value
        let specs = layout.sections(for: selectedTab)
        let showSecondary = BusRealtimeDisplaySettings.showsSecondaryEta
        let contents = specs.map { spec in
            BusSectionContent(
                routeNames: spec.routeNames,
                stopName: spec.stopName,
                rows: isLoading ? [] : Array((BusRealtimeData.shared.busRealtimeSectionItems.value[spec] ?? [])
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
        } else if status == .denied || status == .restricted {
            handleLocationEvent(.authorizationUnavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        } else if status == .denied || status == .restricted {
            handleLocationEvent(.authorizationUnavailable)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        handleLocationEvent(.located(BusLocationGroup.resolve(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // locationUnknown is transient (Core Location keeps trying), so keep the last group; other errors use the default layout.
        let isTransient = (error as? CLError)?.code == .locationUnknown
        handleLocationEvent(.locationFailed(isTransient: isTransient))
    }

    private func applyLocationGroup(_ group: BusLocationGroup?) {
        guard group != BusRealtimeData.shared.busLocationGroup.value else { return }
        BusRealtimeData.shared.busLocationGroup.accept(group)
        selectedTab = layout.defaultTab
        render()
        fetchBusRealtimeData()
    }

    private func handleLocationEvent(_ event: BusLocationGroupEvent) {
        applyLocationGroup(event.nextGroup(current: BusRealtimeData.shared.busLocationGroup.value))
    }

    private func observeSubjects() {
        BusRealtimeData.shared.busRealtimeData.subscribe(onNext: { [weak self] result in
            guard let self else { return }
            let isLoading = BusRealtimeData.shared.isLoading.value
            if isLoading, result.isEmpty {
                return
            }
            let showSecondary = BusRealtimeData.shared.showSecondaryEta.value
            var sectionItems: [BusRealtimeSectionSpec: [BusArrivalItem]] = [:]
            for spec in layout.allSections {
                let items = result.filter { bus in
                    bus.stop.seq == spec.stopID && spec.routes.contains(Int32(bus.route.seq))
                }.flatMap {
                    arrivalItems(for: $0, destinationStop: spec.destinationStopID, showSecondary: showSecondary)
                }
                sectionItems[spec] = spec.routes.count > 1 ? BusArrivalDeduplication.uniqueItems(items).sorted() : items
            }
            BusRealtimeData.shared.busRealtimeSectionItems.accept(sectionItems)
            render()
            // Set the loading state to false
            BusRealtimeData.shared.isLoading.accept(false)
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
        destinationStop: Int32?,
        showSecondary: Bool
    ) -> Api.LocalTime? {
        guard showSecondary,
              let destinationStop,
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
        destinationStop: Int32?,
        showSecondary: Bool
    ) -> [BusArrivalItem] {
        let now = Foundation.Date.now
        let holidays = BusHolidayCalendar.shared.holidays
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
        // Logs from another service-day type (holiday-aware) are dropped here, so both
        // dispatch-interval detection and future candidates use only comparable days.
        let parsedLogs: [(BusRealtimePageQuery.Data.Bus.Log, Foundation.Date)] = bus.log.compactMap { log in
            guard let time = log.time.toLocalTimeOrNil() else { return nil }
            guard BusRecentDates.isLogInCurrentServiceDayType(
                logDate: log.date,
                logHour: Calendar.current.component(.hour, from: time),
                now: now,
                holidays: holidays
            ) else { return nil }
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
        let dispatchMinutes = BusLogMerging.realtimeDispatchMinutes(
            intervals: bus.minimumDispatchIntervals.map { (weekday: $0.weekday, minutes: $0.minutes) },
            logDerivedMinutes: logDerivedDispatchMinutes,
            now: now,
            holidays: holidays
        )
        let lastLiveArrivalDate = liveArrivals.compactMap { arrival -> Foundation.Date? in
            estimatedArrivalTime(for: arrival)?.toLocalTimeOrNil()
        }.max()
        var seenLogTimes = Set(liveArrivals.compactMap { estimatedArrivalTime(for: $0)?.toLocalTimeOrNil() })
        let futureLogCandidates: [FutureLogCandidate] = parsedLogs
            .compactMap { log, time in
                guard let serviceDate = BusLogMerging.realtimeServiceDate(for: time, now: now) else { return nil }
                guard serviceDate > now else { return nil }
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
            }) ?? destinationStop.flatMap({ stop in
                bus.arrival.first(where: { $0.destinationTravelMinutes.contains { $0.destinationStopId == stop } })
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
        let showSecondary = BusRealtimeData.shared.showSecondaryEta.value
        var seen = Set<[Int32]>()
        var inputs: [BusRouteStopInput] = []
        // The log field is still requested for selected stops because it is used as the fallback ETA source.
        for spec in layout.allSections {
            let destinations = spec.destinationStopID.map { [$0] } ?? []
            for route in spec.routes where seen.insert([route, spec.stopID]).inserted {
                inputs.append(BusRouteStopInput(
                    route: route,
                    stop: spec.stopID,
                    destinationStops: showSecondary && !destinations.isEmpty ? .some(destinations) : .none,
                    limit: .some(3),
                    dates: .some(dates)
                ))
            }
        }
        return inputs
    }

    private func fetchBusRealtimeData() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UIDebugBusLoading") {
            BusRealtimeData.shared.isLoading.accept(true)
            return
        }
        #endif
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
        // Refresh holidays in the background; until then the empty set gives the
        // existing weekday/Saturday/Sunday classification without delaying this poll.
        BusHolidayCalendar.shared.refreshIfNeeded { [weak self] in self?.fetchBusRealtimeData() }
        let dates = BusRecentDates.logRequestDates(holidays: BusHolidayCalendar.shared.holidays)
        let busInput = busRealtimeInput(dates: dates)
        if lastAppliedBusInput != busInput || lastAppliedNoticeLanguage != noticeLanguage {
            BusRealtimeData.shared.isLoading.accept(true)
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
                    BusRealtimeData.shared.busRealtimeData.accept(data.bus)
                    self.hasLoadedInitialNotices = true
                    BusRealtimeData.shared.notices.accept(data.notices.flatMap(\.notices))
                    self.render()
                    if data.bus.isEmpty {
                        BusRealtimeData.shared.isLoading.accept(false)
                    }
                } else {
                    BusRealtimeData.shared.isLoading.accept(false)
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
        subscription = nil
    }

    private func moveToEntireTimetable(_ spec: BusRealtimeSectionSpec) {
        guard let nc = navigationController as? BusNC else { return }
        nc.moveToTimetableVC(
            stopID: spec.stopID, routes: spec.routes, routeNames: spec.routeNames, stopName: spec.stopName
        )
    }

    private func openDepartureLogSheet(_ stopID: Int32, _ routes: [Int32]) {
        let spec = layout.sections(for: selectedTab).first { $0.stopID == stopID && $0.routes == routes }
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
            BusRealtimeData.shared.showSecondaryEta.accept(isOn)
            self.fetchBusRealtimeData()
            self.render()
            BusRealtimeData.shared.busRealtimeData.accept(BusRealtimeData.shared.busRealtimeData.value)
        }
        vc.updateSeoulTarget = { target in
            BusRealtimeDisplaySettings.seoulTargetStop = target
            self.render()
            BusRealtimeData.shared.seoulTargetStop.accept(target)
            BusRealtimeData.shared.busRealtimeData.accept(BusRealtimeData.shared.busRealtimeData.value)
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
