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
        $0.addTarget(self, action: #selector(analyticsSwitchChanged), for: .valueChanged)
    }

    private var onAnalyticsConsentChanged: ((Bool) -> Void)?
    private lazy var campusButton: UIButton = .init().then {
        var conf = UIButton.Configuration.bordered()
        var title = AttributedString(String(localized: "setting.campus"))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        conf.attributedTitle = title
        $0.configuration = conf
        // Available start stops
        let items = self.availableCampus.map { campus in
            UIAction(title: String(localized: campus), handler: { _ in
                self.selectCampus(campus)
            })
        }
        let menu = UIMenu(title: "", children: items)
        $0.menu = menu
        $0.showsMenuAsPrimaryAction = true
        $0.isHidden = true
    }

    private lazy var themeButton: UIButton = .init().then {
        var conf = UIButton.Configuration.bordered()
        var title = AttributedString(String(localized: "setting.theme"))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        conf.attributedTitle = title
        $0.configuration = conf
        // Available start stops
        let items = self.availableTheme.map { theme in
            UIAction(title: String(localized: theme), handler: { _ in
                self.selectTheme(theme)
            })
        }
        let menu = UIMenu(title: "", children: items)
        $0.menu = menu
        $0.showsMenuAsPrimaryAction = true
        $0.isHidden = true
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
        contentView.addSubview(campusButton)
        contentView.addSubview(themeButton)
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
        }
        campusButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        themeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
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
        iconImageView.image = UIImage(systemName: imageName)
        titleLabel.text = String(localized: title)
        self.onAnalyticsConsentChanged = nil
        campusButton.isHidden = true
        themeButton.isHidden = true
        arrowImageView.isHidden = true
        contentLabel.isHidden = true
        contentLabel.text = nil
        analyticsSwitch.isHidden = true
        if title == "setting.campus" {
            campusButton.do {
                $0.isHidden = false
                let campusID = UserDefaults.standard.integer(forKey: "campusID")
                self.setButtonTitle($0, SettingsLogic.campusKey(for: campusID))
            }
        } else if title == "setting.theme" {
            themeButton.do {
                $0.isHidden = false
                let themeID = UserDefaults.standard.integer(forKey: "themeID")
                self.setButtonTitle($0, SettingsLogic.themeKey(for: themeID))
            }
        } else if title == "setting.language" {
            arrowImageView.isHidden = false
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

    private func selectCampus(_ campus: String.LocalizationValue) {
        let campusID = SettingsLogic.campusID(for: campus)
        AnalyticsManager.logSelect(.settingSelectCampus, type: .menu, name: campusID == 1 ? "seoul" : "erica")
        UserDefaults.standard.set(campusID, forKey: "campusID")
        UserDefaults(suiteName: "group.net.jaram.hyuabot")?.set(campusID, forKey: "campusID")
        WidgetCenter.shared.reloadTimelines(ofKind: "CafeteriaWidget")
        if campus == "campus.seoul" {
            setButtonTitle(campusButton, "campus.seoul")
        } else {
            setButtonTitle(campusButton, "campus.erica")
        }
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
            setButtonTitle(themeButton, "theme.system")
        } else if themeID == 1 {
            UserDefaults.standard.set(themeID, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .light
            setButtonTitle(themeButton, "theme.light")
        } else {
            UserDefaults.standard.set(themeID, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .dark
            setButtonTitle(themeButton, "theme.dark")
        }
    }

    private func setButtonTitle(_ button: UIButton, _ title: String.LocalizationValue) {
        var config = button.configuration
        var title = AttributedString(String(localized: title))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        config?.attributedTitle = title
        button.configuration = config
    }
}
