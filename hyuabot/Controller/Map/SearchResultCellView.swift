import UIKit
import QueryAPI
import RxSwift

class SearchResultCellView: UITableViewCell {
    static let reuseIdentifier = "SearchResultCellView"
    private let roomLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.textAlignment = .left
    }
    private let buildingLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingMiddle
        $0.textAlignment = .right
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.roomLabel)
        self.contentView.addSubview(self.buildingLabel)
        self.roomLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.lessThanOrEqualTo(self.contentView.snp.centerX).offset(-10)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.buildingLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.contentView.snp.centerX).offset(10)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(item: MapPageSearchQuery.Data.Room) {
        self.roomLabel.text = item.name
        self.buildingLabel.text = "\(item.buildingName) (\(item.number)호)"
    }
}
