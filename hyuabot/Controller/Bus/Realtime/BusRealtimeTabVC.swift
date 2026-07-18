import Api
import RxSwift
import UIKit

class BusRealtimeTabVC: UIViewController {
    let tabType: BusRealtimeType
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let refreshMethod: @MainActor () -> Void
    private let busRealtimeSection: [String.LocalizationValue]
    private let showEntireTimetable: @MainActor (Int32, [Int32], String.LocalizationValue) -> Void
    private let showDepartureLog: @MainActor (Int32, [Int32]) -> Void
    private let showStopVC: @MainActor (Int32, [Int32]) -> Void
    private var showsSkeleton = true
    private lazy var busRealtimeTableView: UITableView = .init().then {
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.backgroundColor = .systemBackground
        $0.refreshControl = refreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        $0.showsVerticalScrollIndicator = false
        // Register cells
        $0.register(BusRealtimeCellView.self, forCellReuseIdentifier: BusRealtimeCellView.reuseIdentifier)
        $0.register(BusRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: BusRealtimeHeaderView.reuseIdentifier)
        $0.register(BusRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: BusRealtimeFooterView.reuseIdentifier)
        $0.register(BusRealtimeEmptyCellView.self, forCellReuseIdentifier: BusRealtimeEmptyCellView.reuseIdentifier)
        $0.register(BusRealtimeSkeletonCellView.self, forCellReuseIdentifier: BusRealtimeSkeletonCellView.reuseIdentifier)
        $0.register(
            BusRealtimeSkeletonHeaderView.self,
            forHeaderFooterViewReuseIdentifier: BusRealtimeSkeletonHeaderView.reuseIdentifier
        )
        $0.register(
            BusRealtimeSkeletonFooterView.self,
            forHeaderFooterViewReuseIdentifier: BusRealtimeSkeletonFooterView.reuseIdentifier
        )
    }

    required init(
        tabType: BusRealtimeType,
        refreshMethod: @escaping @MainActor () -> Void,
        showEntireTimetable: @escaping @MainActor (Int32, [Int32], String.LocalizationValue) -> Void,
        showDepartureLog: @escaping @MainActor (Int32, [Int32]) -> Void,
        showStopVC: @escaping @MainActor (Int32, [Int32]) -> Void
    ) {
        self.tabType = tabType
        self.refreshMethod = refreshMethod
        self.showEntireTimetable = showEntireTimetable
        self.showDepartureLog = showDepartureLog
        self.showStopVC = showStopVC
        switch tabType {
        case .city: busRealtimeSection = [
                "bus.realtime.section.10-1.campus",
                "bus.realtime.section.10-1.station"
            ]
        case .seoul: busRealtimeSection = [
                "bus.realtime.section.3102",
                "bus.realtime.section.seoul.other"
            ]
        case .suwon: busRealtimeSection = [
                "bus.realtime.section.suwon.other"
            ]
        case .other: busRealtimeSection = [
                "bus.realtime.section.50.ansan",
                "bus.realtime.section.50.station"
            ]
        }
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeSubjects()
    }

    private func setupUI() {
        view.addSubview(busRealtimeTableView)
        busRealtimeTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func showStopModal(_ stopID: Int32, routes: [Int32] = []) {
        showStopVC(stopID, routes)
    }

    private func observeSubjects() {
        BusRealtimeData.shared.isLoading
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.showsSkeleton = isLoading
                self?.reload()
            })
            .disposed(by: disposeBag)
    }

    func reload() {
        busRealtimeTableView.reloadData()
        refreshControl.endRefreshing()
    }

    var firstSectionHeaderLocationButton: UIView? {
        (busRealtimeTableView.headerView(forSection: 0) as? BusRealtimeHeaderView)?.locationButton
    }

    var firstSectionFooterTimetableButton: UIView? {
        (busRealtimeTableView.footerView(forSection: 0) as? BusRealtimeFooterView)?.showEntireTimeTableButton
    }

    var firstSectionFooterLogButton: UIView? {
        (busRealtimeTableView.footerView(forSection: 0) as? BusRealtimeFooterView)?.showDeparuteLogButton
    }

    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.busRefresh)
        refreshMethod()
    }
}

extension BusRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        busRealtimeSection.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if showsSkeleton {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: BusRealtimeSkeletonHeaderView.reuseIdentifier)
        }
        guard let headerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: BusRealtimeHeaderView.reuseIdentifier) as? BusRealtimeHeaderView
        else {
            return UIView()
        }
        let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216_000_379 : UserDefaults.standard
            .integer(forKey: "busStopID"))
        var stopID: Int32 = 0
        var routes: [Int32] = []
        if tabType == .city {
            if section == 0 {
                stopID = selectedStopID
                routes = [216_000_068]
            } else if section == 1 {
                stopID = 216_000_138
                routes = [216_000_068]
            }
        } else if tabType == .seoul {
            if section == 0 {
                stopID = selectedStopID
                routes = [216_000_061]
            } else if section == 1 {
                stopID = 216_000_719
                routes = [216_000_026, 216_000_043, 216_000_096]
            }
        } else if tabType == .suwon {
            if section == 0 {
                stopID = 216_000_070
                routes = [216_000_104, 200_000_015]
            }
        } else if tabType == .other {
            if section == 0 {
                stopID = 216_000_759
                routes = [216_000_075]
            } else if section == 1 {
                stopID = 213_000_487
                routes = [216_000_075]
            }
        }
        headerView.setupUI(
            title: String(localized: busRealtimeSection[section]),
            showStopVC: { [weak self] in
                self?.showStopModal(stopID, routes: routes)
            }
        )
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if showsSkeleton {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: BusRealtimeSkeletonFooterView.reuseIdentifier)
        }
        guard let footerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: BusRealtimeFooterView.reuseIdentifier) as? BusRealtimeFooterView
        else {
            return UIView()
        }
        let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216_000_379 : UserDefaults.standard
            .integer(forKey: "busStopID"))
        var stopID: Int32 = 0
        var routes: [Int32] = []
        if tabType == .city {
            if section == 0 {
                stopID = selectedStopID
                routes = [216_000_068]
            } else if section == 1 {
                stopID = 216_000_138
                routes = [216_000_068]
            }
        } else if tabType == .seoul {
            if section == 0 {
                stopID = selectedStopID
                routes = [216_000_061]
            } else if section == 1 {
                stopID = 216_000_719
                routes = [216_000_026, 216_000_043, 216_000_096]
            }
        } else if tabType == .suwon {
            if section == 0 {
                stopID = 216_000_070
                routes = [216_000_104, 200_000_015]
            }
        } else if tabType == .other {
            if section == 0 {
                stopID = 216_000_759
                routes = [216_000_075]
            } else if section == 1 {
                stopID = 213_000_487
                routes = [216_000_075]
            }
        }
        footerView.setupUI(
            stopID: stopID,
            routes: routes,
            title: busRealtimeSection[section],
            showEntireTimetable: showEntireTimetable,
            showDepartureLog: showDepartureLog
        )
        return footerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return section == 0 ? 3 : 2
        }
        if tabType == .city {
            if section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeCityFromCampus.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 5)
            } else if section == 1 {
                guard let items = try? BusRealtimeData.shared.busRealtimeCityFromStation.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 5)
            }
        } else if tabType == .seoul {
            if section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeSeoulFromCampus.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 5)
            } else if section == 1 {
                guard let items = try? BusRealtimeData.shared.busRealtimeGunpoFromCampus.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 5)
            }
        } else if tabType == .suwon {
            if section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeSuwonFromCampus.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 10)
            }
        } else if tabType == .other {
            if section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeKTXFromCampus.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 5)
            } else if section == 1 {
                guard let items = try? BusRealtimeData.shared.busRealtimeKTXFromStation.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 5)
            }
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: BusRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let cell = tableView
            .dequeueReusableCell(withIdentifier: BusRealtimeCellView.reuseIdentifier, for: indexPath) as? BusRealtimeCellView
        else { fatalError() }
        if tabType == .city {
            if indexPath.section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeCityFromCampus.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            } else if indexPath.section == 1 {
                guard let items = try? BusRealtimeData.shared.busRealtimeCityFromStation.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            }
        } else if tabType == .seoul {
            if indexPath.section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeSeoulFromCampus.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            } else if indexPath.section == 1 {
                guard let items = try? BusRealtimeData.shared.busRealtimeGunpoFromCampus.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            }
        } else if tabType == .suwon {
            if indexPath.section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeSuwonFromCampus.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            }
        } else if tabType == .other {
            if indexPath.section == 0 {
                guard let items = try? BusRealtimeData.shared.busRealtimeKTXFromCampus.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            } else if indexPath.section == 1 {
                guard let items = try? BusRealtimeData.shared.busRealtimeKTXFromStation.value() else { return BusRealtimeEmptyCellView() }
                if items.isEmpty { return BusRealtimeEmptyCellView() }
                cell.setupUI(item: items[indexPath.row])
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        50
    }
}
