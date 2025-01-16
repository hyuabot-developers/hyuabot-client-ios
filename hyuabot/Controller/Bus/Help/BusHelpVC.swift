import UIKit

class BusHelpVC: UIViewController {
    private let titleItems: [String.LocalizationValue] = ["bus.help.title1", "bus.help.title2", "bus.help.title3", "bus.help.title4"]
    private let contentItems: [String.LocalizationValue] = ["bus.help.content1", "bus.help.content2", "bus.help.content3", "bus.help.content4"]
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "bus.help")
    }
    private lazy var helpTableView = UITableView().then {
        $0.dataSource = self
        $0.delegate = self
        $0.register(ShuttleHelpItemCell.self, forCellReuseIdentifier: ShuttleViaCellView.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .hanyangBlue
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.helpTableView)
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        self.helpTableView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension BusHelpVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleHelpItemCell.reuseIdentifier) as? ShuttleHelpItemCell ?? ShuttleHelpItemCell()
        cell.setupUI(title: self.titleItems[indexPath.row], content: self.contentItems[indexPath.row])
        return cell
    }
}
