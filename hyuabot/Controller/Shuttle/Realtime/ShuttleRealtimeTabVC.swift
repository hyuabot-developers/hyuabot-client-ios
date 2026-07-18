// swiftlint:disable file_length

import Api
import RxSwift
import SnapKit
import UIKit

// swiftlint:disable:next type_body_length
class ShuttleRealtimeTabVC: UIViewController {
    let stopID: ShuttleStopEnum
    private let disposeBag = DisposeBag()
    private let destinationRefreshControl = UIRefreshControl()
    private let timetableRefreshControl = UIRefreshControl()
    private let shuttleRealtimeSection: [String.LocalizationValue]
    private let refreshMethod: @MainActor () -> Void
    private let showEntireTimetable: @MainActor (ShuttleStopEnum, Int) -> Void
    private let showViaVCByOrder: @MainActor (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    private let showViaVCByDestination: @MainActor (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Void
    private let showStopVC: @MainActor (ShuttleStopEnum) -> Void
    private let showBusAlternativeStop: @MainActor (ShuttleStopEnum, ShuttleBusAlternativeDisplayData) -> Void
    private let showAlarmVC: @MainActor (ShuttleStopEnum, ShuttleAlarmContext) -> Void
    private let timetableDelegate: ShuttleRealtimeTimeTableDelegate
    private var headerExpandedStates: [Int: Bool] = [:]
    private(set) var transferInfoView: ShuttleTransferInfoView?
    private var transferInfoTimeView: ShuttleTransferInfoView?
    private var busAlternatives: [String: [ShuttleBusAlternativeDisplayData]] = [:]
    private var busAlternativeLastNonEmptyAt: [String: Foundation.Date] = [:]
    private let busAlternativeEmptyGraceInterval: TimeInterval = 60
    private var activeBoardingAlarmKeys: Set<String> = []
    private var showsInitialSkeleton = true
    var forceShowBusAlternative = false
    lazy var tableFooterView1 = ShuttleRealtimeTableFooterView(parentView: self.view, stopID: self.stopID, showStopModal: showStopModal)
    lazy var tableFooterView2 = ShuttleRealtimeTableFooterView2(
        parentView: self.view,
        stopID: self.stopID,
        showStopModal: showStopModal,
        showEntireTimetable: showEntireTimetable
    )
    private lazy var shuttleRealtimeTableView: UITableView = .init(frame: .zero, style: .grouped).then {
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.backgroundColor = .systemBackground
        $0.refreshControl = destinationRefreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        $0.tableFooterView = self.tableFooterView1
        $0.showsVerticalScrollIndicator = false
        // Register the view
        $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
        $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
        $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeSkeletonCellView.self, forCellReuseIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
    }

    private lazy var shuttleRealtimeTableTimeView: UITableView = .init(frame: .zero, style: .grouped).then {
        $0.delegate = self.timetableDelegate
        $0.dataSource = self.timetableDelegate
        $0.sectionHeaderTopPadding = 0
        $0.backgroundColor = .systemBackground
        $0.tableFooterView = self.tableFooterView2
        $0.refreshControl = timetableRefreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        $0.showsVerticalScrollIndicator = false
        // Register the view
        $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
        $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
        $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeSkeletonCellView.self, forCellReuseIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
    }

    required init(
        stopID: ShuttleStopEnum,
        refreshMethod: @escaping @MainActor () -> Void,
        showEntireTimetable: @escaping @MainActor (ShuttleStopEnum, Int) -> Void,
        showViaVCByOrder: @escaping @MainActor (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void,
        showViaVCByDestination: @escaping @MainActor (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Void,
        showStopVC: @escaping @MainActor (ShuttleStopEnum) -> Void,
        showBusAlternativeStop: @escaping @MainActor (ShuttleStopEnum, ShuttleBusAlternativeDisplayData) -> Void,
        showAlarmVC: @escaping @MainActor (ShuttleStopEnum, ShuttleAlarmContext) -> Void
    ) {
        self.stopID = stopID
        if self.stopID == .dormiotryOut || self.stopID == .shuttlecockOut {
            shuttleRealtimeSection = ["shuttle.desination.subway", "shuttle.desination.terminal", "shuttle.desination.jungang_station"]
        } else if self.stopID == .station {
            shuttleRealtimeSection = ["shuttle.desination.dormitory", "shuttle.desination.terminal", "shuttle.desination.jungang_station"]
        } else {
            shuttleRealtimeSection = ["shuttle.desination.dormitory"]
        }
        self.refreshMethod = refreshMethod
        self.showEntireTimetable = showEntireTimetable
        self.showViaVCByOrder = showViaVCByOrder
        self.showViaVCByDestination = showViaVCByDestination
        self.showStopVC = showStopVC
        self.showBusAlternativeStop = showBusAlternativeStop
        self.showAlarmVC = showAlarmVC
        timetableDelegate = ShuttleRealtimeTimeTableDelegate(
            showViaVC: showViaVCByOrder,
            showAlarmVC: { stopID, item in
                guard let context = Self.makeAlarmContext(stopID: stopID, item: item, directionDisplayName: nil) else { return }
                showAlarmVC(stopID, context)
            },
            stopID: self.stopID
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
        observeAlarmStateChanges()
        reloadActiveBoardingAlarmKeys()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadActiveBoardingAlarmKeys()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let transferInfoView {
            updateTableFooter(tableView: shuttleRealtimeTableView, transferView: transferInfoView, actionFooter: tableFooterView1)
        }
        if let transferInfoTimeView {
            updateTableFooter(tableView: shuttleRealtimeTableTimeView, transferView: transferInfoTimeView, actionFooter: tableFooterView2)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.addSubview(shuttleRealtimeTableView)
        view.addSubview(shuttleRealtimeTableTimeView)
        shuttleRealtimeTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        shuttleRealtimeTableTimeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        setupTransferFootersIfNeeded()
    }

    private func setupTransferFootersIfNeeded() {
        guard shouldShowTransferSection else { return }

        let transferView = ShuttleTransferInfoView(stopID: stopID)
        let transferTimeView = ShuttleTransferInfoView(stopID: stopID)
        transferInfoView = transferView
        transferInfoTimeView = transferTimeView

        transferView.onHeightChange = { [weak self, weak transferView] in
            guard let self, let transferView else { return }
            updateTableFooter(tableView: shuttleRealtimeTableView, transferView: transferView, actionFooter: tableFooterView1)
        }
        transferTimeView.onHeightChange = { [weak self, weak transferTimeView] in
            guard let self, let transferTimeView else { return }
            updateTableFooter(tableView: shuttleRealtimeTableTimeView, transferView: transferTimeView, actionFooter: tableFooterView2)
        }

        updateTableFooter(tableView: shuttleRealtimeTableView, transferView: transferView, actionFooter: tableFooterView1)
        updateTableFooter(tableView: shuttleRealtimeTableTimeView, transferView: transferTimeView, actionFooter: tableFooterView2)
    }

    private var shouldShowTransferSection: Bool {
        stopID == .dormiotryOut || stopID == .shuttlecockOut || stopID == .terminal
    }

    private func updateTableFooter(tableView: UITableView, transferView: ShuttleTransferInfoView, actionFooter: UIView) {
        let width = max(tableView.bounds.width, view.bounds.width)
        if let stopFooter = actionFooter as? ShuttleRealtimeTableFooterView {
            stopFooter.setCompactLayout(transferView.preferredHeight > 0)
        }
        let actionHeight = actionFooter.frame.height
        let transferHeight = transferView.preferredHeight
        let desiredSize = CGSize(width: width, height: transferHeight + actionHeight)
        if let currentFooter = tableView.tableFooterView,
           currentFooter.bounds.size == desiredSize,
           transferView.superview === currentFooter,
           actionFooter.superview === currentFooter
        {
            return
        }

        let footer = UIView(frame: CGRect(origin: .zero, size: desiredSize))
        footer.backgroundColor = .systemBackground

        footer.addSubview(actionFooter)
        footer.addSubview(transferView)
        actionFooter.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(actionHeight)
        }
        transferView.snp.remakeConstraints { make in
            make.top.equalTo(actionFooter.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(transferHeight)
        }

        tableView.tableFooterView = footer
    }

    private func observeSubjects() {
        ShuttleRealtimeData.shared.showArrivalByTime.subscribe(onNext: { [weak self] showArrivalByTime in
            self?.shuttleRealtimeTableView.isHidden = showArrivalByTime
            self?.shuttleRealtimeTableTimeView.isHidden = !showArrivalByTime
        }).disposed(by: disposeBag)

        ShuttleRealtimeData.shared.isLoading
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] isLoading in
                guard let self else { return }
                showsInitialSkeleton = isLoading
                timetableDelegate.showsInitialSkeleton = isLoading
                UIView.performWithoutAnimation {
                    self.shuttleRealtimeTableView.reloadData()
                    self.shuttleRealtimeTableTimeView.reloadData()
                }
            }).disposed(by: disposeBag)

        ShuttleRealtimeData.shared.busAlternatives
            .subscribe(onNext: { [weak self] alternatives in
                self?.updateBusAlternatives(alternatives)
            }).disposed(by: disposeBag)

        ShuttleRealtimeData.shared.transferData
            .subscribe(onNext: { [weak self] data in
                guard let self else { return }
                transferInfoView?.setup(data: data)
                transferInfoTimeView?.setup(data: data)
                debugScrollToTransferFooterIfNeeded()
            }).disposed(by: disposeBag)
    }

    private func debugScrollToTransferFooterIfNeeded() {
        #if DEBUG
            guard ProcessInfo.processInfo.arguments.contains("-debugScrollShuttleTransferFooter"),
                  shouldShowTransferSection else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                let tableView = visibleTableView
                tableView.layoutIfNeeded()
                let bottomOffset = max(
                    0,
                    tableView.contentSize.height + tableView.adjustedContentInset.bottom - tableView.bounds.height
                )
                tableView.setContentOffset(CGPoint(x: 0, y: bottomOffset), animated: false)
            }
        #endif
    }

    private func observeAlarmStateChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(boardingAlarmStateDidChange),
            name: .shuttleBoardingAlarmStateDidChange,
            object: nil
        )
    }

    @objc private func boardingAlarmStateDidChange() {
        reloadActiveBoardingAlarmKeys()
    }

    private func reloadActiveBoardingAlarmKeys() {
        ShuttleAlarmNotificationService.shared.activeBoardingKeys { [weak self] keys in
            guard let self else { return }
            activeBoardingAlarmKeys = keys
            timetableDelegate.activeBoardingAlarmKeys = keys
            UIView.performWithoutAnimation {
                self.shuttleRealtimeTableView.reloadData()
                self.shuttleRealtimeTableTimeView.reloadData()
            }
        }
    }

    private func updateBusAlternatives(_ alternatives: [String: [ShuttleBusAlternativeDisplayData]]) {
        let mergedAlternatives = mergeBusAlternatives(alternatives)
        guard busAlternatives != mergedAlternatives else { return }
        let oldFooterCounts = footerAlternativeCounts(busAlternatives)
        let newFooterCounts = footerAlternativeCounts(mergedAlternatives)
        busAlternatives = mergedAlternatives

        if oldFooterCounts == newFooterCounts {
            updateVisibleBusAlternativeFooters()
        } else {
            UIView.performWithoutAnimation {
                let sections = IndexSet(integersIn: 0 ..< self.shuttleRealtimeSection.count)
                self.shuttleRealtimeTableView.reloadSections(sections, with: .none)
            }
        }
    }

    private func mergeBusAlternatives(_ incoming: [String: [ShuttleBusAlternativeDisplayData]])
        -> [String: [ShuttleBusAlternativeDisplayData]]
    {
        var merged = busAlternatives
        let now = Foundation.Date()
        let knownKeys = Set(busAlternatives.keys).union(incoming.keys)

        guard !incoming.isEmpty else {
            for key in knownKeys {
                guard let previous = merged[key], !previous.isEmpty else { continue }
                let lastNonEmptyAt = busAlternativeLastNonEmptyAt[key] ?? .distantPast
                if now.timeIntervalSince(lastNonEmptyAt) >= busAlternativeEmptyGraceInterval {
                    merged[key] = []
                }
            }
            return merged
        }

        for (key, value) in incoming {
            if value.isEmpty, let previous = merged[key], !previous.isEmpty {
                let lastNonEmptyAt = busAlternativeLastNonEmptyAt[key] ?? .distantPast
                if now.timeIntervalSince(lastNonEmptyAt) >= busAlternativeEmptyGraceInterval {
                    merged[key] = []
                }
                continue
            }
            merged[key] = value
            if !value.isEmpty {
                busAlternativeLastNonEmptyAt[key] = now
            }
        }
        return merged
    }

    private func footerAlternativeCounts(_ alternatives: [String: [ShuttleBusAlternativeDisplayData]]) -> [Int] {
        shuttleRealtimeSection.indices.map { section in
            let count = alternatives[busAlternativeKey(section: section)]?.count ?? 0
            if section == 0, forceShowBusAlternative, count == 0 {
                return 1
            }
            return count
        }
    }

    private func updateVisibleBusAlternativeFooters() {
        UIView.performWithoutAnimation {
            for section in self.shuttleRealtimeSection.indices {
                guard let footerView = self.shuttleRealtimeTableView.footerView(forSection: section) as? ShuttleRealtimeFooterView
                else { continue }
                let alternatives = self.busAlternatives[self.busAlternativeKey(section: section)] ?? []
                let forceShow = section == 0 && self.forceShowBusAlternative
                footerView.setupUI(
                    stopID: self.stopID,
                    section: section,
                    busAlternatives: alternatives,
                    forceShow: forceShow,
                    showEntireTimetable: self.showEntireTimetable
                ) { [weak self] alternative in
                    guard let self else { return }
                    showBusAlternativeStop(stopID, alternative)
                }
            }
        }
    }

    var visibleTableView: UITableView {
        shuttleRealtimeTableView.isHidden ? shuttleRealtimeTableTimeView : shuttleRealtimeTableView
    }

    var firstSectionHeaderHelpView: UIView? {
        (visibleTableView.headerView(forSection: 0) as? ShuttleRealtimeHeaderView)?.helpImageView
    }

    func reload() {
        shuttleRealtimeTableView.reloadData()
        shuttleRealtimeTableTimeView.reloadData()
        destinationRefreshControl.endRefreshing()
        timetableRefreshControl.endRefreshing()
    }

    func scrollToFooter() {
        shuttleRealtimeTableView.layoutIfNeeded()
        let offset = max(0, shuttleRealtimeTableView.contentSize.height - shuttleRealtimeTableView.bounds.height)
        shuttleRealtimeTableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        // Force UITableView to re-render visible section footers at the new scroll position
        shuttleRealtimeTableView.setNeedsLayout()
        shuttleRealtimeTableView.layoutIfNeeded()
    }

    var lastSectionFooterTimetableButton: UIView? {
        let n = shuttleRealtimeTableView.numberOfSections
        guard n > 0 else { return nil }
        return (shuttleRealtimeTableView.footerView(forSection: n - 1) as? ShuttleRealtimeFooterView)?.showEntireTimeTableButton
    }

    var busAlternativeView: UIView? {
        (visibleTableView.footerView(forSection: 0) as? ShuttleRealtimeFooterView)?.busAlternativeContainer
    }

    func reloadSection0() {
        UIView.performWithoutAnimation {
            visibleTableView.reloadSections(IndexSet(integer: 0), with: .none)
        }
    }

    func scrollToTop() {
        visibleTableView.setContentOffset(.zero, animated: false)
        visibleTableView.layoutIfNeeded()
    }

    private func showStopModal(_ stop: ShuttleStopEnum) {
        showStopVC(stop)
    }

    static func makeAlarmContext(
        stopID: ShuttleStopEnum,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order,
        directionDisplayName: String?
    ) -> ShuttleAlarmContext? {
        makeAlarmContext(
            stopID: stopID,
            routeName: item.route.name,
            routeTag: item.route.tag,
            directionDisplayName: directionDisplayName,
            departureTime: item.time,
            stops: item.stops.map { ShuttleAlarmRouteStop(id: $0.stop, time: $0.time) }
        )
    }

    static func makeAlarmContext(
        stopID: ShuttleStopEnum,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry,
        directionDisplayName: String?
    ) -> ShuttleAlarmContext? {
        makeAlarmContext(
            stopID: stopID,
            routeName: item.route.name,
            routeTag: item.route.tag,
            directionDisplayName: directionDisplayName,
            departureTime: item.time,
            stops: item.stops.map { ShuttleAlarmRouteStop(id: $0.stop, time: $0.time) }
        )
    }

    private static func makeAlarmContext(
        stopID: ShuttleStopEnum,
        routeName: String,
        routeTag: String,
        directionDisplayName: String?,
        departureTime: LocalTime,
        stops: [ShuttleAlarmRouteStop]
    ) -> ShuttleAlarmContext? {
        let boardingStopID = shuttleAlarmStopID(stopID)
        let departureDate = normalizedScheduleDate(for: departureTime.toLocalTime(), after: Foundation.Date.now)
        guard let boardingRouteStopIndex = stops.firstIndex(where: { $0.id == boardingStopID }) else {
            return nil
        }
        let routeStops = normalizeAlarmRouteStops(stops, boardingIndex: boardingRouteStopIndex, departureDate: departureDate)
        let boardingLocation = shuttleAlarmLocation(for: boardingStopID)
        let boardingStop = ShuttleAlarmStop(
            id: boardingStopID,
            name: shuttleAlarmStopName(boardingStopID),
            time: departureDate,
            latitude: boardingLocation?.latitude,
            longitude: boardingLocation?.longitude
        )
        var normalizedStops = routeStops
        normalizedStops[boardingRouteStopIndex] = boardingStop
        if let fallbackDestination = fallbackDestinationStop(
            stopID: stopID,
            routeName: routeName,
            departureDate: departureDate
        ),
            normalizedStops.dropFirst(boardingRouteStopIndex + 1).isEmpty
        {
            normalizedStops.append(fallbackDestination)
        }
        let orderedStops = normalizedStops
        let key = ["shuttle", boardingStopID, routeName, departureTime.replacingOccurrences(of: ":", with: "")].joined(separator: "_")
        let minutes = max(Int(ceil(departureDate.timeIntervalSince(Foundation.Date.now) / 60)), 0)
        return ShuttleAlarmContext(
            key: key,
            routeName: routeName,
            routeDisplayName: shuttleAlarmRouteDisplayName(stopID: stopID, routeName: routeName, routeTag: routeTag),
            directionDisplayName: directionDisplayName ?? normalizedStops.last?.name ?? boardingStop.name,
            boardingStop: boardingStop,
            routeStops: orderedStops,
            departureTime: departureDate,
            minutesUntilDeparture: minutes,
            createdAt: Foundation.Date.now
        )
    }

    private static func fallbackDestinationStop(
        stopID: ShuttleStopEnum,
        routeName: String,
        departureDate: Foundation.Date
    ) -> ShuttleAlarmStop? {
        guard stopID == .shuttlecockIn, routeName.hasSuffix("D") else { return nil }
        let stopID = "dormitory_i"
        let location = shuttleAlarmLocation(for: stopID)
        return ShuttleAlarmStop(
            id: stopID,
            name: shuttleAlarmStopName(stopID),
            time: departureDate.addingTimeInterval(5 * 60),
            latitude: location?.latitude,
            longitude: location?.longitude
        )
    }

    private static func normalizeAlarmRouteStops(
        _ stops: [ShuttleAlarmRouteStop],
        boardingIndex: Int,
        departureDate: Foundation.Date
    ) -> [ShuttleAlarmStop] {
        var dates = Array(repeating: departureDate, count: stops.count)

        var nextDate = departureDate
        if boardingIndex > 0 {
            for index in stride(from: boardingIndex - 1, through: 0, by: -1) {
                var date = scheduleDate(onSameDayAs: departureDate, time: stops[index].time.toLocalTime())
                while date >= nextDate {
                    date = date.addingTimeInterval(-24 * 60 * 60)
                }
                dates[index] = date
                nextDate = date
            }
        }

        var previousDate = departureDate
        if boardingIndex < stops.count - 1 {
            for index in (boardingIndex + 1) ..< stops.count {
                var date = scheduleDate(onSameDayAs: departureDate, time: stops[index].time.toLocalTime())
                while date <= previousDate {
                    date = date.addingTimeInterval(24 * 60 * 60)
                }
                dates[index] = date
                previousDate = date
            }
        }

        return stops.enumerated().map { index, routeStop in
            let location = shuttleAlarmLocation(for: routeStop.id)
            return ShuttleAlarmStop(
                id: routeStop.id,
                name: shuttleAlarmStopName(routeStop.id),
                time: dates[index],
                latitude: location?.latitude,
                longitude: location?.longitude
            )
        }
    }

    private static func scheduleDate(onSameDayAs date: Foundation.Date, time: Foundation.Date) -> Foundation.Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = timeComponents.second
        return calendar.date(from: components) ?? time
    }

    private static func shuttleAlarmRouteDisplayName(stopID: ShuttleStopEnum, routeName: String, routeTag: String) -> String {
        switch stopID {
        case .dormiotryOut, .shuttlecockOut:
            switch routeTag {
            case "DH": return String(localized: "shuttle_type_school_station")
            case "DY": return String(localized: "shuttle_type_school_terminal")
            case "DJ": return String(localized: "shuttle_type_school_jungang_station")
            case "C": return String(localized: "shuttle_type_school_circular")
            default: return routeName
            }
        case .station:
            if routeTag == "DH" {
                return routeName
                    .hasSuffix("S") ? String(localized: "shuttle_type_shuttlecock") : String(localized: "shuttle_type_dormitory")
            } else if routeTag == "DJ" {
                return String(localized: "shuttle_type_jungang_station")
            } else if routeTag == "C" {
                return routeName
                    .hasSuffix("S") ? String(localized: "shuttle_type_station_circular_shuttlecock") :
                    String(localized: "shuttle_type_station_circular_dormitory")
            }
            return routeName
        case .terminal:
            return routeName.hasSuffix("S") ? String(localized: "shuttle_type_shuttlecock") : String(localized: "shuttle_type_dormitory")
        case .jungangStation:
            return String(localized: "shuttle_type_dormitory")
        case .shuttlecockIn:
            return routeName
                .hasSuffix("S") ? String(localized: "shuttle_type_shuttlecock_finishing") : String(localized: "shuttle_type_dormitory")
        }
    }

    private static func normalizedScheduleDate(for date: Foundation.Date, after previousDate: Foundation.Date) -> Foundation.Date {
        var scheduledDate = date
        while scheduledDate <= previousDate {
            scheduledDate = scheduledDate.addingTimeInterval(24 * 60 * 60)
        }
        return scheduledDate
    }

    private static func shuttleAlarmStopID(_ stopID: ShuttleStopEnum) -> String {
        switch stopID {
        case .dormiotryOut:
            "dormitory_o"
        case .shuttlecockOut:
            "shuttlecock_o"
        case .station:
            "station"
        case .terminal:
            "terminal"
        case .jungangStation:
            "jungang_stn"
        case .shuttlecockIn:
            "shuttlecock_i"
        }
    }

    private static func shuttleAlarmStopName(_ stopID: String) -> String {
        switch stopID {
        case "dormitory_o":
            String(localized: "shuttle.stop.dormitory.out")
        case "dormitory_i":
            String(localized: "shuttle.stop.dormitory.in")
        case "shuttlecock_o":
            String(localized: "shuttle.stop.shuttlecock.out")
        case "station":
            String(localized: "shuttle.stop.station")
        case "terminal":
            String(localized: "shuttle.stop.terminal")
        case "jungang_stn":
            String(localized: "shuttle.stop.jungang.station")
        case "shuttlecock_i":
            String(localized: "shuttle.stop.shuttlecock.in")
        default:
            String(localized: "shuttle.stop.dormitory.out")
        }
    }

    private static func shuttleAlarmLocation(for stopID: String) -> (latitude: Double, longitude: Double)? {
        let locationStopID = stopID == "dormitory_i" ? "dormitory_o" : stopID
        if let stop = (try? ShuttleRealtimeData.shared.arrival.value())?.first(where: { $0.name == locationStopID }) {
            return (stop.latitude, stop.longitude)
        }
        return shuttleAlarmFallbackLocation(for: locationStopID)
    }

    private static func shuttleAlarmFallbackLocation(for stopID: String) -> (latitude: Double, longitude: Double)? {
        switch stopID {
        case "dormitory_o":
            (37.29339607529377, 126.83630604103446)
        case "shuttlecock_o":
            (37.29875417910844, 126.83784054072336)
        case "station":
            (37.309700971618255, 126.85207173389148)
        case "terminal":
            (37.319338173415936, 126.8455263115596)
        case "jungang_stn":
            (37.31487247528457, 126.83963540399434)
        case "shuttlecock_i":
            (37.29869328231496, 126.8377767466817)
        default:
            nil
        }
    }

    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.shuttleRefresh)
        refreshMethod()
    }
}

private struct ShuttleAlarmRouteStop {
    let id: String
    let time: LocalTime
}

extension ShuttleRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        shuttleRealtimeSection.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier) as? ShuttleRealtimeHeaderView
        else { return UIView() }
        guard shuttleRealtimeSection.indices.contains(section) else { return UIView() }
        let isExpanded = headerExpandedStates[section] ?? false
        headerView.setupUI(
            title: String(localized: shuttleRealtimeSection[section]),
            stop: stopID,
            section: section,
            isExpanded: isExpanded
        )
        headerView.onToggle = { [weak self] isExpanded in
            self?.headerExpandedStates[section] = isExpanded
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeFooterView.reuseIdentifier) as? ShuttleRealtimeFooterView
        else { return UIView() }
        guard shuttleRealtimeSection.indices.contains(section) else { return UIView() }
        let alternatives = busAlternatives[busAlternativeKey(section: section)] ?? []
        let forceShow = section == 0 && forceShowBusAlternative
        footerView.setupUI(
            stopID: stopID,
            section: section,
            busAlternatives: alternatives,
            forceShow: forceShow,
            showEntireTimetable: showEntireTimetable
        ) { [weak self] alternative in
            guard let self else { return }
            showBusAlternativeStop(stopID, alternative)
        }
        return footerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsInitialSkeleton {
            return skeletonRowCount(section: section)
        }
        if stopID == .dormiotryOut {
            if section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            } else if section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            } else if section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            }
        } else if stopID == .shuttlecockOut {
            if section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            } else if section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            } else if section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            }
        } else if stopID == .station {
            if section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            } else if section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            } else if section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value() else { return 0 }
                return max(min(data.count, 3), 1)
            }
        } else if stopID == .terminal {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return 0 }
            return max(min(data.count, 7), 1)
        } else if stopID == .jungangStation {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return 0 }
            return max(min(data.count, 7), 1)
        } else if stopID == .shuttlecockIn {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return 0 }
            return max(min(data.count, 7), 1)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard shuttleRealtimeSection.indices.contains(indexPath.section) else { return UITableViewCell() }
        if showsInitialSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        if stopID == .dormiotryOut {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .dormiotryOut,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .dormiotryOut,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .dormiotryOut,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .dormiotryOut,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .dormiotryOut,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .dormiotryOut,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value()
                else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .dormiotryOut,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .dormiotryOut,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .dormiotryOut,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            }
        } else if stopID == .shuttlecockOut {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .shuttlecockOut,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .shuttlecockOut,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .shuttlecockOut,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .shuttlecockOut,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .shuttlecockOut,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .shuttlecockOut,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value()
                else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .shuttlecockOut,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .shuttlecockOut,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .shuttlecockOut,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            }
        } else if stopID == .station {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .station,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .station,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .station,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.station, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .station,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .station,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .station,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.station, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value()
                else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                        for: indexPath
                    ) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = directionDisplayName(section: indexPath.section)
                    cell.setupUI(
                        stopID: .station,
                        indexPath: indexPath,
                        item: item,
                        isBoardingAlarmActive: isBoardingAlarmActive(
                            stopID: .station,
                            item: item,
                            directionDisplayName: directionDisplayName
                        )
                    ) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(
                            stopID: .station,
                            item: item,
                            directionDisplayName: self.directionDisplayName(section: indexPath.section)
                        ) else { return }
                        showAlarmVC(.station, context)
                    }
                    return cell
                }
            }
        } else if stopID == .terminal {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                let directionDisplayName = directionDisplayName(section: indexPath.section)
                cell.setupUI(
                    stopID: .terminal,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .terminal, item: item, directionDisplayName: directionDisplayName)
                ) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(
                        stopID: .terminal,
                        item: item,
                        directionDisplayName: self.directionDisplayName(section: indexPath.section)
                    ) else { return }
                    showAlarmVC(.terminal, context)
                }
                return cell
            }
        } else if stopID == .jungangStation {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                let directionDisplayName = directionDisplayName(section: indexPath.section)
                cell.setupUI(
                    stopID: .jungangStation,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(
                        stopID: .jungangStation,
                        item: item,
                        directionDisplayName: directionDisplayName
                    )
                ) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(
                        stopID: .jungangStation,
                        item: item,
                        directionDisplayName: self.directionDisplayName(section: indexPath.section)
                    ) else { return }
                    showAlarmVC(.jungangStation, context)
                }
                return cell
            }
        } else if stopID == .shuttlecockIn {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                let directionDisplayName = directionDisplayName(section: indexPath.section)
                cell.setupUI(
                    stopID: .shuttlecockIn,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(
                        stopID: .shuttlecockIn,
                        item: item,
                        directionDisplayName: directionDisplayName
                    )
                ) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(
                        stopID: .shuttlecockIn,
                        item: item,
                        directionDisplayName: self.directionDisplayName(section: indexPath.section)
                    ) else { return }
                    showAlarmVC(.shuttlecockIn, context)
                }
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if showsInitialSkeleton {
            return CGFloat.leastNormalMagnitude
        }
        let alternativesCount = busAlternatives[busAlternativeKey(section: section)]?.count ?? 0
        if alternativesCount > 0 {
            return CGFloat(50 + 50 * alternativesCount)
        }
        if section == 0, forceShowBusAlternative {
            return 100
        }
        return 50
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let header = tableView.headerView(forSection: section) as? ShuttleRealtimeHeaderView else {
            return 50
        }
        return header.isExpanded ? 50 + header.routeAdapterHeight : 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ShuttleRealtimeCellView else { return }
        guard let item = cell.itemByDestination else { return }
        AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
        showViaVCByDestination(item)
    }

    private func busAlternativeKey(section: Int) -> String {
        switch (stopID, section) {
        case (.dormiotryOut, 0):
            "dormitory_station"
        case (.dormiotryOut, 1):
            "dormitory_terminal"
        case (.dormiotryOut, 2):
            "dormitory_jungang"
        case (.shuttlecockOut, 0):
            "shuttlecock_station"
        case (.shuttlecockOut, 1):
            "shuttlecock_terminal"
        case (.shuttlecockOut, 2):
            "shuttlecock_jungang"
        case (.station, 0):
            "station_dormitory"
        case (.terminal, 0):
            "terminal_dormitory"
        case (.jungangStation, 0):
            "jungang_dormitory"
        default:
            ""
        }
    }

    private func skeletonRowCount(section: Int) -> Int {
        switch stopID {
        case .terminal, .jungangStation, .shuttlecockIn:
            4
        default:
            section == 0 ? 3 : 2
        }
    }

    private func directionDisplayName(section: Int) -> String? {
        guard shuttleRealtimeSection.indices.contains(section) else { return nil }
        return String(localized: shuttleRealtimeSection[section])
    }

    private func isBoardingAlarmActive(
        stopID: ShuttleStopEnum,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry,
        directionDisplayName: String?
    ) -> Bool {
        guard let context = Self.makeAlarmContext(stopID: stopID, item: item, directionDisplayName: directionDisplayName) else {
            return false
        }
        return activeBoardingAlarmKeys.contains(context.key)
    }
}
