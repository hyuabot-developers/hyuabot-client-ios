import UIKit

class SettingVC: UIViewController {
    private let imageNames = ["graduationcap.fill", "moonphase.waning.crescent", "globe", "person.circle", "info.circle.fill"]
    private let titles: [String.LocalizationValue] = ["setting.campus", "setting.theme", "setting.language", "setting.developer", "setting.version"]
    private lazy var settingView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(SettingCellView.self, forCellReuseIdentifier: SettingCellView.reuseIdentifier)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        // Set default Value
        if (UserDefaults.standard.integer(forKey: "campusID") == 0) {
            UserDefaults.standard.set(2, forKey: "campusID")
        }
            
        self.navigationItem.title = String(localized: "tabbar.setting")
        self.view.addSubview(self.settingView)
        self.settingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func openAppSetting() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}

extension SettingVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingCellView.reuseIdentifier) as? SettingCellView else { return UITableViewCell() }
        cell.setupUI(imageName: self.imageNames[indexPath.row], title: self.titles[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.titles[indexPath.row] == "setting.language" {
            self.openAppSetting()
        }
    }
}
