import Api
import RxSwift
import UIKit

class BusLogCell: UITableViewCell {
    static let reuseIdentifier = "BusLogCell"
    private let busTimeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
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
        contentView.addSubview(busTimeLabel)
        selectionStyle = .none
        busTimeLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func setupUI(index: Int, item: BusDepartureLogDialogQuery.Data.Bus.Log) {
        let departureTime = item.time.substring(from: 0, to: 4)
        busTimeLabel.text = departureTime
        if index % 2 == 0 {
            backgroundColor = .hanyangBlue
            busTimeLabel.textColor = .white
        } else {
            backgroundColor = .systemBackground
            busTimeLabel.textColor = .label
        }
    }
}
