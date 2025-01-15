import UIKit
import QueryAPI
import RxSwift

class BusLogCell: UITableViewCell {
    static let reuseIdentifier = "BusLogCell"
    private let busTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.busTimeLabel)
        self.selectionStyle = .none
        self.busTimeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func setupUI(index: Int, item: BusDepartureLogDialogQuery.Data.Bus.Route.Log) {
        let departureTime = item.departureTime.substring(from: 0, to: 4)
        self.busTimeLabel.text = departureTime
        if index % 2 == 0 {
            self.backgroundColor = .hanyangBlue
            self.busTimeLabel.textColor = .white
        } else {
            self.backgroundColor = .systemBackground
            self.busTimeLabel.textColor = .label
        }
    }
}
