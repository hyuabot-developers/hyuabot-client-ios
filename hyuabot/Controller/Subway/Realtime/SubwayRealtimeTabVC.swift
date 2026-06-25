import Api
import RxSwift
import UIKit

class SubwayRealtimeTabVC: UIViewController {
    private let tabType: SubwayTabType
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let refreshMethod: () -> Void
    private let subwayRealtimeSection: [String.LocalizationValue]
    private let showEntireTimetable: (String.LocalizationValue, SubwayHeadingEnum) -> Void
    private var showsSkeleton = true
    private lazy var subwayRealtimeTableView: UITableView = .init().then {
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.estimatedRowHeight = 60
        $0.refreshControl = self.refreshControl
        $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
        $0.showsVerticalScrollIndicator = false
        // Register cell
        $0.register(SubwayRealtimeCellView.self, forCellReuseIdentifier: SubwayRealtimeCellView.reuseIdentifier)
        $0.register(SubwayTransferCellView.self, forCellReuseIdentifier: SubwayTransferCellView.reuseIdentifier)
        $0.register(SubwayRealtimeEmptyCellView.self, forCellReuseIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier)
        $0.register(SubwayRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: SubwayRealtimeHeaderView.reuseIdentifier)
        $0.register(SubwayRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: SubwayRealtimeFooterView.reuseIdentifier)
        $0.register(SubwayRealtimeSkeletonCellView.self, forCellReuseIdentifier: SubwayRealtimeSkeletonCellView.reuseIdentifier)
        $0.register(
            SubwayRealtimeSkeletonHeaderView.self,
            forHeaderFooterViewReuseIdentifier: SubwayRealtimeSkeletonHeaderView.reuseIdentifier
        )
        $0.register(
            SubwayRealtimeSkeletonFooterView.self,
            forHeaderFooterViewReuseIdentifier: SubwayRealtimeSkeletonFooterView.reuseIdentifier
        )
    }

    required init(
        tabType: SubwayTabType,
        refreshMethod: @escaping () -> Void,
        showEntireTimetable: @escaping (String.LocalizationValue, SubwayHeadingEnum) -> Void
    ) {
        self.tabType = tabType
        self.refreshMethod = refreshMethod
        self.showEntireTimetable = showEntireTimetable
        switch tabType {
        case .line4: subwayRealtimeSection = [
                "subway.realtime.section.4.up",
                "subway.realtime.section.4.down"
            ]
        case .lineSuin: subwayRealtimeSection = [
                "subway.realtime.section.suin.up",
                "subway.realtime.section.suin.down"
            ]
        case .transfer: subwayRealtimeSection = [
                "subway.realtime.section.transfer.up",
                "subway.realtime.section.transfer.down"
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
        view.addSubview(subwayRealtimeTableView)
        subwayRealtimeTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func reload() {
        subwayRealtimeTableView.reloadData()
        refreshControl.endRefreshing()
    }

    private func observeSubjects() {
        SubwayRealtimeData.shared.isLoading
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.showsSkeleton = isLoading
                self?.reload()
            })
            .disposed(by: disposeBag)
    }

    @objc func refreshTableView(_ sender: UIRefreshControl) {
        AnalyticsManager.logSelect(.subwayRefresh)
        refreshMethod()
    }
}

extension SubwayRealtimeTabVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        subwayRealtimeSection.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if showsSkeleton {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: SubwayRealtimeSkeletonHeaderView.reuseIdentifier)
        }
        guard let headerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: SubwayRealtimeHeaderView.reuseIdentifier) as? SubwayRealtimeHeaderView
        else { return UIView() }
        guard subwayRealtimeSection.indices.contains(section) else { return UIView() }
        headerView.setupUI(title: String(localized: subwayRealtimeSection[section]))
        return headerView
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if showsSkeleton {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: SubwayRealtimeSkeletonFooterView.reuseIdentifier)
        }
        guard let footerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: SubwayRealtimeFooterView.reuseIdentifier) as? SubwayRealtimeFooterView
        else { return UIView() }
        guard subwayRealtimeSection.indices.contains(section) else { return UIView() }
        footerView.setupUI(
            tabType: tabType,
            showEntireTimetable: {
                self.showEntireTimetable(
                    self.subwayRealtimeSection[section],
                    section == 0 ? .up : .down
                )
            }
        )
        return footerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return section == 0 ? 3 : 2
        }
        guard let data = try? SubwayRealtimeData.shared.combinedRealtimeData.value() else { return 1 }
        guard let campusBlue = data.campusBlue, let campusYellow = data.campusYellow else { return 1 }
        if tabType == .line4 {
            if section == 0 {
                let arrivals = campusBlue.arrival.first(where: { $0.direction == "up" })?.entries ?? []
                return arrivals.isEmpty ? 1 : arrivals.count
            } else if section == 1 {
                let arrivals = campusBlue.arrival.first(where: { $0.direction == "down" })?.entries ?? []
                return arrivals.isEmpty ? 1 : arrivals.count
            }
        } else if tabType == .lineSuin {
            if section == 0 {
                let arrivals = campusYellow.arrival.first(where: { $0.direction == "up" })?.entries ?? []
                return arrivals.isEmpty ? 1 : arrivals.count
            } else if section == 1 {
                let arrivals = campusYellow.arrival.first(where: { $0.direction == "down" })?.entries ?? []
                return arrivals.isEmpty ? 1 : arrivals.count
            }
        } else if tabType == .transfer {
            if section == 0 {
                guard let items = try? SubwayRealtimeData.shared.transferUp.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 6)
            } else if section == 1 {
                guard let items = try? SubwayRealtimeData.shared.transferDown.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 6)
            }
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard subwayRealtimeSection.indices.contains(indexPath.section) else { return UITableViewCell() }
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeCellView.reuseIdentifier) as? SubwayRealtimeCellView
        else { return UITableViewCell() }
        guard let data = try? SubwayRealtimeData.shared.combinedRealtimeData.value() else { return UITableViewCell() }
        guard let campusBlue = data.campusBlue, let campusYellow = data.campusYellow else { return UITableViewCell() }
        if tabType == .line4 {
            if indexPath.section == 0 {
                let arrivals = campusBlue.arrival.first(where: { $0.direction == "up" })?.entries ?? []
                guard arrivals.indices.contains(indexPath.row) else { return emptyCell(tableView) }
                cell.setupUI(tabType: tabType, item: arrivals[indexPath.row])
            } else if indexPath.section == 1 {
                let arrivals = campusBlue.arrival.first(where: { $0.direction == "down" })?.entries ?? []
                guard arrivals.indices.contains(indexPath.row) else { return emptyCell(tableView) }
                cell.setupUI(tabType: tabType, item: arrivals[indexPath.row])
            }
        } else if tabType == .lineSuin {
            if indexPath.section == 0 {
                let arrivals = campusYellow.arrival.first(where: { $0.direction == "up" })?.entries ?? []
                guard arrivals.indices.contains(indexPath.row) else { return emptyCell(tableView) }
                cell.setupUI(tabType: tabType, item: arrivals[indexPath.row])
            } else if indexPath.section == 1 {
                let arrivals = campusYellow.arrival.first(where: { $0.direction == "down" })?.entries ?? []
                guard arrivals.indices.contains(indexPath.row) else { return emptyCell(tableView) }
                cell.setupUI(tabType: tabType, item: arrivals[indexPath.row])
            }
        } else if tabType == .transfer {
            guard let transferCell = tableView
                .dequeueReusableCell(withIdentifier: SubwayTransferCellView.reuseIdentifier) as? SubwayTransferCellView
            else { return UITableViewCell() }
            if indexPath.section == 0 {
                guard let items = try? SubwayRealtimeData.shared.transferUp.value() else { return UITableViewCell() }
                guard items.indices.contains(indexPath.row), indexPath.row < 6 else { return emptyCell(tableView) }
                transferCell.setupUI(item: items[indexPath.row], direction: "up")
            } else if indexPath.section == 1 {
                guard let items = try? SubwayRealtimeData.shared.transferDown.value() else { return UITableViewCell() }
                guard items.indices.contains(indexPath.row), indexPath.row < 6 else { return emptyCell(tableView) }
                transferCell.setupUI(item: items[indexPath.row], direction: "down")
            }
            return transferCell
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        50
    }

    private func emptyCell(_ tableView: UITableView) -> UITableViewCell {
        tableView
            .dequeueReusableCell(withIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier) as? SubwayRealtimeEmptyCellView ??
            UITableViewCell()
    }
}
