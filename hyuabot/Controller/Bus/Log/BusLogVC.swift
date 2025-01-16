import UIKit
import RxSwift
import QueryAPI

class BusLogVC: UIViewController {
    let stopID: Int
    let routes: [Int]
    private let disposeBag = DisposeBag()
    private let firstLogs: BehaviorSubject<[BusDepartureLogDialogQuery.Data.Bus.Route.Log]> = .init(value: [])
    private let secondLogs: BehaviorSubject<[BusDepartureLogDialogQuery.Data.Bus.Route.Log]> = .init(value: [])
    private let thirdLogs: BehaviorSubject<[BusDepartureLogDialogQuery.Data.Bus.Route.Log]> = .init(value: [])
    
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "bus.log.title")
    }
    
    private lazy var firstLogTableView: UITableView = {
        let tableView = UITableView().then {
            $0.register(BusLogCell.self, forCellReuseIdentifier: BusLogCell.reuseIdentifier)
            $0.separatorStyle = .none
            $0.dataSource = self
            $0.delegate = self
            $0.rowHeight = 40
            $0.layer.do {
                $0.borderColor = UIColor.gray.cgColor
                $0.borderWidth = 1
                $0.cornerRadius = 8
            }
        }
        return tableView
    }()
    
    private let firstLogTitleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textAlignment = .center
    }
    
    private lazy var firstLogView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        view.isLayoutMarginsRelativeArrangement = true
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        view.addArrangedSubview(firstLogTitleLabel)
        view.addArrangedSubview(firstLogTableView)
        return view
    }()
    
    private lazy var secondLogTableView: UITableView = {
        let tableView = UITableView().then {
            $0.register(BusLogCell.self, forCellReuseIdentifier: BusLogCell.reuseIdentifier)
            $0.separatorStyle = .none
            $0.dataSource = self
            $0.delegate = self
            $0.rowHeight = 40
            $0.layer.do {
                $0.borderColor = UIColor.gray.cgColor
                $0.borderWidth = 1
                $0.cornerRadius = 8
            }
        }
        return tableView
    }()
    
    private let secondLogTitleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textAlignment = .center
    }
    
    private lazy var secondLogView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        view.isLayoutMarginsRelativeArrangement = true
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        view.addArrangedSubview(secondLogTitleLabel)
        view.addArrangedSubview(secondLogTableView)
        return view
    }()
    
    private lazy var thirdLogTableView: UITableView = {
        let tableView = UITableView().then {
            $0.register(BusLogCell.self, forCellReuseIdentifier: BusLogCell.reuseIdentifier)
            $0.separatorStyle = .none
            $0.dataSource = self
            $0.delegate = self
            $0.rowHeight = 40
            $0.layer.do {
                $0.borderColor = UIColor.gray.cgColor
                $0.borderWidth = 1
                $0.cornerRadius = 8
            }
        }
        return tableView
    }()
    
    private let thirdLogTitleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textAlignment = .center
    }
    
    private lazy var thirdLogView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 20
        view.isLayoutMarginsRelativeArrangement = true
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)
        view.addArrangedSubview(thirdLogTitleLabel)
        view.addArrangedSubview(thirdLogTableView)
        return view
    }()
    
    private lazy var logView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.backgroundColor = .systemBackground
        view.addArrangedSubview(firstLogView)
        view.addArrangedSubview(secondLogView)
        view.addArrangedSubview(thirdLogView)
        view.isLayoutMarginsRelativeArrangement = true
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        return view
    }()
    
    required init(stopID: Int, routes: [Int]) {
        self.stopID = stopID
        self.routes = routes
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.fetchLog()
        self.observeSubjects()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.logView)
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.logView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func fetchLog() {
        let now = Date.now
        let firstDate = now.addingTimeInterval(-60 * 60 * 24 * 7)
        let secondDate = now.addingTimeInterval(-60 * 60 * 24 * 2)
        let thirdDate = now.addingTimeInterval(-60 * 60 * 24)
        // Set Labels
        let dateFormatter = DateFormatter().then { $0.dateFormat = "MM/dd" }
        self.firstLogTitleLabel.text = dateFormatter.string(from: firstDate)
        self.secondLogTitleLabel.text = dateFormatter.string(from: secondDate)
        self.thirdLogTitleLabel.text = dateFormatter.string(from: thirdDate)
        // Fetch Logs
        let queryDateFormatter = DateFormatter().then { $0.dateFormat = "yyyy-MM-dd" }
        Network.shared.client.fetch(query: BusDepartureLogDialogQuery(
            stopID: self.stopID,
            routes: self.routes,
            dates: [
                queryDateFormatter.string(from: firstDate),
                queryDateFormatter.string(from: secondDate),
                queryDateFormatter.string(from: thirdDate)
            ]
        )) { result in
            if case .success(let response) = result {
                var firstLogs: [BusDepartureLogDialogQuery.Data.Bus.Route.Log] = []
                var secondLogs: [BusDepartureLogDialogQuery.Data.Bus.Route.Log] = []
                var thirdLogs: [BusDepartureLogDialogQuery.Data.Bus.Route.Log] = []
                response.data?.bus.first?.routes.forEach { route in
                    route.log.forEach { log in
                        if log.departureDate == queryDateFormatter.string(from: firstDate) {
                            firstLogs.append(log)
                        } else if log.departureDate == queryDateFormatter.string(from: secondDate) {
                            secondLogs.append(log)
                        } else if log.departureDate == queryDateFormatter.string(from: thirdDate) {
                            thirdLogs.append(log)
                        }
                    }
                }
                self.firstLogs.onNext(firstLogs.sorted(by: { $0.departureTime < $1.departureTime }))
                self.secondLogs.onNext(secondLogs.sorted(by: { $0.departureTime < $1.departureTime }))
                self.thirdLogs.onNext(thirdLogs.sorted(by: { $0.departureTime < $1.departureTime }))
            }
        }
    }
    
    @objc private func observeSubjects() {
        self.firstLogs.subscribe(onNext: { [weak self] logs in
            self?.firstLogTableView.reloadData()
        }).disposed(by: self.disposeBag)
        self.secondLogs.subscribe(onNext: { [weak self] logs in
            self?.secondLogTableView.reloadData()
        }).disposed(by: self.disposeBag)
        self.thirdLogs.subscribe(onNext: { [weak self] logs in
            self?.thirdLogTableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
}

extension BusLogVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
            case self.firstLogTableView:
                guard let logs = try? self.firstLogs.value() else { return 0 }
                return logs.count
            case self.secondLogTableView:
                guard let logs = try? self.secondLogs.value() else { return 0 }
                return logs.count
            case self.thirdLogTableView:
                guard let logs = try? self.thirdLogs.value() else { return 0 }
                return logs.count
            default:
                return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BusLogCell.reuseIdentifier) as? BusLogCell ?? BusLogCell()
        switch tableView {
        case self.firstLogTableView:
            guard let logs = try? self.firstLogs.value() else { return UITableViewCell() }
            cell.setupUI(index: indexPath.row, item: logs[indexPath.row])
        case self.secondLogTableView:
            guard let logs = try? self.secondLogs.value() else { return UITableViewCell() }
            cell.setupUI(index: indexPath.row, item: logs[indexPath.row])
        case self.thirdLogTableView:
            guard let logs = try? self.thirdLogs.value() else { return UITableViewCell() }
            cell.setupUI(index: indexPath.row, item: logs[indexPath.row])
        default:
            break
        }
        return cell
    }
}
