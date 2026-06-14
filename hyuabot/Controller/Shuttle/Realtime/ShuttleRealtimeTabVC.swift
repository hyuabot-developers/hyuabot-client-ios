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
    private let timetableDelegate: ShuttleRealtimeTimeTableDelegate
    private var headerExpandedStates: [Int: Bool] = [:]
    private(set) var transferInfoView: ShuttleTransferInfoView?
    private var busAlternativeBannerHeightConstraint: Constraint?
    private lazy var busAlternativeBanner: UIView = {
        let banner = UIView()
        banner.backgroundColor = .hanyangOrange
        banner.clipsToBounds = true
        let routeLabel = UILabel().then {
            $0.tag = 100
            $0.font = .systemFont(ofSize: 13, weight: .bold)
            $0.textColor = .white
            $0.text = String(localized: "shuttle.bus.alternative.route")
        }
        let timeLabel = UILabel().then {
            $0.tag = 101
            $0.font = .systemFont(ofSize: 13)
            $0.textColor = .white
            $0.textAlignment = .right
        }
        banner.addSubview(routeLabel)
        banner.addSubview(timeLabel)
        routeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        timeLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(routeLabel.snp.trailing).offset(8)
        }
        return banner
    }()
    lazy var tableFooterView1 = ShuttleRealtimeTableFooterView(parentView: self.view, stopID: self.stopID, showStopModal: showStopModal)
    lazy var tableFooterView2 = ShuttleRealtimeTableFooterView2(parentView: self.view, stopID: self.stopID, showStopModal: showStopModal, showEntireTimetable: showEntireTimetable)
    private lazy var shuttleRealtimeTableView: UITableView = {
        let tableView = UITableView().then{
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
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
        let tableView = UITableView().then{
            $0.delegate = self.timetableDelegate
            $0.dataSource = self.timetableDelegate
            $0.sectionHeaderTopPadding = 0
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
        showStopVC: @escaping (ShuttleStopEnum) -> Void
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
        self.timetableDelegate = ShuttleRealtimeTimeTableDelegate(showViaVC: showViaVCByOrder, stopID: self.stopID)
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
            self.view.addSubview(busAlternativeBanner)
            self.view.addSubview(self.shuttleRealtimeTableView)
            self.view.addSubview(self.shuttleRealtimeTableTimeView)
            self.view.addSubview(transferView)
            busAlternativeBanner.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                busAlternativeBannerHeightConstraint = make.height.equalTo(0).constraint
            }
            transferView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
            }
            self.shuttleRealtimeTableView.snp.makeConstraints { make in
                make.top.equalTo(busAlternativeBanner.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(transferView.snp.top)
            }
            self.shuttleRealtimeTableTimeView.snp.makeConstraints { make in
                make.top.equalTo(busAlternativeBanner.snp.bottom)
                make.leading.trailing.equalToSuperview()
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

        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            let busSubject = stopID == .dormiotryOut
                ? ShuttleRealtimeData.shared.busAlternativeDormitory.asObservable()
                : ShuttleRealtimeData.shared.busAlternativeShuttlecock.asObservable()
            let shuttleSubject = stopID == .dormiotryOut
                ? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.asObservable()
                : ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.asObservable()
            Observable.combineLatest(busSubject, shuttleSubject)
                .subscribe(onNext: { [weak self] busData, shuttleEntries in
                    guard let self else { return }
                    guard let busMinutes = busData?.arrival.first?.minutes else {
                        self.updateBusAlternativeBanner(visible: false, minutes: 0)
                        return
                    }
                    guard let nextShuttle = shuttleEntries.first else {
                        self.updateBusAlternativeBanner(visible: true, minutes: busMinutes)
                        return
                    }
                    let shuttleMinutes = Int(nextShuttle.time.toLocalTime().timeIntervalSince(Date.now)) / 60
                    self.updateBusAlternativeBanner(visible: busMinutes < shuttleMinutes, minutes: busMinutes)
                }).disposed(by: self.disposeBag)
        }
    }

    private func updateBusAlternativeBanner(visible: Bool, minutes: Int) {
        let height: CGFloat = visible ? 44 : 0
        UIView.animate(withDuration: 0.3) {
            self.busAlternativeBannerHeightConstraint?.update(offset: height)
            self.view.layoutIfNeeded()
        }
        if visible, let timeLabel = busAlternativeBanner.viewWithTag(101) as? UILabel {
            timeLabel.text = String(localized: "shuttle.bus.alternative.time.\(minutes)")
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
    
    private func showStopModal(_ stop: ShuttleStopEnum) {
        self.showStopVC(stop)
    }

    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.shuttleRefresh)
        self.refreshMethod()
    }
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
        footerView.setupUI(stopID: self.stopID, section: section, showEntireTimetable: showEntireTimetable)
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
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            }
        } else if (self.stopID == .shuttlecockOut) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            }
        } else if (self.stopID == .station) {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value() else { return UITableViewCell() }
                if !data.isEmpty {
                    let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                    cell.setupUI(stopID: .station, indexPath: indexPath, item: data[indexPath.row])
                    return cell
                }
            }
        } else if (self.stopID == .terminal) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .terminal, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .jungangStation) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .jungangStation, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .shuttlecockIn) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .shuttlecockIn, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
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
}
