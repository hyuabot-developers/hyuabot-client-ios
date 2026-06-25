import RxSwift
import UIKit

class BusTimetableCellView: UITableViewCell {
    static let reuseIdentifier = "BusTimetableCellView"
    private let busRouteLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }

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
        contentView.addSubview(busRouteLabel)
        contentView.addSubview(busTimeLabel)
        selectionStyle = .none
        busRouteLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        busTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(item: BusTimetableItem) {
        busRouteLabel.text = item.route
        setRouteColor(routeName: item.route)
        let components = Calendar.current.dateComponents([.hour, .minute], from: item.time)
        busTimeLabel.text = String(
            format: String(localized: "bus.timetable.time.%lld.%lld"),
            components.hour!,
            components.minute!
        )
    }

    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            busRouteLabel.textColor = .busGreen
        } else {
            busRouteLabel.textColor = .busRed
        }
    }
}
