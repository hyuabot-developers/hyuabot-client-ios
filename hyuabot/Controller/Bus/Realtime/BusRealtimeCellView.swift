import UIKit
import QueryAPI
import RxSwift

class BusRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "BusRealtimeCellView"
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
    
    func setupUI(item: BusRealtimeItem) {
        self.busRouteLabel.text = item.routeName
        self.setRouteColor(routeName: item.routeName)
        self.setUITimeLabel(item: item)
    }
    
    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            self.busRouteLabel.textColor = .busGreen
        } else {
            self.busRouteLabel.textColor = .busRed
        }
    }
    
    func setUITimeLabel(item: BusRealtimeItem) {
        if (item.realtime != nil) {
            let realtimeItem = item.realtime!
            if (realtimeItem.seat < 0) {
                self.busTimeLabel.text = String(localized: "bus.realtime.no.seat.\(Int(realtimeItem.time)).\(realtimeItem.stop)")
            } else {
                self.busTimeLabel.text = String(localized: "bus.realtime.seat.\(Int(realtimeItem.time)).\(realtimeItem.stop).\(realtimeItem.seat)")
            }
        } else if (item.timetable != nil) {
            let timetableItem = item.timetable!
            let calendar = Calendar.current
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            let departureTime = dateFormatter.date(from: timetableItem.time)
            let hour = calendar.component(.hour, from: departureTime!)
            let minute = calendar.component(.minute, from: departureTime!)
            self.busTimeLabel.text = String(localized: "bus.realtime.time.\(hour).\(minute)")
        }
    }
}
