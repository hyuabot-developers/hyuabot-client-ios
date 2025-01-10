import UIKit

class ShuttleHelpVC: UIViewController {
    private let titleItems: [String.LocalizationValue] = ["shuttle.help.title1", "shuttle.help.title2", "shuttle.help.title3", "shuttle.help.title4", "shuttle.help.title5"]
    private let contentItems: [String.LocalizationValue] = ["shuttle.help.content1", "shuttle.help.content2", "shuttle.help.content3", "shuttle.help.content4", "shuttle.help.content5"]
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .hanyangBlue
        $0.textAlignment = .center
        $0.text = String(localized: "shuttle.help")
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

extension ShuttleHelpVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
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
