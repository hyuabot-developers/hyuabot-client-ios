//
//  ShuttleRealtimeTabVC.swift
//  hyuabot
//

// swiftlint:disable file_length

import Api
import RxSwift
import SnapKit
import UIKit

// swiftlint:disable:next type_body_length
class ShuttleRealtimeTabVC: UIViewController {
    private static let floatingStatusClearance: CGFloat = 28
    var forceShowBusAlternative = false
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
    private var routeHeights: [Int: CGFloat] = [:]
    private var hasAppliedTopInset = false
    private(set) var transferInfoView: ShuttleTransferInfoView?
    private var transferInfoViewsByIndexPath: [IndexPath: ShuttleTransferInfoView] = [:]
    private var transferInfoViewsByOrderSeq: [String: ShuttleTransferInfoView] = [:]
    private var expandedShuttleIndexPath: IndexPath?
    private var isAnimatingShuttleExpansion = false
    private var latestTransferData: ShuttleRealtimePageQuery.Data?
    private var busAlternatives: [String: [ShuttleBusAlternativeDisplayData]] = [:]
    private var busAlternativeLastNonEmptyAt: [String: Foundation.Date] = [:]
    private let busAlternativeEmptyGraceInterval: TimeInterval = 60
    private var activeBoardingAlarmKeys: Set<String> = []
    private var showsInitialSkeleton = true
    lazy var tableFooterView1 = ShuttleRealtimeTableFooterView(parentView: self.view)
    lazy var tableFooterView2 = ShuttleRealtimeTableFooterView2(
        parentView: self.view,
        stopID: self.stopID,
        showEntireTimetable: showEntireTimetable
    )
    private lazy var shuttleRealtimeTableView: UITableView = .init(frame: .zero, style: .grouped).then {
        $0.backgroundColor = SettingsStyle.Color.background
        $0.separatorStyle = .none
        $0.sectionHeaderTopPadding = 0
        $0.contentInsetAdjustmentBehavior = .never
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.refreshControl = destinationRefreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        $0.tableFooterView = self.tableFooterView1
        $0.rowHeight = ShuttleRealtimeCellView.informationRowHeight
        $0.estimatedRowHeight = ShuttleRealtimeCellView.informationRowHeight
        $0.showsVerticalScrollIndicator = false
        $0.contentInset.bottom = ShuttleRealtimeTabVC.floatingStatusClearance
        $0.verticalScrollIndicatorInsets.bottom = ShuttleRealtimeTabVC.floatingStatusClearance
        // Register the view
        $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
        $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
        $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeSkeletonCellView.self, forCellReuseIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
        $0.register(
            ShuttleExpandedTransferCellView.self,
            forCellReuseIdentifier: ShuttleExpandedTransferCellView.reuseIdentifier
        )
    }

    private lazy var shuttleRealtimeTableTimeView: UITableView = .init(frame: .zero, style: .grouped).then {
        $0.backgroundColor = SettingsStyle.Color.background
        $0.separatorStyle = .none
        $0.sectionHeaderTopPadding = 0
        $0.contentInsetAdjustmentBehavior = .never
        $0.delegate = self.timetableDelegate
        $0.dataSource = self.timetableDelegate
        $0.sectionHeaderTopPadding = 0
        $0.tableFooterView = self.tableFooterView2
        $0.rowHeight = ShuttleRealtimeCellView.informationRowHeight
        $0.estimatedRowHeight = ShuttleRealtimeCellView.informationRowHeight
        $0.refreshControl = timetableRefreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        $0.showsVerticalScrollIndicator = false
        $0.contentInset.bottom = ShuttleRealtimeTabVC.floatingStatusClearance
        $0.verticalScrollIndicatorInsets.bottom = ShuttleRealtimeTabVC.floatingStatusClearance
        // Register the view
        $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
        $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
        $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeSkeletonCellView.self, forCellReuseIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier)
        $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
        $0.register(
            ShuttleExpandedTransferCellView.self,
            forCellReuseIdentifier: ShuttleExpandedTransferCellView.reuseIdentifier
        )
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
        timetableDelegate.transferViewProvider = { [weak self] item in self?.orderTransferViews(for: item) ?? [] }
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
    }

    private var shouldShowTransferSection: Bool {
        stopID == .dormiotryOut || stopID == .shuttlecockOut
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
                latestTransferData = data
                for transferView in transferInfoViewsByIndexPath.values {
                    transferView.setup(data: data)
                }
                for transferView in transferInfoViewsByOrderSeq.values {
                    transferView.setup(data: data)
                }
                shuttleRealtimeTableTimeView.reloadData()
                UIView.performWithoutAnimation {
                    shuttleRealtimeTableView.reloadData()
                }
            }).disposed(by: disposeBag)
    }

    private func observeAlarmStateChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(boardingAlarmStateDidChange),
            name: .shuttleBoardingAlarmStateDidChange,
            object: nil
        )
    }

    @objc
    private func boardingAlarmStateDidChange() {
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

    private func mergeBusAlternatives(
        _ incoming: [String: [ShuttleBusAlternativeDisplayData]]
    ) -> [String: [ShuttleBusAlternativeDisplayData]] {
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
            let count = displayedBusAlternatives(from: alternatives, section: section).count
            if section == 0, canForceShowBusAlternative, count == 0 {
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
                let alternatives = self.displayedBusAlternatives(from: self.busAlternatives, section: section)
                let forceShow = section == 0 && self.canForceShowBusAlternative
                footerView.setupUI(
                    stopID: self.stopID,
                    section: section,
                    transferView: nil,
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

    private var canForceShowBusAlternative: Bool {
        forceShowBusAlternative && ShuttleTransferDisplaySettings.alternativeDisplayMode != .hidden
    }

    private func displayedBusAlternatives(
        from alternatives: [String: [ShuttleBusAlternativeDisplayData]],
        section: Int
    ) -> [ShuttleBusAlternativeDisplayData] {
        let values = alternatives[busAlternativeKey(section: section)] ?? []
        return ShuttleTransferDisplaySettings.alternativeDisplayMode == .hidden ? [] : values
    }

    private func destinationEntries(
        section: Int
    ) -> [ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry] {
        switch (stopID, section) {
        case (.dormiotryOut, 0):
            (try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value()) ?? []
        case (.dormiotryOut, 1):
            (try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value()) ?? []
        case (.dormiotryOut, 2):
            (try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value()) ?? []
        case (.shuttlecockOut, 0):
            (try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value()) ?? []
        case (.shuttlecockOut, 1):
            (try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value()) ?? []
        case (.shuttlecockOut, 2):
            (try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value()) ?? []
        case (.station, 0):
            (try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value()) ?? []
        case (.station, 1):
            (try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value()) ?? []
        case (.station, 2):
            (try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value()) ?? []
        case (.terminal, 0):
            (try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value()) ?? []
        case (.jungangStation, 0):
            (try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value()) ?? []
        case (.shuttlecockIn, 0):
            (try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value()) ?? []
        default:
            []
        }
    }

    private func transferDestination(section: Int) -> ShuttleTransferDestination? {
        switch section {
        case 0: .station
        case 1: .terminal
        case 2: .jungangStation
        default: nil
        }
    }

    private func orderTransferViews(
        for item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) -> [ShuttleTransferInfoView] {
        guard shouldShowTransferSection else { return [] }
        let stopNames = Set(item.stops.map(\.stop))
        let destinations: [ShuttleTransferDestination] = switch item.route.tag {
        case "DY" where stopNames.contains("terminal"): [.terminal]
        case "DJ": []
        default:
            [
                stopNames.contains("station") ? ShuttleTransferDestination.station : nil,
                stopNames.contains("terminal") ? ShuttleTransferDestination.terminal : nil
            ].compactMap { $0 }
        }
        return destinations.map { destination in
            let cacheKey = "\(item.seq)-\(destination)"
            let transferView: ShuttleTransferInfoView
            if let cached = transferInfoViewsByOrderSeq[cacheKey] {
                transferView = cached
            } else {
                transferView = ShuttleTransferInfoView(stopID: stopID, destination: destination, presentation: .inline)
                transferInfoViewsByOrderSeq[cacheKey] = transferView
            }
            transferView.selectShuttle(item)
            transferView.setup(data: latestTransferData)
            return transferView
        }
    }

    private func transferView(
        at indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) -> ShuttleTransferInfoView? {
        guard shouldShowTransferSection,
              let destination = transferDestination(section: indexPath.section)
        else { return nil }
        let transferView: ShuttleTransferInfoView
        if let cachedView = transferInfoViewsByIndexPath[indexPath] {
            transferView = cachedView
        } else {
            transferView = ShuttleTransferInfoView(
                stopID: stopID,
                destination: destination,
                presentation: .inline
            )
            transferInfoViewsByIndexPath[indexPath] = transferView
        }
        transferView.selectShuttle(item)
        transferView.setup(data: latestTransferData)
        if indexPath == IndexPath(row: 0, section: 0) {
            transferInfoView = transferView
        }
        return transferView
    }

    private func expandedDataRow(section: Int) -> Int? {
        guard let expandedShuttleIndexPath,
              expandedShuttleIndexPath.section == section
        else { return nil }
        let row = expandedShuttleIndexPath.row
        let entries = destinationEntries(section: section)
        return entries.indices.contains(row) ? row : nil
    }

    private func displayedRowCount(baseCount: Int, section: Int) -> Int {
        baseCount + (expandedDataRow(section: section) == nil ? 0 : 1)
    }

    private func isTransferExpansionRow(_ indexPath: IndexPath) -> Bool {
        guard let expandedRow = expandedDataRow(section: indexPath.section) else { return false }
        return indexPath.row == expandedRow + 1
    }

    private func dataIndexPath(for displayedIndexPath: IndexPath) -> IndexPath? {
        guard let expandedRow = expandedDataRow(section: displayedIndexPath.section) else {
            return displayedIndexPath
        }
        if displayedIndexPath.row == expandedRow + 1 {
            return nil
        }
        let row = displayedIndexPath.row > expandedRow + 1
            ? displayedIndexPath.row - 1
            : displayedIndexPath.row
        return IndexPath(row: row, section: displayedIndexPath.section)
    }

    private func toggleShuttleExpansion(at indexPath: IndexPath, selectedCell: ShuttleRealtimeCellView) {
        let previousIndexPath = expandedShuttleIndexPath
        let isCollapsing = previousIndexPath == indexPath
        let previousCell = previousIndexPath.flatMap {
            shuttleRealtimeTableView.cellForRow(at: $0) as? ShuttleRealtimeCellView
        }
        expandedShuttleIndexPath = isCollapsing ? nil : indexPath
        selectedCell.setExpanded(!isCollapsing)
        if previousCell !== selectedCell {
            previousCell?.setExpanded(false)
        }

        let deletedRow = previousIndexPath.map { IndexPath(row: $0.row + 1, section: $0.section) }
        let insertedRow = isCollapsing ? nil : IndexPath(row: indexPath.row + 1, section: indexPath.section)

        isAnimatingShuttleExpansion = true
        shuttleRealtimeTableView.performBatchUpdates {
            if let deletedRow {
                shuttleRealtimeTableView.deleteRows(at: [deletedRow], with: .fade)
            }
            if let insertedRow {
                shuttleRealtimeTableView.insertRows(at: [insertedRow], with: .fade)
            }
        } completion: { _ in
            self.isAnimatingShuttleExpansion = false
        }
    }

    var visibleTableView: UITableView {
        shuttleRealtimeTableView.isHidden ? shuttleRealtimeTableTimeView : shuttleRealtimeTableView
    }

    var firstSectionHeaderHelpView: UIView? {
        (visibleTableView.headerView(forSection: 0) as? ShuttleRealtimeHeaderView)?.routeToggleButton
    }

    func reload() {
        shuttleRealtimeTableView.reloadData()
        shuttleRealtimeTableTimeView.reloadData()
        destinationRefreshControl.endRefreshing()
        timetableRefreshControl.endRefreshing()
    }

    func reloadTransferDisplaySettings() {
        transferInfoViewsByIndexPath.values.forEach { $0.reloadDisplaySettings() }
        UIView.performWithoutAnimation {
            shuttleRealtimeTableView.reloadData()
            shuttleRealtimeTableTimeView.reloadData()
        }
    }

    func scrollToFooter() {
        shuttleRealtimeTableView.layoutIfNeeded()
        let table = shuttleRealtimeTableView
        let offset = max(
            -table.adjustedContentInset.top,
            table.contentSize.height + table.adjustedContentInset.bottom - table.bounds.height
        )
        shuttleRealtimeTableView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
        // Force UITableView to re-render visible section footers at the new scroll position
        shuttleRealtimeTableView.setNeedsLayout()
        shuttleRealtimeTableView.layoutIfNeeded()
    }

    var lastSectionFooterTimetableButton: UIView? {
        let sectionCount = shuttleRealtimeTableView.numberOfSections
        guard sectionCount > 0 else { return nil }
        return (shuttleRealtimeTableView.footerView(forSection: sectionCount - 1) as? ShuttleRealtimeFooterView)?.showEntireTimeTableButton
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
        let table = visibleTableView
        table.setContentOffset(CGPoint(x: 0, y: -table.adjustedContentInset.top), animated: false)
        table.layoutIfNeeded()
    }

    func scrollToDestination(_ destinationID: String) {
        let normalizedID = destinationID
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
        let section: Int? = switch normalizedID {
        case "station", "subway":
            shuttleRealtimeSection.firstIndex(of: "shuttle.desination.subway")
        case "terminal":
            shuttleRealtimeSection.firstIndex(of: "shuttle.desination.terminal")
        case "jungang", "jungang_stn", "jungang_station":
            shuttleRealtimeSection.firstIndex(of: "shuttle.desination.jungang_station")
        case "campus", "dormitory", "dormitory_i":
            shuttleRealtimeSection.firstIndex(of: "shuttle.desination.dormitory")
        default:
            nil
        }
        guard let section else { return }
        loadViewIfNeeded()
        view.layoutIfNeeded()
        for tableView in [shuttleRealtimeTableView, shuttleRealtimeTableTimeView] {
            tableView.layoutIfNeeded()
            guard tableView.numberOfSections > section else { continue }
            let headerRect = tableView.rectForHeader(inSection: section)
            guard !headerRect.isNull else { continue }
            let y = max(-tableView.adjustedContentInset.top, headerRect.minY - tableView.adjustedContentInset.top)
            tableView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
        }
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
        // swiftlint:disable opening_brace
        if let fallbackDestination = fallbackDestinationStop(
            stopID: stopID,
            routeName: routeName,
            departureDate: departureDate
        ),
            normalizedStops.dropFirst(boardingRouteStopIndex + 1).isEmpty
        {
            normalizedStops.append(fallbackDestination)
        }
        // swiftlint:enable opening_brace
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
            createdAt: Foundation.Date.now,
            chipKind: ShuttleDisplayLogic.routeChipKind(stopID: boardingStopID, destinationKey: nil, routeTag: routeTag)
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

    @objc
    private func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.shuttleRefresh)
        refreshMethod()
    }
}

private struct ShuttleAlarmRouteStop {
    let id: String
    let time: LocalTime
}

extension ShuttleRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    /// Insets are managed by the parent: `top` is the gap below the pinned header, `bottom` clears the floating tab bar.
    func setContentInsets(top: CGFloat, bottom: CGFloat) {
        for table in [shuttleRealtimeTableView, shuttleRealtimeTableTimeView] {
            let atTop = !hasAppliedTopInset || table.contentOffset.y + table.adjustedContentInset.top <= 12
            table.contentInset.top = top
            table.contentInset.bottom = bottom
            table.verticalScrollIndicatorInsets = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
            if atTop {
                table.contentOffset.y = -top
            }
        }
        hasAppliedTopInset = true
    }

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
        let alternatives = displayedBusAlternatives(from: busAlternatives, section: section)
        let forceShow = section == 0 && canForceShowBusAlternative
        footerView.setupUI(
            stopID: stopID,
            section: section,
            transferView: nil,
            busAlternatives: alternatives,
            forceShow: forceShow,
            showEntireTimetable: showEntireTimetable
        ) { [weak self] alternative in
            guard let self else { return }
            showBusAlternativeStop(stopID, alternative)
        }
        return footerView
    }

    private func dequeueRealtimeCell(_ tableView: UITableView, for indexPath: IndexPath) -> ShuttleRealtimeCellView {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
            for: indexPath
        ) as? ShuttleRealtimeCellView else {
            fatalError("Unable to dequeue ShuttleRealtimeCellView")
        }
        cell.showsTopSeparator = (dataIndexPath(for: indexPath)?.row ?? indexPath.row) > 0
        return cell
    }

    private enum RealtimeDataSource: Int {
        case dormitoryToStation
        case dormitoryToTerminal
        case dormitoryToJungangStation
        case shuttlecockToStation
        case shuttlecockToTerminal
        case shuttlecockToJungangStation
        case stationToCampus
        case stationToTerminal
        case stationToJungangStation
        case terminalToCampus
        case jungangStationToCampus
        case shuttlecockInToDormitory
    }

    private func realtimeDataSource(section: Int) -> RealtimeDataSource? {
        switch (stopID, section) {
        case (.dormiotryOut, 0): .dormitoryToStation
        case (.dormiotryOut, 1): .dormitoryToTerminal
        case (.dormiotryOut, 2): .dormitoryToJungangStation
        case (.shuttlecockOut, 0): .shuttlecockToStation
        case (.shuttlecockOut, 1): .shuttlecockToTerminal
        case (.shuttlecockOut, 2): .shuttlecockToJungangStation
        case (.station, 0): .stationToCampus
        case (.station, 1): .stationToTerminal
        case (.station, 2): .stationToJungangStation
        case (.terminal, _): .terminalToCampus
        case (.jungangStation, _): .jungangStationToCampus
        case (.shuttlecockIn, _): .shuttlecockInToDormitory
        default: nil
        }
    }

    private func realtimeDataCount(for source: RealtimeDataSource) -> (Int, Int)? {
        if source.rawValue <= RealtimeDataSource.stationToJungangStation.rawValue {
            return realtimeOutboundDataCount(for: source)
        }
        return realtimeInboundDataCount(for: source)
    }

    private func realtimeOutboundDataCount(for source: RealtimeDataSource) -> (Int, Int)? {
        switch source {
        case .dormitoryToStation:
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value() else { return nil }
            return (data.count, 3)
        case .dormitoryToTerminal:
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return nil }
            return (data.count, 3)
        case .dormitoryToJungangStation:
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value() else { return nil }
            return (data.count, 3)
        case .shuttlecockToStation:
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return nil }
            return (data.count, 3)
        case .shuttlecockToTerminal:
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return nil }
            return (data.count, 3)
        case .shuttlecockToJungangStation:
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value() else { return nil }
            return (data.count, 3)
        case .stationToCampus:
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return nil }
            return (data.count, 3)
        case .stationToTerminal:
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return nil }
            return (data.count, 3)
        case .stationToJungangStation:
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value() else { return nil }
            return (data.count, 3)
        default: return nil
        }
    }

    private func realtimeInboundDataCount(for source: RealtimeDataSource) -> (Int, Int)? {
        switch source {
        case .terminalToCampus:
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return nil }
            return (data.count, 7)
        case .jungangStationToCampus:
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return nil }
            return (data.count, 7)
        case .shuttlecockInToDormitory:
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return nil }
            return (data.count, 7)
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsInitialSkeleton {
            return skeletonRowCount(section: section)
        }
        guard let source = realtimeDataSource(section: section),
              let (dataCount, maximumCount) = realtimeDataCount(for: source) else { return 0 }
        return displayedRowCount(baseCount: max(min(dataCount, maximumCount), 1), section: section)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard shuttleRealtimeSection.indices.contains(indexPath.section) else { return UITableViewCell() }
        if showsInitialSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        if isTransferExpansionRow(indexPath), let expandedRow = expandedDataRow(section: indexPath.section) {
            let entries = destinationEntries(section: indexPath.section)
            guard entries.indices.contains(expandedRow),
                  let cell = tableView.dequeueReusableCell(
                      withIdentifier: ShuttleExpandedTransferCellView.reuseIdentifier,
                      for: indexPath
                  ) as? ShuttleExpandedTransferCellView else { return UITableViewCell() }
            let item = entries[expandedRow]
            let section = indexPath.section
            let direction = directionDisplayName(section: section)
            cell.setup(
                transferView: transferView(at: IndexPath(row: expandedRow, section: section), item: item),
                isAlarmActive: isBoardingAlarmActive(stopID: stopID, item: item, directionDisplayName: direction),
                onAlarm: { [weak self] in
                    guard let self,
                          let context = Self.makeAlarmContext(stopID: stopID, item: item, directionDisplayName: direction)
                    else { return }
                    showAlarmVC(stopID, context)
                },
                onStops: { [weak self] in self?.showViaVCByDestination(item) }
            )
            return cell
        }
        let displayedIndexPath = indexPath
        guard let indexPath = dataIndexPath(for: displayedIndexPath) else { return UITableViewCell() }
        if stopID == .dormiotryOut {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value()
                else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            }
        } else if stopID == .shuttlecockOut {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value()
                else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            }
        } else if stopID == .station {
            if indexPath.section == 0 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            } else if indexPath.section == 1 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value() else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            } else if indexPath.section == 2 {
                guard let data = try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value()
                else { return UITableViewCell() }
                if data.indices.contains(indexPath.row) {
                    let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                    )
                    return cell
                }
            }
        } else if stopID == .terminal {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
                let item = data[indexPath.row]
                let directionDisplayName = directionDisplayName(section: indexPath.section)
                cell.setupUI(
                    stopID: .terminal,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .terminal, item: item, directionDisplayName: directionDisplayName)
                )
                return cell
            }
        } else if stopID == .jungangStation {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                )
                return cell
            }
        } else if stopID == .shuttlecockIn {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value() else { return UITableViewCell() }
            if data.indices.contains(indexPath.row) {
                let cell = dequeueRealtimeCell(tableView, for: displayedIndexPath)
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
                )
                return cell
            }
        }
        return tableView.dequeueReusableCell(
            withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier,
            for: displayedIndexPath
        )
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard headerExpandedStates[section] == true else { return ShuttleRealtimeHeaderView.headerHeight }
        let header = tableView.headerView(forSection: section) as? ShuttleRealtimeHeaderView
        if let header, header.routeAdapterHeight > 0 {
            routeHeights[section] = header.routeAdapterHeight
        }
        return ShuttleRealtimeHeaderView.headerHeight + (routeHeights[section] ?? 0)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if showsInitialSkeleton {
            return CGFloat.leastNormalMagnitude
        }
        let alternativesCount = displayedBusAlternatives(from: busAlternatives, section: section).count
        let effectiveAlternativesCount = if alternativesCount > 0 {
            alternativesCount
        } else if section == 0, canForceShowBusAlternative {
            1
        } else {
            0
        }
        return ShuttleRealtimeFooterView.cardGap + ShuttleRealtimeFooterView.timetableButtonHeight
            + ShuttleRealtimeCellView.informationRowHeight * CGFloat(effectiveAlternativesCount)
    }

    static func emptyRowHeight(
        isShuttleRealtimeTable: Bool,
        showsInitialSkeleton: Bool,
        isTransferExpansionRow: Bool,
        hasDestinationEntries: Bool
    ) -> CGFloat? {
        guard isShuttleRealtimeTable, !showsInitialSkeleton, !isTransferExpansionRow, !hasDestinationEntries else {
            return nil
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // The empty-state row is a StateView, which needs more height than a 44pt information row.
        if let height = Self.emptyRowHeight(
            isShuttleRealtimeTable: tableView === shuttleRealtimeTableView,
            showsInitialSkeleton: showsInitialSkeleton,
            isTransferExpansionRow: isTransferExpansionRow(indexPath),
            hasDestinationEntries: !destinationEntries(section: indexPath.section).isEmpty
        ) {
            return height
        }
        guard tableView === shuttleRealtimeTableView,
              isTransferExpansionRow(indexPath),
              let expandedRow = expandedDataRow(section: indexPath.section)
        else { return ShuttleRealtimeCellView.informationRowHeight }
        let entries = destinationEntries(section: indexPath.section)
        guard entries.indices.contains(expandedRow) else {
            return ShuttleRealtimeCellView.informationRowHeight
        }
        let transferView = transferView(
            at: IndexPath(row: expandedRow, section: indexPath.section),
            item: entries[expandedRow]
        )
        return ShuttleExpandedTransferCellView.preferredHeight(transferView: transferView)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView === shuttleRealtimeTableView,
              let shuttleCell = cell as? ShuttleRealtimeCellView,
              let dataIndexPath = dataIndexPath(for: indexPath)
        else { return }
        shuttleCell.setExpanded(expandedShuttleIndexPath == dataIndexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let header = tableView.headerView(forSection: section) as? ShuttleRealtimeHeaderView else {
            return ShuttleRealtimeHeaderView.headerHeight
        }
        return header.isExpanded ? ShuttleRealtimeHeaderView.headerHeight + header.routeAdapterHeight : ShuttleRealtimeHeaderView
            .headerHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isTransferExpansionRow(indexPath),
              let dataIndexPath = dataIndexPath(for: indexPath),
              let cell = tableView.cellForRow(at: indexPath) as? ShuttleRealtimeCellView,
              cell.itemByDestination != nil
        else { return }
        if expandedShuttleIndexPath != dataIndexPath {
            AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
        }
        toggleShuttleExpansion(at: dataIndexPath, selectedCell: cell)
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
