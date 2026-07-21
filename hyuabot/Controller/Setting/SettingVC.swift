import SafariServices
import UIKit

class SettingVC: UIViewController {
    private let imageNames = [
        "graduationcap.fill",
        "moonphase.waning.crescent",
        "globe",
        "chart.bar.fill",
        "questionmark.circle",
        "hand.raised.fill",
        "doc.text.fill",
        "person.circle",
        "info.circle.fill"
    ]
    private let titles: [String.LocalizationValue] = [
        "setting.campus",
        "setting.theme",
        "setting.language",
        "setting.analytics",
        "setting.coachmark.reset",
        "setting.privacy_policy",
        "setting.open_source_licenses",
        "setting.developer",
        "setting.version"
    ]
    private let analyticsNames = [
        "setting.campus",
        "setting.theme",
        "setting.language",
        "setting.analytics",
        "setting.coachmark.reset",
        "setting.privacy_policy",
        "setting.open_source_licenses",
        "setting.developer",
        "setting.version"
    ]
    private lazy var settingView = UITableView().then {
        $0.showsVerticalScrollIndicator = false
        $0.delegate = self
        $0.dataSource = self
        $0.register(SettingCellView.self, forCellReuseIdentifier: SettingCellView.reuseIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.setting)
        showCoachMarksIfNeeded()
    }

    private func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("setting") else { return }
        let rows: [(Int, String, String, String)] = [
            (0, "setting.campus", "coach.setting.campus.title", "coach.setting.campus.message"),
            (1, "setting.theme", "coach.setting.theme.title", "coach.setting.theme.message"),
            (2, "setting.language", "coach.setting.language.title", "coach.setting.language.message")
        ]
        let items: [CoachMarkItem] = rows.compactMap { row, _, titleKey, msgKey in
            guard let cell = settingView.cellForRow(at: IndexPath(row: row, section: 0)) else { return nil }
            return CoachMarkItem(
                id: "setting.\(row)",
                targetView: cell,
                title: String(localized: String.LocalizationValue(titleKey)),
                message: String(localized: String.LocalizationValue(msgKey))
            )
        }
        presentCoachMarks(pageId: "setting", items: items)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        // Set default Value
        if UserDefaults.standard.integer(forKey: "campusID") == 0 {
            UserDefaults.standard.set(2, forKey: "campusID")
            UserDefaults(suiteName: "group.net.jaram.hyuabot")?.set(2, forKey: "campusID")
        }

        navigationItem.title = String(localized: "tabbar.setting")
        view.addSubview(settingView)
        settingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func openAppSetting() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }

    private func resetCoachMarks() {
        CoachMarkManager.shared.resetAll()
        showToastMessage(
            image: UIImage(systemName: "checkmark.circle.fill"),
            message: String(localized: "toast.coachmark.reset.complete")
        )
    }

    private func setAnalyticsConsent(_ isEnabled: Bool) {
        AnalyticsManager.setCollectionEnabled(isEnabled)
    }
}

extension SettingVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingCellView.reuseIdentifier) as? SettingCellView
        else { return UITableViewCell() }
        cell.setupUI(
            imageName: imageNames[indexPath.row],
            title: titles[indexPath.row],
            onAnalyticsConsentChanged: { [weak self] isEnabled in
                self?.setAnalyticsConsent(isEnabled)
            }
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < analyticsNames.count {
            AnalyticsManager.logSelect(.settingSelectRow, type: .listItem, name: analyticsNames[indexPath.row])
        }
        if titles[indexPath.row] == "setting.language" {
            openAppSetting()
        } else if titles[indexPath.row] == "setting.coachmark.reset" {
            resetCoachMarks()
        } else if titles[indexPath.row] == "setting.privacy_policy" {
            openPrivacyPolicy()
        } else if titles[indexPath.row] == "setting.open_source_licenses" {
            let viewController = OpenSourceLicensesVC()
            viewController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(viewController, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://jil8885.github.io/privacy_policy") else { return }
        let viewController = SFSafariViewController(url: url)
        viewController.dismissButtonStyle = .close
        present(viewController, animated: true)
    }
}
