import UIKit
import RxSwift
import SnapKit
import Api

class ShuttleRealtimeTabVC: UIViewController {
    let stopID: ShuttleStopEnum
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let shuttleRealtimeSection: [String.LocalizationValue]
    private let refreshMethod: () -> Void
    private let showEntireTimetable: (ShuttleStopEnum, Int) -> Void
    private let showViaVCByOrder: (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    private let showViaVCByDestination: (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Void
    private let showStopVC: (ShuttleStopEnum) -> Void
    private let showBusAlternativeStop: (ShuttleStopEnum, ShuttleBusAlternativeDisplayData) -> Void
    private let showAlarmVC: (ShuttleStopEnum, ShuttleAlarmContext) -> Void
    private let timetableDelegate: ShuttleRealtimeTimeTableDelegate
    private var headerExpandedStates: [Int: Bool] = [:]
    private(set) var transferInfoView: ShuttleTransferInfoView?
    private var busAlternatives: [String: [ShuttleBusAlternativeDisplayData]] = [:]
    private var activeBoardingAlarmKeys: Set<String> = []
    var forceShowBusAlternative = false
    lazy var tableFooterView1 = ShuttleRealtimeTableFooterView(parentView: self.view, stopID: self.stopID, showStopModal: showStopModal)
    lazy var tableFooterView2 = ShuttleRealtimeTableFooterView2(parentView: self.view, stopID: self.stopID, showStopModal: showStopModal, showEntireTimetable: showEntireTimetable)
    private lazy var shuttleRealtimeTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped).then{
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.backgroundColor = .systemBackground
            $0.refreshControl = refreshControl
            $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
            $0.tableFooterView = self.tableFooterView1
            $0.showsVerticalScrollIndicator = false
            // Register the view
            $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
            $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
            $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
            $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
        }
        return tableView
    }()
    private lazy var shuttleRealtimeTableTimeView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped).then{
            $0.delegate = self.timetableDelegate
            $0.dataSource = self.timetableDelegate
            $0.sectionHeaderTopPadding = 0
            $0.backgroundColor = .systemBackground
            $0.tableFooterView = self.tableFooterView2
            $0.refreshControl = refreshControl
            $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
            $0.showsVerticalScrollIndicator = false
            // Register the view
            $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
            $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
            $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
            $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
        }
        return tableView
    }()
    required init(
        stopID: ShuttleStopEnum,
        refreshMethod: @escaping () -> Void,
        showEntireTimetable: @escaping (ShuttleStopEnum, Int) -> Void,
        showViaVCByOrder: @escaping (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void,
        showViaVCByDestination: @escaping (ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> Void,
        showStopVC: @escaping (ShuttleStopEnum) -> Void,
        showBusAlternativeStop: @escaping (ShuttleStopEnum, ShuttleBusAlternativeDisplayData) -> Void,
        showAlarmVC: @escaping (ShuttleStopEnum, ShuttleAlarmContext) -> Void
    ) {
        self.stopID = stopID
        if (self.stopID == .dormiotryOut || self.stopID == .shuttlecockOut) {
            self.shuttleRealtimeSection = ["shuttle.desination.subway", "shuttle.desination.terminal", "shuttle.desination.jungang_station"]
        } else if (self.stopID == .station) {
            self.shuttleRealtimeSection = ["shuttle.desination.dormitory", "shuttle.desination.terminal", "shuttle.desination.jungang_station"]
        } else {
            self.shuttleRealtimeSection = ["shuttle.desination.dormitory"]
        }
        self.refreshMethod = refreshMethod
        self.showEntireTimetable = showEntireTimetable
        self.showViaVCByOrder = showViaVCByOrder
        self.showViaVCByDestination = showViaVCByDestination
        self.showStopVC = showStopVC
        self.showBusAlternativeStop = showBusAlternativeStop
        self.showAlarmVC = showAlarmVC
        self.timetableDelegate = ShuttleRealtimeTimeTableDelegate(
            showViaVC: showViaVCByOrder,
            showAlarmVC: { stopID, item in
                guard let context = Self.makeAlarmContext(stopID: stopID, item: item, directionDisplayName: nil) else { return }
                showAlarmVC(stopID, context)
            },
            stopID: self.stopID
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.observeSubjects()
        self.observeAlarmStateChanges()
        self.reloadActiveBoardingAlarmKeys()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reloadActiveBoardingAlarmKeys()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        let transferStops: [ShuttleStopEnum] = [.dormiotryOut, .shuttlecockOut]
        if transferStops.contains(self.stopID) {
            let transferView = ShuttleTransferInfoView(stopID: self.stopID)
            self.transferInfoView = transferView
            self.view.addSubview(self.shuttleRealtimeTableView)
            self.view.addSubview(self.shuttleRealtimeTableTimeView)
            self.view.addSubview(transferView)
            transferView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
            }
            self.shuttleRealtimeTableView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(transferView.snp.top)
            }
            self.shuttleRealtimeTableTimeView.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(transferView.snp.top)
            }
        } else {
            self.view.addSubview(self.shuttleRealtimeTableView)
            self.view.addSubview(self.shuttleRealtimeTableTimeView)
            self.shuttleRealtimeTableView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            self.shuttleRealtimeTableTimeView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    private func observeSubjects() {
        ShuttleRealtimeData.shared.showArrivalByTime.subscribe(onNext: { [weak self] showArrivalByTime in
            self?.shuttleRealtimeTableView.isHidden = showArrivalByTime
            self?.shuttleRealtimeTableTimeView.isHidden = !showArrivalByTime
        }).disposed(by: self.disposeBag)

        ShuttleRealtimeData.shared.busAlternatives
            .subscribe(onNext: { [weak self] alternatives in
            self?.updateBusAlternatives(alternatives)
            }).disposed(by: self.disposeBag)
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
            self.activeBoardingAlarmKeys = keys
            self.timetableDelegate.activeBoardingAlarmKeys = keys
            UIView.performWithoutAnimation {
                self.shuttleRealtimeTableView.reloadData()
                self.shuttleRealtimeTableTimeView.reloadData()
            }
        }
    }

    private func updateBusAlternatives(_ alternatives: [String: [ShuttleBusAlternativeDisplayData]]) {
        guard busAlternatives != alternatives else { return }
        busAlternatives = alternatives
        UIView.performWithoutAnimation {
            let sections = IndexSet(integersIn: 0..<self.shuttleRealtimeSection.count)
            self.shuttleRealtimeTableView.reloadSections(sections, with: .none)
        }
    }

    var visibleTableView: UITableView {
        shuttleRealtimeTableView.isHidden ? shuttleRealtimeTableTimeView : shuttleRealtimeTableView
    }

    var firstSectionHeaderHelpView: UIView? {
        (visibleTableView.headerView(forSection: 0) as? ShuttleRealtimeHeaderView)?.helpImageView
    }

    func reload() {
        self.shuttleRealtimeTableView.reloadData()
        self.shuttleRealtimeTableTimeView.reloadData()
        self.refreshControl.endRefreshing()
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
        self.showStopVC(stop)
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

    private static func makeAlarmContext(stopID: ShuttleStopEnum, routeName: String, routeTag: String, directionDisplayName: String?, departureTime: LocalTime, stops: [ShuttleAlarmRouteStop]) -> ShuttleAlarmContext? {
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
            for index in (boardingIndex + 1)..<stops.count {
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
                return routeName.hasSuffix("S") ? String(localized: "shuttle_type_shuttlecock") : String(localized: "shuttle_type_dormitory")
            } else if routeTag == "DJ" {
                return String(localized: "shuttle_type_jungang_station")
            } else if routeTag == "C" {
                return routeName.hasSuffix("S") ? String(localized: "shuttle_type_station_circular_shuttlecock") : String(localized: "shuttle_type_station_circular_dormitory")
            }
            return routeName
        case .terminal:
            return routeName.hasSuffix("S") ? String(localized: "shuttle_type_shuttlecock") : String(localized: "shuttle_type_dormitory")
        case .jungangStation:
            return String(localized: "shuttle_type_dormitory")
        case .shuttlecockIn:
            return routeName.hasSuffix("S") ? String(localized: "shuttle_type_shuttlecock_finishing") : String(localized: "shuttle_type_dormitory")
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

    private static func shuttleAlarmStopName(_ stopID: String) -> String {
        switch stopID {
        case "dormitory_o", "dormitory_i":
            return String(localized: "shuttle.stop.dormitory.out")
        case "shuttlecock_o":
            return String(localized: "shuttle.stop.shuttlecock.out")
        case "station":
            return String(localized: "shuttle.stop.station")
        case "terminal":
            return String(localized: "shuttle.stop.terminal")
        case "jungang_stn":
            return String(localized: "shuttle.stop.jungang.station")
        case "shuttlecock_i":
            return String(localized: "shuttle.stop.shuttlecock.in")
        default:
            return String(localized: "shuttle.stop.dormitory.out")
        }
    }

    private static func shuttleAlarmLocation(for stopID: String) -> ShuttleRealtimePageQuery.Data.Shuttle.Stop? {
        let locationStopID = stopID == "dormitory_i" ? "dormitory_o" : stopID
        return (try? ShuttleRealtimeData.shared.arrival.value())?.first(where: { $0.name == locationStopID })
    }

    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.shuttleRefresh)
        self.refreshMethod()
    }
}

private struct ShuttleAlarmRouteStop {
    let id: String
    let time: LocalTime
}

extension ShuttleRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.shuttleRealtimeSection.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier) as? ShuttleRealtimeHeaderView else { return UIView() }
        guard self.shuttleRealtimeSection.indices.contains(section) else { return UIView() }
        let isExpanded = headerExpandedStates[section] ?? false
        headerView.setupUI(title: String(localized: self.shuttleRealtimeSection[section]), stop: self.stopID, section: section, isExpanded: isExpanded)
        headerView.onToggle = { [weak self] isExpanded in
            self?.headerExpandedStates[section] = isExpanded
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeFooterView.reuseIdentifier) as? ShuttleRealtimeFooterView else { return UIView() }
        guard self.shuttleRealtimeSection.indices.contains(section) else { return UIView() }
        let alternatives = busAlternatives[busAlternativeKey(section: section)] ?? []
        let forceShow = section == 0 && forceShowBusAlternative
        footerView.setupUI(stopID: self.stopID, section: section, busAlternatives: alternatives, forceShow: forceShow, showEntireTimetable: showEntireTimetable) { [weak self] alternative in
            guard let self else { return }
            self.showBusAlternativeStop(self.stopID, alternative)
        }
        return footerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.stopID == .dormiotryOut) {
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
        } else if (self.stopID == .shuttlecockOut) {
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
        } else if (self.stopID == .station) {
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
        } else if (self.stopID == .terminal) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return 0 }
            return max(min(data.count, 7), 1)
        } else if (self.stopID == .jungangStation) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return 0 }
            return max(min(data.count, 7), 1)
        } else if (self.stopID == .shuttlecockIn) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return 0 }
            return max(min(data.count, 7), 1)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard self.shuttleRealtimeSection.indices.contains(indexPath.section) else { return UITableViewCell() }
        if (self.stopID == .dormiotryOut) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .dormiotryOut, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .dormiotryOut, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .dormiotryOut, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .dormiotryOut, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .dormiotryOut, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .dormiotryOut, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            }
        } else if (self.stopID == .shuttlecockOut) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .shuttlecockOut, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockOut, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .shuttlecockOut, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockOut, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .shuttlecockOut, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockOut, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            }
        } else if (self.stopID == .station) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .station, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .station, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.station, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .station, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .station, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.station, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .station, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .station, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                        self.showAlarmVC(.station, context)
                    }
                    return cell
                }
            }
        } else if (self.stopID == .terminal) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                cell.setupUI(stopID: .terminal, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .terminal, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(stopID: .terminal, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                    self.showAlarmVC(.terminal, context)
                }
                return cell
            }
        } else if (self.stopID == .jungangStation) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                cell.setupUI(stopID: .jungangStation, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .jungangStation, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(stopID: .jungangStation, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                    self.showAlarmVC(.jungangStation, context)
                }
                return cell
            }
        } else if (self.stopID == .shuttlecockIn) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                let directionDisplayName = self.directionDisplayName(section: indexPath.section)
                cell.setupUI(stopID: .shuttlecockIn, indexPath: indexPath, item: item, isBoardingAlarmActive: isBoardingAlarmActive(stopID: .shuttlecockIn, item: item, directionDisplayName: directionDisplayName)) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockIn, item: item, directionDisplayName: self.directionDisplayName(section: indexPath.section)) else { return }
                    self.showAlarmVC(.shuttlecockIn, context)
                }
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
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
        self.showViaVCByDestination(item)
    }

    private func busAlternativeKey(section: Int) -> String {
        switch (stopID, section) {
        case (.dormiotryOut, 0):
            return "dormitory_station"
        case (.dormiotryOut, 1):
            return "dormitory_terminal"
        case (.dormiotryOut, 2):
            return "dormitory_jungang"
        case (.shuttlecockOut, 0):
            return "shuttlecock_station"
        case (.shuttlecockOut, 1):
            return "shuttlecock_terminal"
        case (.shuttlecockOut, 2):
            return "shuttlecock_jungang"
        case (.station, 0):
            return "station_dormitory"
        case (.terminal, 0):
            return "terminal_dormitory"
        case (.jungangStation, 0):
            return "jungang_dormitory"
        default:
            return ""
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
