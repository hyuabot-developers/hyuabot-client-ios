import UIKit
import Api

class ShuttleViaVC: UIViewController {
    private var itemByOrder: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order?
    private var itemByDestination: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?
    private var timetableItem: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order?
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.text = String(localized: "shuttle.via.stop")
        $0.textAlignment = .center
    }
    private lazy var tableView = UITableView().then {
        $0.backgroundColor = .systemBackground
        $0.register(ShuttleViaCellView.self, forCellReuseIdentifier: ShuttleViaCellView.reuseIdentifier)
        $0.dataSource = self
        $0.delegate = self
    }
    
    private lazy var contentView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.backgroundColor = .systemBackground
        $0.addArrangedSubview(self.tableView)
    }
    
    init(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        super.init(nibName: nil, bundle: nil)
        self.itemByOrder = item
    }
    
    init(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        super.init(nibName: nil, bundle: nil)
        self.itemByDestination = item
    }
    
    init(item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        super.init(nibName: nil, bundle: nil)
        self.timetableItem = item
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.contentView)
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.contentView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension ShuttleViaVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.itemByOrder?.stops.count ?? 0) > 0 {
            return self.itemByOrder?.stops.count ?? 0
        } else if (self.itemByDestination?.stops.count ?? 0) > 0 {
            return self.itemByDestination?.stops.count ?? 0
        } else if (self.timetableItem?.stops.count ?? 0) > 0 {
            return self.timetableItem?.stops.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleViaCellView.reuseIdentifier) as? ShuttleViaCellView ?? ShuttleViaCellView()
        if self.itemByOrder != nil {
            cell.setupUI(startStop: self.itemByOrder!, item: self.itemByOrder!.stops[indexPath.row])
        } else if self.itemByDestination != nil {
            cell.setupUI(startStop: self.itemByDestination!, item: self.itemByDestination!.stops[indexPath.row])
        } else if self.timetableItem != nil {
            cell.setupUI(startStop: self.timetableItem!, item: self.timetableItem!.stops[indexPath.row])
        }
        return cell
    }
}
