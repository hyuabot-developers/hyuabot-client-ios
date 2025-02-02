import UIKit
import QueryAPI
import RxSwift

class ReadingRoomCellView: UITableViewCell {
    static let reuseIdentifier = "ReadingRoomCellView"
    private let nameLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.numberOfLines = 1
    }
    private let alarmButton = UIButton().then {
        $0.setImage(UIImage(systemName: "bell"), for: .normal)
        $0.tintColor = .plainButtonText
    }
    private let seatLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
        $0.numberOfLines = 1
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.selectionStyle = .none
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.alarmButton)
        self.contentView.addSubview(self.seatLabel)
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.alarmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(self.nameLabel)
        }
        self.seatLabel.snp.makeConstraints { make in
            make.trailing.equalTo(self.alarmButton.snp.leading).offset(-10)
            make.centerY.equalTo(self.nameLabel)
        }
    }
    
    func setupUI(item: ReadingRoomPageQuery.Data.ReadingRoom) {
        self.nameLabel.text = item.name
        self.seatLabel.text = "\(item.available) / \(item.active)"
    }
}
