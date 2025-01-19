import UIKit
import RxSwift
import QueryAPI

class CafeteriaTabVC: UIViewController {
    private let cafeteriaType: CafeteriaType
    private let showCafeteriaInfoVC: (Int) -> Void
    private lazy var cafeteriaTableViwew: UITableView = {
        let tableView = UITableView().then {
            $0.delegate = self
            $0.dataSource = self
            $0.sectionHeaderTopPadding = 0
            $0.showsVerticalScrollIndicator = false
            // Register Cell
            $0.register(CafeteriaHeaderView.self, forHeaderFooterViewReuseIdentifier: CafeteriaHeaderView.reuseIdentifier)
            $0.register(CafeteriaMenuCellView.self, forCellReuseIdentifier: CafeteriaMenuCellView.reuseIdentifier)
        }
        return tableView
    }()
    
    required init(cafeteriaType: CafeteriaType, showCafeteriaInfoVC: @escaping (Int) -> Void) {
        self.cafeteriaType = cafeteriaType
        self.showCafeteriaInfoVC = showCafeteriaInfoVC
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
        self.view.addSubview(self.cafeteriaTableViwew)
        self.cafeteriaTableViwew.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func showCafeteriaInfoVC(cafeteriaID: Int) {
        self.showCafeteriaInfoVC(cafeteriaID)
    }
    
    func reload() { self.cafeteriaTableViwew.reloadData() }
}

extension CafeteriaTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if (self.cafeteriaType == .breakfast) {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return 0 }
            return cafeteriaItems.count
        } else if (self.cafeteriaType == .lunch) {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return 0 }
            return cafeteriaItems.count
        } else if (self.cafeteriaType == .dinner) {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return 0 }
            return cafeteriaItems.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CafeteriaHeaderView.reuseIdentifier) as? CafeteriaHeaderView else { return UIView() }
        if (self.cafeteriaType == .breakfast) {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return UIView() }
            let item = cafeteriaItems[section]
            headerView.setupUI(title: item.name, runningTime: item.runningTime, showCafeteriaInfoVC: { [weak self] in
                self?.showCafeteriaInfoVC(cafeteriaID: item.id)
            })
        } else if (self.cafeteriaType == .lunch) {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return UIView() }
            let item = cafeteriaItems[section]
            headerView.setupUI(title: item.name, runningTime: item.runningTime, showCafeteriaInfoVC: { [weak self] in
                self?.showCafeteriaInfoVC(cafeteriaID: item.id)
            })
        } else if (self.cafeteriaType == .dinner) {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return UIView() }
            let item = cafeteriaItems[section]
            headerView.setupUI(title: item.name, runningTime: item.runningTime, showCafeteriaInfoVC: { [weak self] in
                self?.showCafeteriaInfoVC(cafeteriaID: item.id)
            })
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.cafeteriaType == .breakfast) {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return 0 }
            return cafeteriaItems[section].menu.count
        } else if (self.cafeteriaType == .lunch) {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return 0 }
            return cafeteriaItems[section].menu.count
        } else if (self.cafeteriaType == .dinner) {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return 0 }
            return cafeteriaItems[section].menu.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CafeteriaMenuCellView.reuseIdentifier) as? CafeteriaMenuCellView else { return UITableViewCell() }
        if (self.cafeteriaType == .breakfast) {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return UITableViewCell() }
            let item = cafeteriaItems[indexPath.section].menu[indexPath.row]
            cell.setupUI(item: item)
        } else if (self.cafeteriaType == .lunch) {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return UITableViewCell() }
            let item = cafeteriaItems[indexPath.section].menu[indexPath.row]
            cell.setupUI(item: item)
        } else if (self.cafeteriaType == .dinner) {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return UITableViewCell() }
            let item = cafeteriaItems[indexPath.section].menu[indexPath.row]
            cell.setupUI(item: item)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
