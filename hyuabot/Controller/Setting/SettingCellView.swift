import UIKit

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
    private lazy var campusButton: UIButton = UIButton().then {
        var conf = UIButton.Configuration.bordered()
        var title = AttributedString.init(String(localized: "setting.campus"))
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
    private lazy var themeButton: UIButton = UIButton().then {
        var conf = UIButton.Configuration.bordered()
        var title = AttributedString.init(String(localized: "setting.theme"))
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
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.selectionStyle = .none
        self.contentView.addSubview(self.iconImageView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.campusButton)
        self.contentView.addSubview(self.themeButton)
        self.contentView.addSubview(self.arrowImageView)
        self.contentView.addSubview(self.contentLabel)
        self.iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
        }
        self.campusButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        self.themeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        self.arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        self.contentLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(imageName: String, title: String.LocalizationValue) {
        self.iconImageView.image = UIImage(systemName: imageName)
        self.titleLabel.text = String(localized: title)
        if title == "setting.campus" {
            self.campusButton.do {
                $0.isHidden = false
                let campusID = UserDefaults.standard.integer(forKey: "campusID")
                if campusID == 1 {
                    self.setButtonTitle($0, "campus.seoul")
                } else if campusID == 2 {
                    self.setButtonTitle($0, "campus.erica")
                }
            }
        } else if title == "setting.theme" {
            self.themeButton.do {
                $0.isHidden = false
                let themeID = UserDefaults.standard.integer(forKey: "themeID")
                if themeID == 0 {
                    self.setButtonTitle($0, "theme.system")
                } else if themeID == 1 {
                    self.setButtonTitle($0, "theme.light")
                } else {
                    self.setButtonTitle($0, "theme.dark")
                }
            }
        } else if title == "setting.language" {
            self.arrowImageView.isHidden = false
        } else if title == "setting.developer" {
            self.contentLabel.isHidden = false
            self.contentLabel.text = String(localized: "setting.developer.info")
        } else if title == "setting.version" {
            self.contentLabel.isHidden = false
            self.contentLabel.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        }
    }
    
    private func selectCampus(_ campus: String.LocalizationValue) {
        if campus == "campus.seoul" {
            UserDefaults.standard.set(1, forKey: "campusID")
            self.setButtonTitle(self.campusButton, "campus.seoul")
        } else {
            UserDefaults.standard.set(2, forKey: "campusID")
            self.setButtonTitle(self.campusButton, "campus.erica")
        }
    }
    
    private func selectTheme(_ theme: String.LocalizationValue) {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        if theme == "theme.system" {
            UserDefaults.standard.set(0, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .unspecified
            self.setButtonTitle(self.themeButton, "theme.system")
        } else if theme == "theme.light" {
            UserDefaults.standard.set(1, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .light
            self.setButtonTitle(self.themeButton, "theme.light")
        } else {
            UserDefaults.standard.set(2, forKey: "themeID")
            window?.overrideUserInterfaceStyle = .dark
            self.setButtonTitle(self.themeButton, "theme.dark")
        }
    }
    
    private func setButtonTitle(_ button: UIButton, _ title: String.LocalizationValue) {
        var config = button.configuration
        var title = AttributedString.init(String(localized: title))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        config?.attributedTitle = title
        button.configuration = config
    }
}
