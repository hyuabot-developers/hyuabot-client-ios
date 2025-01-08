import UIKit
import QueryAPI
import RxSwift

class ShuttleHelpItemCell: UITableViewCell {
    static let reuseIdentifier = "ShuttleHelpItemCell"
    private let titleLabel = UILabel().then {
        $0.font = .godo(size: 18, weight: .bold)
        $0.textAlignment = .left
    }
    private let contentLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.textAlignment = .left
        $0.numberOfLines = 0
    }
    private lazy var cellStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.contentLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.cellStackView)
        self.cellStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview().inset(15)
        }
    }
    
    func setupUI(title: String.LocalizationValue, content: String.LocalizationValue) {
        self.titleLabel.text = String(localized: title)
        self.contentLabel.text = String(localized: content)
    }
}
