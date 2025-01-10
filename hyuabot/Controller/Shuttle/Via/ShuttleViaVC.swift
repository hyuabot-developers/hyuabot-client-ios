import UIKit
import QueryAPI

class ShuttleViaVC: UIViewController {
    private let item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable
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
    
    init(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) {
        self.item = item
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
        return self.item.via.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleViaCellView.reuseIdentifier) as? ShuttleViaCellView ?? ShuttleViaCellView()
        cell.setupUI(startStop: self.item, item: self.item.via[indexPath.row])
        return cell
    }
}
