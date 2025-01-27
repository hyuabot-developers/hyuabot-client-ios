import UIKit
import QueryAPI
import RxSwift

class CalendarEventCellView: UITableViewCell {
    static let reuseIdentifier = "CalendarEventCellView"
    private let fromDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private let toDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    private let nameLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
        $0.textAlignment = .left
    }
    private let dateLabel = UILabel().then {
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
        self.selectionStyle = .none
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.dateLabel)
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.trailing.lessThanOrEqualTo(self.contentView.snp.trailing).offset(-150)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.contentView.snp.trailing).offset(-140)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(item: Event) {
        let startDate = self.fromDateFormatter.date(from: item.startDate)
        let endDate = self.fromDateFormatter.date(from: item.endDate)
        self.nameLabel.text = item.title
        self.dateLabel.text = "\(self.toDateFormatter.string(from: startDate!)) - \(self.toDateFormatter.string(from: endDate!))"
    }
}
