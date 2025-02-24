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
                if (realtimeItem.stop <= 1) {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.arriving.\(realtimeItem.stop)"))
                } else {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.no.seat.\(Int(realtimeItem.time)).\(realtimeItem.stop)"))
                }
            } else {
                if (realtimeItem.stop <= 1) {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.arriving.\(realtimeItem.stop).\(realtimeItem.seat)"))
                } else {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.seat.\(Int(realtimeItem.time)).\(realtimeItem.stop).\(realtimeItem.seat)"))
                }
            }
        } else if (item.timetable != nil) {
            let timetableItem = item.timetable!
            self.busTimeLabel.text = String(localized: "bus.realtime.time.\(timetableItem.departureHour).\(timetableItem.departureMinute)")
        }
    }
    
    private func setRealtimeAttributedText(_ text: String) {
        let attributeString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(
            .foregroundColor,
            value: UIColor.red, range: NSRange(
                location: 0,
                length: text.distance(from: text.startIndex, to: text.firstIndex(of: "(")!) - 1
            )
        )
        self.busTimeLabel.attributedText = attributeString
    }
}
