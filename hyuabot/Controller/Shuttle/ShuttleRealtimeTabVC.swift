import UIKit
import RxSwift

class ShuttleRealtimeTabVC: UIViewController {
    let stopID: ShuttleStopEnum
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let shuttleRealtimeSection: [String.LocalizationValue]
    private let refreshMethod: () -> Void
    private lazy var shuttleRealtimeTableView: UITableView = {
        let tableView = UITableView().then{
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.refreshControl = refreshControl
            $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
            // Register the view
            $0.register(ShuttleRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier)
            $0.register(ShuttleRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: ShuttleRealtimeFooterView.reuseIdentifier)
            $0.register(ShuttleRealtimeEmptyCellView.self, forCellReuseIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier)
            $0.register(ShuttleRealtimeCellView.self, forCellReuseIdentifier: ShuttleRealtimeCellView.reuseIdentifier)
        }
        return tableView
    }()
    
    required init(stopID: ShuttleStopEnum, refreshMethod: @escaping () -> Void) {
        self.stopID = stopID
        if (self.stopID == .dormiotryOut || self.stopID == .shuttlecockOut) {
            self.shuttleRealtimeSection = ["shuttle.desination.subway", "shuttle.desination.terminal", "shuttle.desination.jungang_station"]
        } else if (self.stopID == .station) {
            self.shuttleRealtimeSection = ["shuttle.desination.dormitory", "shuttle.desination.terminal", "shuttle.desination.jungang_station"]
        } else {
            self.shuttleRealtimeSection = ["shuttle.desination.dormitory"]
        }
        self.refreshMethod = refreshMethod
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.addSubview(self.shuttleRealtimeTableView)
        self.shuttleRealtimeTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func reload() {
        self.shuttleRealtimeTableView.reloadData()
        self.refreshControl.endRefreshing()
    }

    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        self.refreshMethod()
    }
}

extension ShuttleRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.shuttleRealtimeSection.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeHeaderView.reuseIdentifier) as? ShuttleRealtimeHeaderView else { return UIView() }
        headerView.setupUI(title: String(localized: self.shuttleRealtimeSection[section]))
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShuttleRealtimeFooterView.reuseIdentifier) as? ShuttleRealtimeFooterView else { return UIView() }
        footerView.setupUI(stopID: "", destination: "")
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
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToDormitoryData.value() else { return 0 }
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
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockToDormitoryData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .shuttlecockIn, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
}
