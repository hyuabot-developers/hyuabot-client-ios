import UIKit
import RxSwift
import QueryAPI

class BusRealtimeTabVC: UIViewController {
    let tabType: BusRealtimeType
    private let disposeBag = DisposeBag()
    private let refreshControl = UIRefreshControl()
    private let refreshMethod: () -> Void
    private let busRealtimeSection: [String.LocalizationValue]
    private let showEntireTimetable: (Int, Int) -> ()
    private let showStopVC: (Int) -> ()
    private lazy var busRealtimeTableView: UITableView = {
        let tableView = UITableView().then {
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.refreshControl = refreshControl
            $0.refreshControl?.addTarget(self, action: #selector(refreshTableView(_:)), for: .valueChanged)
            $0.showsVerticalScrollIndicator = false
            // Register cells
            $0.register(BusRealtimeCellView.self, forCellReuseIdentifier: BusRealtimeCellView.reuseIdentifier)
            $0.register(BusRealtimeHeaderView.self, forHeaderFooterViewReuseIdentifier: BusRealtimeHeaderView.reuseIdentifier)
            $0.register(BusRealtimeFooterView.self, forHeaderFooterViewReuseIdentifier: BusRealtimeFooterView.reuseIdentifier)
            $0.register(BusRealtimeEmptyCellView.self, forCellReuseIdentifier: BusRealtimeEmptyCellView.reuseIdentifier)
        }
        return tableView
    }()
    
    required init (
        tabType: BusRealtimeType,
        refreshMethod: @escaping () -> (),
        showEntireTimetable: @escaping (Int, Int) -> (),
        showStopVC: @escaping (Int) -> ()
    ) {
        self.tabType = tabType
        self.refreshMethod = refreshMethod
        self.showEntireTimetable = showEntireTimetable
        self.showStopVC = showStopVC
        switch tabType {
            case .city: self.busRealtimeSection = [
                "bus.realtime.section.10-1.campus",
                "bus.realtime.section.10-1.station"
            ]
            case .seoul: self.busRealtimeSection = [
                "bus.realtime.section.3102",
                "bus.realtime.section.seoul.other"
            ]
            case .suwon: self.busRealtimeSection = [
                "bus.realtime.section.707-1",
                "bus.realtime.section.suwon.other"
            ]
            case .other: self.busRealtimeSection = [
                "bus.realtime.section.50.ansan",
                "bus.realtime.section.50.station"
            ]
        }
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
        self.view.addSubview(self.busRealtimeTableView)
        self.busRealtimeTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func showStopModal(_ stopID: Int) {
        self.showStopVC(stopID)
    }
    
    func reload() {
        self.busRealtimeTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    @objc private func refreshTableView(_ sender: UIRefreshControl) {
        self.refreshMethod()
    }
}

extension BusRealtimeTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.busRealtimeSection.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BusRealtimeHeaderView.reuseIdentifier) as? BusRealtimeHeaderView else {
            return UIView()
        }
        headerView.setupUI(title: String(localized: self.busRealtimeSection[section]))
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: BusRealtimeFooterView.reuseIdentifier) as? BusRealtimeFooterView else {
            return UIView()
        }
        return footerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
}
