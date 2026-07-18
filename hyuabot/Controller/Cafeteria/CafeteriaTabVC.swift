import Api
import RxSwift
import UIKit

class CafeteriaTabVC: UIViewController {
    private let disposeBag = DisposeBag()
    private let cafeteriaType: CafeteriaType
    private let showCafeteriaInfoVC: @MainActor (Int) -> Void
    private var showsSkeleton = true
    private let noDataLabel = UILabel().then {
        $0.text = String(localized: "cafeteria.no.data")
        $0.font = .godo(size: 18, weight: .regular)
        $0.textColor = .label
        $0.textAlignment = .center
    }

    private lazy var cafeteriaTableView: UITableView = .init().then {
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.showsVerticalScrollIndicator = false
        $0.contentInset.bottom = 88
        $0.verticalScrollIndicatorInsets.bottom = 88
        // Register Cell
        $0.register(CafeteriaHeaderView.self, forHeaderFooterViewReuseIdentifier: CafeteriaHeaderView.reuseIdentifier)
        $0.register(CafeteriaSkeletonHeaderView.self, forHeaderFooterViewReuseIdentifier: CafeteriaSkeletonHeaderView.reuseIdentifier)
        $0.register(CafeteriaMenuCellView.self, forCellReuseIdentifier: CafeteriaMenuCellView.reuseIdentifier)
        $0.register(CafeteriaSkeletonCellView.self, forCellReuseIdentifier: CafeteriaSkeletonCellView.reuseIdentifier)
    }

    required init(cafeteriaType: CafeteriaType, showCafeteriaInfoVC: @escaping @MainActor (Int) -> Void) {
        self.cafeteriaType = cafeteriaType
        self.showCafeteriaInfoVC = showCafeteriaInfoVC
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
        view.addSubview(cafeteriaTableView)
        view.addSubview(noDataLabel)
        cafeteriaTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        noDataLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func showCafeteriaInfoVC(cafeteriaID: Int) {
        showCafeteriaInfoVC(cafeteriaID)
    }

    private func observeSubjects() {
        CafeteriaData.shared.isLoading
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.showsSkeleton = isLoading
                self?.reload()
            })
            .disposed(by: disposeBag)
    }

    private func languageFilteredMenus(
        _ menus: [CafeteriaPageQuery.Data.Cafeterium.Menu],
        type: String
    ) -> [CafeteriaPageQuery.Data.Cafeterium.Menu] {
        menus.filter { $0.type.contains(type) }
    }

    private var cafeteriaItems: [CafeteriaPageQuery.Data.Cafeterium] {
        switch cafeteriaType {
        case .breakfast:
            (try? CafeteriaData.shared.breakfastItems.value()) ?? []
        case .lunch:
            (try? CafeteriaData.shared.lunchItems.value()) ?? []
        case .dinner:
            (try? CafeteriaData.shared.dinnerItems.value()) ?? []
        }
    }

    private var mealTypeQuery: String {
        switch cafeteriaType {
        case .breakfast:
            "조식"
        case .lunch:
            "중식"
        case .dinner:
            "석식"
        }
    }

    private var mealTypeLabel: String {
        switch cafeteriaType {
        case .breakfast:
            String(localized: "cafeteria.tab.breakfast")
        case .lunch:
            String(localized: "cafeteria.tab.lunch")
        case .dinner:
            String(localized: "cafeteria.tab.dinner")
        }
    }

    private func cafeteriaTitle(id: Int) -> String {
        switch id {
        case 1:
            String(localized: "cafeteria.title.1")
        case 2:
            String(localized: "cafeteria.title.2")
        case 4:
            String(localized: "cafeteria.title.4")
        case 6:
            String(localized: "cafeteria.title.6")
        case 7:
            String(localized: "cafeteria.title.7")
        case 8:
            String(localized: "cafeteria.title.8")
        case 11:
            String(localized: "cafeteria.title.11")
        case 12:
            String(localized: "cafeteria.title.12")
        case 13:
            String(localized: "cafeteria.title.13")
        case 14:
            String(localized: "cafeteria.title.14")
        case 15:
            String(localized: "cafeteria.title.15")
        default:
            String(localized: "cafeteria.title.1")
        }
    }

    private func shareMenuName(_ food: String) -> String {
        var name = food
        [
            #"^\s*\[[^\]]+\]\s*"#,
            #"^\s*<[^>]+>\s*"#,
            #"^\s*[\w가-힣]+\)\s*"#
        ].forEach {
            name = name.replacingOccurrences(of: $0, with: "", options: .regularExpression)
        }

        name = name
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "“", with: "")
            .replacingOccurrences(of: "”", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? ""
    }

    private func sharePrice(_ price: String) -> String? {
        let trimmedPrice = price
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedPrice.isEmpty {
            return nil
        }

        return trimmedPrice.hasSuffix("원") ? trimmedPrice : "\(trimmedPrice)원"
    }

    func shareText() -> String? {
        let entries = cafeteriaItems.compactMap { cafeteria -> String? in
            var seenFoods = Set<String>()
            let menus = languageFilteredMenus(cafeteria.menus, type: mealTypeQuery).filter { menu in
                seenFoods.insert(menu.food).inserted
            }

            let menuLines = menus.compactMap { menu -> String? in
                let name = shareMenuName(menu.food)
                if name.isEmpty {
                    return nil
                }

                if let price = sharePrice(menu.price) {
                    return "- \(name) / \(price)"
                }

                return "- \(name)"
            }

            if menuLines.isEmpty {
                return nil
            }

            return ([cafeteriaTitle(id: cafeteria.seq)] + menuLines).joined(separator: "\n")
        }

        if entries.isEmpty {
            return nil
        }

        let date = (try? CafeteriaData.shared.feedDate.value()) ?? Date.now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd."
        let dateText = dateFormatter.string(from: date)

        return String(
            format: String(localized: "cafeteria.share.format"),
            dateText,
            mealTypeLabel,
            entries.joined(separator: "\n\n")
        )
    }

    var firstSectionHeaderInfoButton: UIView? {
        (cafeteriaTableView.headerView(forSection: 0) as? CafeteriaHeaderView)?.infoButton
    }

    func reload() {
        cafeteriaTableView.reloadData()
        if showsSkeleton {
            cafeteriaTableView.isHidden = false
            noDataLabel.isHidden = true
        } else if cafeteriaTableView.numberOfSections == 0 {
            cafeteriaTableView.isHidden = true
            noDataLabel.isHidden = false
        } else {
            cafeteriaTableView.isHidden = false
            noDataLabel.isHidden = true
        }
    }

    func presentShareSheet(sourceView: UIView) {
        guard let text = shareText() else { return }
        AnalyticsManager.logSelect(.cafeteriaShareButton)

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityVC.title = String(localized: "cafeteria.share.title")
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        (parent ?? self).present(activityVC, animated: true)
    }
}

extension CafeteriaTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if showsSkeleton {
            return 3
        }
        if cafeteriaType == .breakfast {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return 0 }
            return cafeteriaItems.count
        } else if cafeteriaType == .lunch {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return 0 }
            return cafeteriaItems.count
        } else if cafeteriaType == .dinner {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return 0 }
            return cafeteriaItems.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if showsSkeleton {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: CafeteriaSkeletonHeaderView.reuseIdentifier)
        }
        guard let headerView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: CafeteriaHeaderView.reuseIdentifier) as? CafeteriaHeaderView
        else { return UIView() }
        if cafeteriaType == .breakfast {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return UIView() }
            let item = cafeteriaItems[section]
            headerView.setupUI(id: item.seq, runningTime: item.runningTime.breakfast, showCafeteriaInfoVC: { [weak self] in
                self?.showCafeteriaInfoVC(cafeteriaID: item.seq)
            })
        } else if cafeteriaType == .lunch {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return UIView() }
            let item = cafeteriaItems[section]
            headerView.setupUI(id: item.seq, runningTime: item.runningTime.lunch, showCafeteriaInfoVC: { [weak self] in
                self?.showCafeteriaInfoVC(cafeteriaID: item.seq)
            })
        } else if cafeteriaType == .dinner {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return UIView() }
            let item = cafeteriaItems[section]
            headerView.setupUI(id: item.seq, runningTime: item.runningTime.dinner, showCafeteriaInfoVC: { [weak self] in
                self?.showCafeteriaInfoVC(cafeteriaID: item.seq)
            })
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return section == 0 ? 3 : 2
        }
        if cafeteriaType == .breakfast {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return 0 }
            return languageFilteredMenus(cafeteriaItems[section].menus, type: "조식").count
        } else if cafeteriaType == .lunch {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return 0 }
            return languageFilteredMenus(cafeteriaItems[section].menus, type: "중식").count
        } else if cafeteriaType == .dinner {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return 0 }
            return languageFilteredMenus(cafeteriaItems[section].menus, type: "석식").count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: CafeteriaSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CafeteriaMenuCellView.reuseIdentifier) as? CafeteriaMenuCellView
        else { return UITableViewCell() }
        if cafeteriaType == .breakfast {
            guard let cafeteriaItems = try? CafeteriaData.shared.breakfastItems.value() else { return UITableViewCell() }
            let item = languageFilteredMenus(cafeteriaItems[indexPath.section].menus, type: "조식")[indexPath.row]
            cell.setupUI(item: item)
        } else if cafeteriaType == .lunch {
            guard let cafeteriaItems = try? CafeteriaData.shared.lunchItems.value() else { return UITableViewCell() }
            let item = languageFilteredMenus(cafeteriaItems[indexPath.section].menus, type: "중식")[indexPath.row]
            cell.setupUI(item: item)
        } else if cafeteriaType == .dinner {
            guard let cafeteriaItems = try? CafeteriaData.shared.dinnerItems.value() else { return UITableViewCell() }
            let item = languageFilteredMenus(cafeteriaItems[indexPath.section].menus, type: "석식")[indexPath.row]
            cell.setupUI(item: item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        70
    }
}
