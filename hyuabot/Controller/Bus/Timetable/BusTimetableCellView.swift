import UIKit
import QueryAPI
import RxSwift

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
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.contentView.addSubview(self.busRouteLabel)
        self.contentView.addSubview(self.busTimeLabel)
        self.selectionStyle = .none
        self.busRouteLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        self.busTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupUI(item: BusTimetableItem) {
        self.busRouteLabel.text = item.routeName
        self.setRouteColor(routeName: item.routeName)
        self.busTimeLabel.text = String(localized: "bus.timetable.time.\(item.timetable.departureHour).\(item.timetable.departureMinute)")
    }
    
    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            self.busRouteLabel.textColor = .busGreen
        } else {
            self.busRouteLabel.textColor = .busRed
        }
    }
}
