import UIKit

class ContactSearchEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "ContactSearchEmptyCellView"
    private let emptyLabel = UILabel().then{
        $0.text = String(localized: "contact.search.empty")
        $0.font = .godo(size: 16, weight: .regular)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(emptyLabel)
        self.selectionStyle = .none
        self.emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(20)
        }
    }
}
