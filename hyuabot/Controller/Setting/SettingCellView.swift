import UIKit
import WidgetKit

class SettingCellView: UITableViewCell {
    static let reuseIdentifier = "SettingCellView"
    private let availableCampus: [String.LocalizationValue] = [
        "campus.seoul",
        "campus.erica"
    ]
    private let availableTheme: [String.LocalizationValue] = [
        "theme.system",
        "theme.light",
        "theme.dark"
    ]
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .plainButtonText
    }

    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 1
        $0.textAlignment = .left
    }

    private let contentLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 1
        $0.textAlignment = .right
        $0.isHidden = true
    }

    private lazy var analyticsSwitch = UISwitch().then {
        $0.isHidden = true
        $0.accessibilityIdentifier = "setting.analytics_switch"
        $0.addTarget(self, action: #selector(analyticsSwitchChanged), for: .valueChanged)
    }

    private var onAnalyticsConsentChanged: ((Bool) -> Void)?
    private lazy var campusControl = UISegmentedControl(items: availableCampus.map { String(localized: $0) }).then {
        $0.isHidden = true
        $0.selectedSegmentTintColor = .hanyangBlue
        $0.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .regular),
            .foregroundColor: UIColor.label
        ], for: .normal)
        $0.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .bold),
            .foregroundColor: UIColor.white
        ], for: .selected)
        $0.accessibilityIdentifier = "setting.campus_control"
        $0.addTarget(self, action: #selector(campusControlChanged), for: .valueChanged)
    }

    private lazy var themeControl = UISegmentedControl(items: availableTheme.map { String(localized: $0) }).then {
        $0.isHidden = true
        $0.selectedSegmentTintColor = .hanyangBlue
        $0.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .regular),
            .foregroundColor: UIColor.label
        ], for: .normal)
        $0.setTitleTextAttributes([
            .font: UIFont.godo(size: 13, weight: .bold),
            .foregroundColor: UIColor.white
        ], for: .selected)
        $0.accessibilityIdentifier = "setting.theme_control"
        $0.addTarget(self, action: #selector(themeControlChanged), for: .valueChanged)
    }

    private let arrowImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.tintColor = .plainButtonText
        $0.contentMode = .scaleAspectFit
        $0.isHidden = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(campusControl)
        contentView.addSubview(themeControl)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(contentLabel)
        contentView.addSubview(analyticsSwitch)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }
        campusControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(124)
        }
        themeControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(144)
        }
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        contentLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        analyticsSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(imageName: String, title: String.LocalizationValue, onAnalyticsConsentChanged: ((Bool) -> Void)? = nil) {
        selectionStyle = .none
        iconImageView.image = UIImage(systemName: imageName)
        titleLabel.text = String(localized: title)
        self.onAnalyticsConsentChanged = nil
        campusControl.isHidden = true
        themeControl.isHidden = true
        arrowImageView.isHidden = true
        contentLabel.isHidden = true
        contentLabel.text = nil
        analyticsSwitch.isHidden = true
        if title == "setting.campus" {
            campusControl.do {
                $0.isHidden = false
                let campusID = UserDefaults.standard.integer(forKey: "campusID")
                $0.selectedSegmentIndex = campusID == 1 ? 0 : 1
            }
        } else if title == "setting.theme" {
            themeControl.do {
                $0.isHidden = false
                let themeID = UserDefaults.standard.integer(forKey: "themeID")
                $0.selectedSegmentIndex = min(max(themeID, 0), availableTheme.count - 1)
            }
        } else if title == "setting.language" {
            arrowImageView.isHidden = false
            selectionStyle = .default
        } else if title == "setting.privacy_policy" || title == "setting.open_source_licenses" {
            arrowImageView.isHidden = false
            selectionStyle = .default
        } else if title == "setting.analytics" {
            analyticsSwitch.isHidden = false
            analyticsSwitch.isOn = AnalyticsManager.isCollectionEnabled
            self.onAnalyticsConsentChanged = onAnalyticsConsentChanged
        } else if title == "setting.developer" {
            contentLabel.isHidden = false
            contentLabel.text = String(localized: "setting.developer.info")
        } else if title == "setting.version" {
            contentLabel.isHidden = false
            contentLabel.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        }
    }

    @objc private func analyticsSwitchChanged() {
        onAnalyticsConsentChanged?(analyticsSwitch.isOn)
    }

    @objc private func campusControlChanged() {
        selectCampus(availableCampus[campusControl.selectedSegmentIndex])
    }

    @objc private func themeControlChanged() {
        selectTheme(availableTheme[themeControl.selectedSegmentIndex])
    }

    private func selectCampus(_ campus: String.LocalizationValue) {
        let campusID = SettingsLogic.campusID(for: campus)
        AnalyticsManager.logSelect(.settingSelectCampus, type: .menu, name: campusID == 1 ? "seoul" : "erica")
        UserDefaults.standard.set(campusID, forKey: "campusID")
        UserDefaults(suiteName: "group.net.jaram.hyuabot")?.set(campusID, forKey: "campusID")
        WidgetCenter.shared.reloadTimelines(ofKind: "CafeteriaWidget")
        campusControl.selectedSegmentIndex = campusID == 1 ? 0 : 1
    }

    private func selectTheme(_ theme: String.LocalizationValue) {
        let themeID = SettingsLogic.themeID(for: theme)
        let themeName = themeID == 0 ? "system" : (themeID == 1 ? "light" : "dark")
        AnalyticsManager.logSelect(.settingSelectTheme, type: .menu, name: themeName)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        if themeID == 0 {
            UserDefaults.standard.set(themeID, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .unspecified
        } else if themeID == 1 {
            UserDefaults.standard.set(themeID, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .light
        } else {
            UserDefaults.standard.set(themeID, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .dark
        }
        themeControl.selectedSegmentIndex = min(max(themeID, 0), availableTheme.count - 1)
    }
}
