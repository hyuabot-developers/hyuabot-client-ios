import UIKit

class SubwayTimetableTabVC: UIViewController {
    let heading: SubwayHeadingEnum
    let isWeekdays: Bool
    private lazy var subwayTimetableTableView: UITableView = {
        let tableView = UITableView().then {
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.showsVerticalScrollIndicator = false
            $0.register(SubwayTimetableCellView.self, forCellReuseIdentifier: SubwayTimetableCellView.reuseIdentifier)
        }
        return tableView
    }()
    
    init(heading: SubwayHeadingEnum, isWeekdays: Bool) {
        self.heading = heading
        self.isWeekdays = isWeekdays
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
        self.view.addSubview(self.subwayTimetableTableView)
        self.subwayTimetableTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func reload() { self.subwayTimetableTableView.reloadData() }
}


extension SubwayTimetableTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.isWeekdays) {
            if (self.heading == .up) {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableUpWeekdays.value() else { return 0 }
                return items.count
            } else {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableDownWeekdays.value() else { return 0 }
                return items.count
            }
        } else {
            if (self.heading == .up) {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableUpWeekends.value() else { return 0 }
                return items.count
            } else {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableDownWeekends.value() else { return 0 }
                return items.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SubwayTimetableCellView.reuseIdentifier) as? SubwayTimetableCellView else { return SubwayTimetableCellView() }
        if (self.isWeekdays) {
            if (self.heading == .up) {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableUpWeekdays.value() else { return cell }
                cell.setupUI(up: items[indexPath.row])
            } else {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableDownWeekdays.value() else { return cell }
                cell.setupUI(down: items[indexPath.row])
            }
        } else {
            if (self.heading == .up) {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableUpWeekends.value() else { return cell }
                cell.setupUI(up: items[indexPath.row])
            } else {
                guard let items = try? SubwayTimetableData.shared.subwayTimetableDownWeekends.value() else { return cell }
                cell.setupUI(down: items[indexPath.row])
            }
        }
        return cell
    }
}
