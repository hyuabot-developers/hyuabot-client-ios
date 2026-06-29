import Api
import RxSwift
import UIKit

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
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        contentView.addSubview(roomLabel)
        contentView.addSubview(buildingLabel)
        roomLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.lessThanOrEqualTo(self.contentView.snp.centerX).offset(-10)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        buildingLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.contentView.snp.centerX).offset(10)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(item: RoomItem) {
        roomLabel.setKoreanTranslatedText(item.name)
        buildingLabel.setKoreanTranslatedText("\(item.building) (\(item.number)호)")
    }
}
