import Api
import Foundation
import RxSwift
import UIKit

class BusRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "BusRealtimeCellView"
    private let calendar = Calendar.current
    private let busRouteLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }

    private let lowFloorBadgeLabel = UILabel().then {
        $0.text = String(localized: "bus.realtime.low.floor")
        $0.font = .godo(size: 11, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.backgroundColor = .hanyangGreen
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    private lazy var routeStackView = UIStackView(arrangedSubviews: [busRouteLabel, lowFloorBadgeLabel]).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 6
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
        contentView.addSubview(routeStackView)
        contentView.addSubview(busTimeLabel)
        selectionStyle = .none
        routeStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
            make.trailing.lessThanOrEqualTo(self.busTimeLabel.snp.leading).offset(-10)
        }
        lowFloorBadgeLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(32)
            make.height.equalTo(20)
        }
        busTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(item: BusArrivalItem) {
        busRouteLabel.text = item.route
        lowFloorBadgeLabel.isHidden = item.item.lowFloor != true
        setRouteColor(routeName: item.route)
        setUITimeLabel(item: item)
    }

    func setRouteColor(routeName: String) {
        if routeName == "10-1" || routeName == "50" {
            busRouteLabel.textColor = .busGreen
        } else {
            busRouteLabel.textColor = .busRed
        }
    }

    func setUITimeLabel(item: BusArrivalItem) {
        busTimeLabel.attributedText = nil
        busTimeLabel.textColor = .label
        if item.item.isRealtime {
            if item.item.seats! < 0 {
                if item.item.stops! <= 1 {
                    setRealtimeAttributedText(String(format: String(localized: "bus.realtime.arriving.%lld"), item.item.stops!))
                } else {
                    setRealtimeAttributedText(String(
                        format: String(localized: "bus.realtime.no.seat.%lld.%lld"),
                        Int(item.item.minutes!),
                        item.item.stops!
                    ))
                }
            } else {
                if item.item.stops! <= 1 {
                    setRealtimeAttributedText(String(
                        format: String(localized: "bus.realtime.arriving.%lld.%lld"),
                        item.item.stops!,
                        item.item.seats!
                    ))
                } else {
                    setRealtimeAttributedText(String(
                        format: String(localized: "bus.realtime.seat.%lld.%lld.%lld"),
                        Int(item.item.minutes!),
                        item.item.stops!,
                        item.item.seats!
                    ))
                }
            }
        } else if !item.item.isRealtime {
            let arrival = item.item.arrivalTime!.toLocalTime()
            let now = Foundation.Date()
            let toServiceSec: (Foundation.Date) -> Int = { date in
                let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
                let s = (comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60 + (comps.second ?? 0)
                return s < 4 * 3600 ? s + 86400 : s
            }
            let remainingMinutes = (toServiceSec(arrival) - toServiceSec(now)) / 60
            busTimeLabel.text = String(format: String(localized: "bus.realtime.estimated.%lld"), remainingMinutes)
            busTimeLabel.textColor = .secondaryLabel
        }
    }

    private func setRealtimeAttributedText(_ text: String) {
        let attributeString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: attributeString.length))
        attributeString.addAttribute(
            .foregroundColor,
            value: UIColor.red, range: NSRange(
                location: 0,
                length: text.distance(from: text.startIndex, to: text.firstIndex(of: "(")!) - 1
            )
        )
        busTimeLabel.attributedText = attributeString
    }
}
