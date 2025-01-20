import UIKit
import RxSwift
import QueryAPI

class SubwayRealtimeTabVC: UIViewController {
    private let tabType: SubwayTabType
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let refreshMethod: () -> ()
    private let subwayRealtimeSection: [String.LocalizationValue]
    private let showEntireTimetable: (String.LocalizationValue) -> ()
    private lazy var subwayRealtimeTableView: UITableView = {
        let tableView = UITableView().then {
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.estimatedRowHeight = 60
            $0.refreshControl = self.refreshControl
            $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
            $0.showsVerticalScrollIndicator = false
            // Register cell
            $0.register(SubwayRealtimeCellView.self, forCellReuseIdentifier: SubwayRealtimeCellView.reuseIdentifier)
            $0.register(SubwayRealtimeEmptyCellView.self, forCellReuseIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier)
            $0.register(SubwayRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: SubwayRealtimeHeaderView.reuseIdentifier)
            $0.register(SubwayRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: SubwayRealtimeFooterView.reuseIdentifier)
        }
        return tableView
    }()
    
    required init (
        tabType: SubwayTabType,
        refreshMethod: @escaping () -> (),
        showEntireTimetable: @escaping (String.LocalizationValue) -> ()
    ) {
        self.tabType = tabType
        self.refreshMethod = refreshMethod
        self.showEntireTimetable = showEntireTimetable
        switch tabType {
        case .line4: self.subwayRealtimeSection = [
            "subway.realtime.section.4.up",
            "subway.realtime.section.4.down"
        ]
        case .lineSuin: self.subwayRealtimeSection = [
            "subway.realtime.section.suin.up",
            "subway.realtime.section.suin.down"
        ]
        case .transfer: self.subwayRealtimeSection = [
            "subway.realtime.section.transfer.up",
            "subway.realtime.section.transfer.down"
        ]}
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.addSubview(self.subwayRealtimeTableView)
        self.subwayRealtimeTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func reload() {
        self.subwayRealtimeTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    @objc func refreshTableView(_ sender: UIRefreshControl) {
        self.refreshMethod()
    }
}

extension SubwayRealtimeTabVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.subwayRealtimeSection.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SubwayRealtimeHeaderView.reuseIdentifier) as? SubwayRealtimeHeaderView else { return UIView() }
        headerView.setupUI(title: String(localized: self.subwayRealtimeSection[section]))
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SubwayRealtimeFooterView.reuseIdentifier) as? SubwayRealtimeFooterView else { return UIView() }
        footerView.setupUI(
            tabType: self.tabType,
            showEntireTimetable: {
                self.showEntireTimetable(self.subwayRealtimeSection[section])
            }
        )
        return footerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.tabType == .line4) {
            if (section == 0) {
                guard let items = try? SubwayRealtimeData.shared.line4Up.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 6)
            } else if (section == 1) {
                guard let items = try? SubwayRealtimeData.shared.line4Down.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 6)
            }
        } else if (self.tabType == .lineSuin) {
            if (section == 0) {
                guard let items = try? SubwayRealtimeData.shared.lineSuinUp.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 6)
            } else if (section == 1) {
                guard let items = try? SubwayRealtimeData.shared.lineSuinDown.value() else { return 1 }
                return items.isEmpty ? 1 : min(items.count, 6)
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeCellView.reuseIdentifier) as? SubwayRealtimeCellView else { return UITableViewCell() }
        if (self.tabType == .line4) {
            if (indexPath.section == 0) {
                guard let items = try? SubwayRealtimeData.shared.line4Up.value() else { return UITableViewCell() }
                if (items.isEmpty) {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier) as? SubwayRealtimeEmptyCellView else { return UITableViewCell() }
                    return cell
                }
                cell.setupUI(tabType: self.tabType, item: items[indexPath.row])
            } else if (indexPath.section == 1) {
                guard let items = try? SubwayRealtimeData.shared.line4Down.value() else { return UITableViewCell() }
                if (items.isEmpty) {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier) as? SubwayRealtimeEmptyCellView else { return UITableViewCell() }
                    return cell
                }
                cell.setupUI(tabType: self.tabType, item: items[indexPath.row])
            }
        } else if (self.tabType == .lineSuin) {
            if (indexPath.section == 0) {
                guard let items = try? SubwayRealtimeData.shared.lineSuinUp.value() else { return UITableViewCell() }
                if (items.isEmpty) {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier) as? SubwayRealtimeEmptyCellView else { return UITableViewCell() }
                    return cell
                }
                cell.setupUI(tabType: self.tabType, item: items[indexPath.row])
            } else if (indexPath.section == 1) {
                guard let items = try? SubwayRealtimeData.shared.lineSuinDown.value() else { return UITableViewCell() }
                if (items.isEmpty) {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayRealtimeEmptyCellView.reuseIdentifier) as? SubwayRealtimeEmptyCellView else { return UITableViewCell() }
                    return cell
                }
                cell.setupUI(tabType: self.tabType, item: items[indexPath.row])
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
}
