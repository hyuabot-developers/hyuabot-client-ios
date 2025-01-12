import UIKit

class ShuttleTimetableTabVC: UIViewController {
    private let isWeekdays: Bool
    private lazy var shuttleTimetableTableView: UITableView = {
        let tableView = UITableView().then {
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.showsVerticalScrollIndicator = false
            $0.register(ShuttleTimetableCellView.self, forCellReuseIdentifier: ShuttleTimetableCellView.reuseIdentifier)
            $0.register(ShuttleTimetableEmptyCellView.self, forCellReuseIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier)
        }
        return tableView
    }()
    
    init(isWeekdays: Bool) {
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
        self.view.addSubview(self.shuttleTimetableTableView)
        self.shuttleTimetableTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func reload() {
        self.shuttleTimetableTableView.reloadData()
    }
}

extension ShuttleTimetableTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.isWeekdays) {
            guard let items = try? ShuttleTimetableData.shared.weekdays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        } else {
            guard let items = try? ShuttleTimetableData.shared.weekends.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let options = try? ShuttleTimetableData.shared.options.value() else { return UITableViewCell() }
        if (self.isWeekdays) {
            guard let items = try? ShuttleTimetableData.shared.weekdays.value() else { return UITableViewCell() }
            if (items.isEmpty != true) {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableCellView.reuseIdentifier, for: indexPath) as! ShuttleTimetableCellView
                cell.setupUI(option: options, item: items[indexPath.row])
                return cell
            }
        } else if (!self.isWeekdays) {
            guard let items = try? ShuttleTimetableData.shared.weekends.value() else { return UITableViewCell() }
            if (items.isEmpty != true) {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableCellView.reuseIdentifier, for: indexPath) as! ShuttleTimetableCellView
                cell.setupUI(option: options, item: items[indexPath.row])
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier, for: indexPath) as! ShuttleTimetableEmptyCellView
    }
}

