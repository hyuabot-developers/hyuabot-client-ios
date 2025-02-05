import UIKit

class SettingCellView: UITableViewCell {
    static let reuseIdentifier = "SettingCellView"
    private let availableCampus: [String.LocalizationValue] = [
        "campus.seoul",
        "campus.erica"
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
    
    private func setButtonTitle(_ button: UIButton, _ title: String.LocalizationValue) {
        var config = button.configuration
        var title = AttributedString.init(String(localized: title))
        title.font = .godo(size: 16, weight: .medium)
        title.foregroundColor = .label
        config?.attributedTitle = title
        button.configuration = config
    }
}
