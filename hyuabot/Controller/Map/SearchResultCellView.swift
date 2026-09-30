import Api
import RxSwift
import UIKit

class SearchResultCellView: UITableViewCell {
    static let reuseIdentifier = "SearchResultCellView"
    private let roomLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.numberOfLines = 0
        $0.textAlignment = .left
    }

    private let buildingLabel = UILabel().then {
        $0.font = .godo(size: 14, weight: .regular)
        $0.numberOfLines = 0
        $0.textAlignment = .left
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
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(12)
        }
        buildingLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(roomLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    func setupUI(item: RoomItem) {
        roomLabel.setKoreanTranslatedText(item.name)
        let roomNumber = String(format: String(localized: "map.room.number.format"), item.number)
        buildingLabel.setKoreanTranslatedText("\(item.building) · \(roomNumber)")
    }
}
