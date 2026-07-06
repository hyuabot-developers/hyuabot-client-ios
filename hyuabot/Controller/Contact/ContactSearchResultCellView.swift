import Api
import RxSwift
import UIKit

class ContactSearchResultCellView: UITableViewCell {
    static let reuseIdentifier = "ContactSearchResultCellView"
    private let nameLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
        $0.textAlignment = .left
    }

    private let phoneLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingMiddle
        $0.textAlignment = .left
        $0.textColor = .secondaryLabel
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(phoneLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(11)
        }
        phoneLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.nameLabel)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(self.nameLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(11)
        }
    }

    func setupUI(item: Contact) {
        nameLabel.text = item.name
        phoneLabel.text = item.phoneNumber
    }
}
