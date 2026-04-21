import UIKit
import Api
import RxSwift
import Foundation

class BusRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "BusRealtimeCellView"
    private let calendar = Calendar.current
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
    
    func setupUI(item: BusArrivalItem) {
        self.busRouteLabel.text = item.route
        self.setRouteColor(routeName: item.route)
        self.setUITimeLabel(item: item)
    }
    
    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            self.busRouteLabel.textColor = .busGreen
        } else {
            self.busRouteLabel.textColor = .busRed
        }
    }
    
    func setUITimeLabel(item: BusArrivalItem) {
        if (item.item.isRealtime) {
            if (item.item.seats! < 0) {
                if (item.item.stops! <= 1) {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.arriving.\(item.item.stops!)"))
                } else {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.no.seat.\(Int(item.item.minutes!)).\(item.item.stops!)"))
                }
            } else {
                if (item.item.stops! <= 1) {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.arriving.\(item.item.stops!).\(item.item.seats!)"))
                } else {
                    self.setRealtimeAttributedText(String(localized: "bus.realtime.seat.\(Int(item.item.minutes!)).\(item.item.stops!).\(item.item.seats!)"))
                }
            }
        } else if (!item.item.isRealtime) {
            let time = self.calendar.dateComponents([.hour, .minute], from: item.item.time!.toLocalTime())
            self.busTimeLabel.text = String(localized: "bus.realtime.time.\(time.hour!).\(time.minute!)")
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
