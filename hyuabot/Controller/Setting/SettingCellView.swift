import UIKit

class SettingCellView: UITableViewCell {
    static let reuseIdentifier = "SettingCellView"
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .plainButtonText
    }
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 1
        $0.textAlignment = .left
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
        self.contentView.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        self.iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconImageView.snp.trailing).offset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(imageName: String, title: String.LocalizationValue) {
        self.iconImageView.image = UIImage(systemName: imageName)
        self.titleLabel.text = String(localized: title)
    }
}
