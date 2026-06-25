import Api
import RxSwift
import UIKit

class ShuttleTimetableTabVC: UIViewController {
    private let isWeekdays: Bool
    private let showViaVC: (ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    private let disposeBag = DisposeBag()
    private var showsSkeleton = false
    private lazy var shuttleTimetableTableView: UITableView = .init().then {
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.showsVerticalScrollIndicator = false
        $0.register(ShuttleTimetableCellView.self, forCellReuseIdentifier: ShuttleTimetableCellView.reuseIdentifier)
        $0.register(ShuttleTimetableEmptyCellView.self, forCellReuseIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier)
        $0.register(ShuttleTimetableSkeletonCellView.self, forCellReuseIdentifier: ShuttleTimetableSkeletonCellView.reuseIdentifier)
    }

    init(isWeekdays: Bool, showViaVC: @escaping (ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void) {
        self.isWeekdays = isWeekdays
        self.showViaVC = showViaVC
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
        view.addSubview(shuttleTimetableTableView)
        shuttleTimetableTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    var firstVisibleCell: UIView? {
        shuttleTimetableTableView.visibleCells.first
    }

    func reload() {
        shuttleTimetableTableView.reloadData()
        guard !showsSkeleton else { return }
        if isWeekdays {
            guard let items = try? ShuttleTimetableData.shared.weekdays.value() else { return }
            let scrollIndex = items.firstIndex { item in
                let now = Date.now
                let dateFormatter = DateFormatter().then {
                    $0.dateFormat = "HH:mm:ss"
                }
                let nowString = dateFormatter.string(from: now)
                return nowString < item.time
            } ?? 0
            shuttleTimetableTableView.scrollToRow(at: IndexPath(row: scrollIndex, section: 0), at: .middle, animated: false)
        } else {
            guard let items = try? ShuttleTimetableData.shared.weekends.value() else { return }
            let scrollIndex = items.firstIndex { item in
                let now = Date.now
                let dateFormatter = DateFormatter().then {
                    $0.dateFormat = "HH:mm:ss"
                }
                let nowString = dateFormatter.string(from: now)
                return nowString < item.time
            } ?? 0
            shuttleTimetableTableView.scrollToRow(at: IndexPath(row: scrollIndex, section: 0), at: .middle, animated: false)
        }
    }

    private func observeSubjects() {
        ShuttleTimetableData.shared.isLoading
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.showsSkeleton = isLoading
                self?.reload()
            })
            .disposed(by: disposeBag)
    }
}

extension ShuttleTimetableTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return 8
        }
        if isWeekdays {
            guard let items = try? ShuttleTimetableData.shared.weekdays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        } else {
            guard let items = try? ShuttleTimetableData.shared.weekends.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleTimetableSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let options = try? ShuttleTimetableData.shared.options.value() else { return UITableViewCell() }
        if isWeekdays {
            guard let items = try? ShuttleTimetableData.shared.weekdays.value() else { return UITableViewCell() }
            if items.isEmpty != true {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleTimetableCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleTimetableCellView
                cell.setupUI(option: options, item: items[indexPath.row])
                return cell
            }
        } else if !isWeekdays {
            guard let items = try? ShuttleTimetableData.shared.weekends.value() else { return UITableViewCell() }
            if items.isEmpty != true {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleTimetableCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleTimetableCellView
                cell.setupUI(option: options, item: items[indexPath.row])
                return cell
            }
        }
        return tableView.dequeueReusableCell(
            withIdentifier: ShuttleTimetableEmptyCellView.reuseIdentifier,
            for: indexPath
        ) as! ShuttleTimetableEmptyCellView
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ShuttleTimetableCellView else { return }
        guard let item = cell.item else { return }
        AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
        showViaVC(item)
    }
}
