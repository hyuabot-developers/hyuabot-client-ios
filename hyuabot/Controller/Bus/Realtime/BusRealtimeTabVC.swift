//
//  BusRealtimeTabVC.swift
//  hyuabot
//

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

    @objc
    private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.busRefresh)
        refreshMethod()
    }
}

extension BusRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        busRealtimeSection.count
    }

    /// Stop ID + route list currently backing a given section, and the section's display title
    /// (dynamic for sections whose primary stop is GPS-selected among a widened candidate set).
    private func sectionInfo(_ section: Int) -> BusRealtimeSectionInfo {
        let selectedStopID = Int32(UserDefaults.standard.integer(forKey: "busStopID") == 0 ? 216_000_379 : UserDefaults.standard
            .integer(forKey: "busStopID"))
        let seoulFirstStopID = Int32(
            UserDefaults.standard.integer(forKey: "bus.seoulFirstStopID") == 0 ? 216_000_379 : UserDefaults.standard
                .integer(forKey: "bus.seoulFirstStopID")
        )
        let seoulSecondStopID = Int32(
            UserDefaults.standard.integer(forKey: "bus.seoulSecondStopID") == 0 ? 216_000_719 : UserDefaults.standard
                .integer(forKey: "bus.seoulSecondStopID")
        )
        let suwonStopID = Int32(
            UserDefaults.standard.integer(forKey: "bus.suwonStopID") == 0 ? 216_000_070 : UserDefaults.standard
                .integer(forKey: "bus.suwonStopID")
        )
        switch tabType {
        case .city:
            if section == 0 {
                return BusRealtimeSectionInfo(
                    stopID: selectedStopID,
                    routes: [216_000_068],
                    title: dynamicSectionTitle(route: "10-1", stopID: selectedStopID)
                )
            }
            return BusRealtimeSectionInfo(
                stopID: 216_000_138, routes: [216_000_068], title: String(localized: busRealtimeSection[section])
            )
        case .seoul:
            if section == 0 {
                return BusRealtimeSectionInfo(
                    stopID: seoulFirstStopID,
                    routes: [216_000_061],
                    title: dynamicSectionTitle(route: "3102", stopID: seoulFirstStopID)
                )
            }
            return BusRealtimeSectionInfo(
                stopID: seoulSecondStopID,
                routes: [216_000_026, 216_000_043, 216_000_096],
                title: dynamicSectionTitle(route: "3100/3101/3100N", stopID: seoulSecondStopID)
            )
        case .suwon:
            return BusRealtimeSectionInfo(
                stopID: suwonStopID,
                routes: [216_000_104, 200_000_015],
                title: dynamicSectionTitle(route: "7070/9090", stopID: suwonStopID)
            )
        case .other:
            if section == 0 {
                return BusRealtimeSectionInfo(
                    stopID: 216_000_759, routes: [216_000_075], title: String(localized: busRealtimeSection[section])
                )
            }
            return BusRealtimeSectionInfo(
                stopID: 213_000_487, routes: [216_000_075], title: String(localized: busRealtimeSection[section])
            )
        }
    }

    private func dynamicSectionTitle(route: String, stopID: Int32) -> String {
        String(format: String(localized: "bus.realtime.section.dynamic"), route, BusStopName.title(for: stopID))
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
        let info = sectionInfo(section)
        headerView.setupUI(
            title: info.title,
            showStopVC: { [weak self] in
                self?.showStopModal(info.stopID, routes: info.routes)
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
        let info = sectionInfo(section)
        footerView.setupUI(
            stopID: info.stopID,
            routes: info.routes,
            title: String.LocalizationValue(stringLiteral: info.title),
            showEntireTimetable: showEntireTimetable,
            showDepartureLog: showDepartureLog
        )
        return footerView
    }

    private func realtimeSubject(for section: Int) -> BehaviorSubject<[BusArrivalItem]>? {
        let data = BusRealtimeData.shared
        switch (tabType, section) {
        case (.city, 0): return data.busRealtimeCityFromCampus
        case (.city, 1): return data.busRealtimeCityFromStation
        case (.seoul, 0): return data.busRealtimeSeoulFromCampus
        case (.seoul, 1): return data.busRealtimeGunpoFromCampus
        case (.suwon, 0): return data.busRealtimeSuwonFromCampus
        case (.other, 0): return data.busRealtimeKTXFromCampus
        case (.other, 1): return data.busRealtimeKTXFromStation
        default: return nil
        }
    }

    private var realtimeRowLimit: Int { tabType == .suwon ? 10 : 5 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton { return section == 0 ? 3 : 2 }
        guard let subject = realtimeSubject(for: section), let items = try? subject.value() else { return 1 }
        return items.isEmpty ? 1 : min(items.count, realtimeRowLimit)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: BusRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let cell = tableView
            .dequeueReusableCell(withIdentifier: BusRealtimeCellView.reuseIdentifier, for: indexPath) as? BusRealtimeCellView
        else { fatalError("Unable to dequeue BusRealtimeCellView") }
        guard let subject = realtimeSubject(for: indexPath.section) else { return cell }
        guard let items = try? subject.value(), !items.isEmpty else { return BusRealtimeEmptyCellView() }
        cell.setupUI(item: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        50
    }
}

private struct BusRealtimeSectionInfo {
    let stopID: Int32
    let routes: [Int32]
    let title: String
}
