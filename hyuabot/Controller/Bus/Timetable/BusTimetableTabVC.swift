import RxSwift
import UIKit

class BusTimetableTabVC: UIViewController {
    let timetableEnum: BusTimetableEnum
    private let disposeBag = DisposeBag()
    private var showsSkeleton = true
    private lazy var busTimetableView: UITableView = .init().then {
        $0.delegate = self
        $0.dataSource = self
        $0.sectionHeaderTopPadding = 0
        $0.showsVerticalScrollIndicator = false
        $0.register(BusTimetableCellView.self, forCellReuseIdentifier: BusTimetableCellView.reuseIdentifier)
        $0.register(BusTimetableEmptyCellView.self, forCellReuseIdentifier: BusTimetableEmptyCellView.reuseIdentifier)
        $0.register(BusTimetableSkeletonCellView.self, forCellReuseIdentifier: BusTimetableSkeletonCellView.reuseIdentifier)
    }

    init(timetableEnum: BusTimetableEnum) {
        self.timetableEnum = timetableEnum
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
        view.addSubview(busTimetableView)
        busTimetableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func reload() {
        busTimetableView.reloadData()
    }

    private func observeSubjects() {
        BusTimetableData.shared.isLoading
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.showsSkeleton = isLoading
                self?.reload()
            })
            .disposed(by: disposeBag)
    }
}

extension BusTimetableTabVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsSkeleton {
            return 8
        }
        if timetableEnum == .weekdays {
            guard let items = try? BusTimetableData.shared.weekdays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        } else if timetableEnum == .saturdays {
            guard let items = try? BusTimetableData.shared.saturdays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        } else if timetableEnum == .sundays {
            guard let items = try? BusTimetableData.shared.sundays.value() else { return 0 }
            return items.isEmpty ? 1 : items.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: BusTimetableSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        if timetableEnum == .weekdays {
            guard let items = try? BusTimetableData.shared.weekdays.value() else { return BusTimetableEmptyCellView() }
            if !items.isEmpty {
                let cell = tableView
                    .dequeueReusableCell(withIdentifier: BusTimetableCellView.reuseIdentifier) as? BusTimetableCellView ??
                    BusTimetableCellView()
                cell.setupUI(item: items[indexPath.row])
                return cell
            }
        } else if timetableEnum == .saturdays {
            guard let items = try? BusTimetableData.shared.saturdays.value() else { return BusTimetableEmptyCellView() }
            if !items.isEmpty {
                let cell = tableView
                    .dequeueReusableCell(withIdentifier: BusTimetableCellView.reuseIdentifier) as? BusTimetableCellView ??
                    BusTimetableCellView()
                cell.setupUI(item: items[indexPath.row])
                return cell
            }
        } else if timetableEnum == .sundays {
            guard let items = try? BusTimetableData.shared.sundays.value() else { return BusTimetableEmptyCellView() }
            if !items.isEmpty {
                let cell = tableView
                    .dequeueReusableCell(withIdentifier: BusTimetableCellView.reuseIdentifier) as? BusTimetableCellView ??
                    BusTimetableCellView()
                cell.setupUI(item: items[indexPath.row])
                return cell
            }
        }
        return BusTimetableCellView()
    }
}
