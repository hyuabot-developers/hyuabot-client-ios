import UIKit
import QueryAPI
import RxSwift

class CafeteriaMenuCellView: UITableViewCell {
    static let reuseIdentifier = "CafeteriaMenuCellView"
    private let menuLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    private let pricaLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.textAlignment = .center
    }
    private lazy var cellStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.menuLabel, self.pricaLabel])
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
        self.selectionStyle = .none
        self.cellStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(15)
        }
    }
    
    func setupUI(item: CafeteriaPageQuery.Data.Menu.Menu) {
        self.menuLabel.text = item.menu
        self.pricaLabel.text = String(localized: "cafeteria.menu.price.\(item.price)")
    }
}
