import UIKit

class BusTimetableTabVC: UIViewController {
    let timetableEnum: BusTimetableEnum
    private lazy var busTimetableView: UITableView = {
        let tableView = UITableView().then {
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.showsVerticalScrollIndicator = false
            $0.register(BusTimetableCellView.self, forCellReuseIdentifier: BusTimetableCellView.reuseIdentifier)
            $0.register(BusTimetableEmptyCellView.self, forCellReuseIdentifier: BusTimetableEmptyCellView.reuseIdentifier)
        }
        return tableView
    }()
    
    init(timetableEnum: BusTimetableEnum) {
        self.timetableEnum = timetableEnum
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
        self.view.addSubview(self.busTimetableView)
        self.busTimetableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func reload() {
        self.busTimetableView.reloadData()
    }
}

extension BusTimetableTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.timetableEnum == .weekdays) {
            guard let items = try? BusTimetableData.shared.weekdays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        } else if (self.timetableEnum == .saturdays) {
            guard let items = try? BusTimetableData.shared.saturdays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        } else if (self.timetableEnum == .sundays) {
            guard let items = try? BusTimetableData.shared.sundays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (self.timetableEnum == .weekdays) {
            guard let items = try? BusTimetableData.shared.weekdays.value() else { return BusTimetableEmptyCellView() }
            if (!items.isEmpty) {
                let cell = tableView.dequeueReusableCell(withIdentifier: BusTimetableCellView.reuseIdentifier) as? BusTimetableCellView ?? BusTimetableCellView()
                cell.setupUI(item: items[indexPath.row])
                return cell
            }
        } else if (self.timetableEnum == .saturdays) {
            guard let items = try? BusTimetableData.shared.saturdays.value() else { return BusTimetableEmptyCellView() }
            if (!items.isEmpty) {
                let cell = tableView.dequeueReusableCell(withIdentifier: BusTimetableCellView.reuseIdentifier) as? BusTimetableCellView ?? BusTimetableCellView()
                cell.setupUI(item: items[indexPath.row])
                return cell
            }
        } else if (self.timetableEnum == .sundays) {
            guard let items = try? BusTimetableData.shared.sundays.value() else { return BusTimetableEmptyCellView() }
            if (!items.isEmpty) {
                let cell = tableView.dequeueReusableCell(withIdentifier: BusTimetableCellView.reuseIdentifier) as? BusTimetableCellView ?? BusTimetableCellView()
                cell.setupUI(item: items[indexPath.row])
                return cell
            }
        }
        return BusTimetableCellView()
    }
}
