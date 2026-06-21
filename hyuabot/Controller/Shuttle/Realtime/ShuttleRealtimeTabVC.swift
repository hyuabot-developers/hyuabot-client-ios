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
                guard let context = Self.makeAlarmContext(stopID: stopID, item: item) else { return }
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

    private static func makeAlarmContext(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> ShuttleAlarmContext? {
        makeAlarmContext(
            stopID: stopID,
            routeName: item.route.name,
            departureTime: item.time,
            stops: item.stops.map { ShuttleAlarmRouteStop(id: $0.stop, time: $0.time) }
        )
    }

    private static func makeAlarmContext(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) -> ShuttleAlarmContext? {
        makeAlarmContext(
            stopID: stopID,
            routeName: item.route.name,
            departureTime: item.time,
            stops: item.stops.map { ShuttleAlarmRouteStop(id: $0.stop, time: $0.time) }
        )
    }

    private static func makeAlarmContext(stopID: ShuttleStopEnum, routeName: String, departureTime: LocalTime, stops: [ShuttleAlarmRouteStop]) -> ShuttleAlarmContext? {
        let boardingStopID = shuttleAlarmStopID(stopID)
        let departureDate = normalizedScheduleDate(for: departureTime.toLocalTime(), after: Foundation.Date.now)
        let routeStops = stops.map { routeStop in
            let date = normalizedScheduleDate(for: routeStop.time.toLocalTime(), after: departureDate.addingTimeInterval(-1))
            let location = shuttleAlarmLocation(for: routeStop.id)
            return ShuttleAlarmStop(
                id: routeStop.id,
                name: shuttleAlarmStopName(routeStop.id),
                time: date,
                latitude: location?.latitude,
                longitude: location?.longitude
            )
        }
        guard let boardingRouteStop = routeStops.first(where: { $0.id == boardingStopID }) else {
            return nil
        }
        let boardingLocation = shuttleAlarmLocation(for: boardingStopID)
        let boardingStop = ShuttleAlarmStop(
            id: boardingStopID,
            name: shuttleAlarmStopName(boardingStopID),
            time: departureDate,
            latitude: boardingLocation?.latitude,
            longitude: boardingLocation?.longitude
        )
        let key = ["shuttle", boardingStopID, routeName, departureTime.replacingOccurrences(of: ":", with: "")].joined(separator: "_")
        let minutes = max(Int(ceil(departureDate.timeIntervalSince(Foundation.Date.now) / 60)), 0)
        var normalizedStops = routeStops
        if let index = normalizedStops.firstIndex(where: { $0.id == boardingRouteStop.id }) {
            normalizedStops[index] = boardingStop
        }
        return ShuttleAlarmContext(
            key: key,
            boardingStop: boardingStop,
            routeStops: normalizedStops,
            departureTime: departureDate,
            minutesUntilDeparture: minutes
        )
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
        let isExpanded = headerExpandedStates[section] ?? false
        headerView.setupUI(title: String(localized: self.shuttleRealtimeSection[section]), stop: self.stopID, section: section, isExpanded: isExpanded)
        headerView.onToggle = { [weak self] isExpanded in
            self?.headerExpandedStates[section] = isExpanded
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeFooterView.reuseIdentifier) as? ShuttleRealtimeFooterView else { return UIView() }
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
        if (self.stopID == .dormiotryOut) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .dormiotryOut, item: item) else { return }
                        self.showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .dormiotryOut, item: item) else { return }
                        self.showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .dormiotryOut, item: item) else { return }
                        self.showAlarmVC(.dormiotryOut, context)
                    }
                    return cell
                }
            }
        } else if (self.stopID == .shuttlecockOut) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockOut, item: item) else { return }
                        self.showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockOut, item: item) else { return }
                        self.showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockOut, item: item) else { return }
                        self.showAlarmVC(.shuttlecockOut, context)
                    }
                    return cell
                }
            }
        } else if (self.stopID == .station) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .station, item: item) else { return }
                        self.showAlarmVC(.station, context)
                    }
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .station, item: item) else { return }
                        self.showAlarmVC(.station, context)
                    }
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    let item = data[indexPath.row]
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: item) { [weak self] in
                        guard let self, let context = Self.makeAlarmContext(stopID: .station, item: item) else { return }
                        self.showAlarmVC(.station, context)
                    }
                    return cell
                }
            }
        } else if (self.stopID == .terminal) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(stopID: .terminal, indexPath: indexPath, item: item) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(stopID: .terminal, item: item) else { return }
                    self.showAlarmVC(.terminal, context)
                }
                return cell
            }
        } else if (self.stopID == .jungangStation) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(stopID: .jungangStation, indexPath: indexPath, item: item) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(stopID: .jungangStation, item: item) else { return }
                    self.showAlarmVC(.jungangStation, context)
                }
                return cell
            }
        } else if (self.stopID == .shuttlecockIn) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(stopID: .shuttlecockIn, indexPath: indexPath, item: item) { [weak self] in
                    guard let self, let context = Self.makeAlarmContext(stopID: .shuttlecockIn, item: item) else { return }
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
}
