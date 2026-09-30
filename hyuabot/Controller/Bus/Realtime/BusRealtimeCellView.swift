import Api
import Foundation
import UIKit

class BusRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "BusRealtimeCellView"

    private let routeMarkerView = UIView().then {
        $0.layer.cornerRadius = 2
    }

    private let busRouteLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
    }

    private let lowFloorBadgeLabel = UILabel().then {
        $0.text = String(localized: "bus.realtime.low.floor")
        $0.font = .godo(size: 11, weight: .bold)
        $0.textColor = .black
        $0.textAlignment = .center
        $0.backgroundColor = .hanyangGreen
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    private lazy var routeStackView = UIStackView(arrangedSubviews: [routeMarkerView, busRouteLabel, lowFloorBadgeLabel]).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 6
    }

    private let busTimeLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.numberOfLines = 0
    }

    private let secondaryDestinationLabel = UILabel().then {
        $0.font = .godo(size: 13, weight: .regular)
        $0.textColor = .label
        $0.textAlignment = .right
        $0.numberOfLines = 0
        $0.isHidden = true
    }

    private lazy var timeStackView = UIStackView(arrangedSubviews: [busTimeLabel, secondaryDestinationLabel]).then {
        $0.axis = .vertical
        $0.alignment = .trailing
        $0.spacing = 3
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(routeStackView)
        contentView.addSubview(timeStackView)
        routeStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(timeStackView.snp.leading).offset(-10)
        }
        routeMarkerView.snp.makeConstraints { make in
            make.width.equalTo(4)
            make.height.equalTo(22)
        }
        lowFloorBadgeLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(32)
            make.height.equalTo(20)
        }
        timeStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.verticalEdges.equalToSuperview().inset(12)
            make.leading.greaterThanOrEqualTo(routeStackView.snp.trailing).offset(10)
        }
        contentView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
        }
    }

    func setupUI(item: BusArrivalItem, showSecondary: Bool = true) {
        busRouteLabel.text = item.route
        lowFloorBadgeLabel.isHidden = item.item.lowFloor != true
        busRouteLabel.textColor = .label
        routeMarkerView.backgroundColor = item.route == "10-1" || item.route == "50" ? .busGreen : .busRed
        setUITimeLabel(item: item, showSecondary: showSecondary)
    }

    private func setUITimeLabel(item: BusArrivalItem, showSecondary: Bool) {
        let arrival = item.item
        let scheduledSource: Api.LocalTime? = item.scheduledTime ?? (arrival.isRealtime ? nil : arrival.arrivalTime)
        if let scheduledSource {
            let minutes = (scheduledSource.toLocalTime().busServiceSeconds - Foundation.Date().busServiceSeconds) / 60
            busTimeLabel.text = String(format: String(localized: "bus.realtime.estimated.%lld"), minutes)
        } else if arrival.isRealtime, let stops = arrival.stops {
            let seats = arrival.seats ?? -1
            if stops <= 1 {
                busTimeLabel.text = seats < 0
                    ? String(format: String(localized: "bus.realtime.arriving.%lld"), stops)
                    : String(format: String(localized: "bus.realtime.arriving.%lld.%lld"), stops, seats)
            } else if let minutes = arrival.minutes {
                busTimeLabel.text = seats < 0
                    ? String(format: String(localized: "bus.realtime.no.seat.%lld.%lld"), Int(minutes), stops)
                    : String(format: String(localized: "bus.realtime.seat.%lld.%lld.%lld"), Int(minutes), stops, seats)
            } else {
                busTimeLabel.text = nil
            }
        } else {
            busTimeLabel.text = nil
        }

        let secondaryText = showSecondary ? Self.secondaryDestinationText(item) : nil
        secondaryDestinationLabel.text = secondaryText
        secondaryDestinationLabel.isHidden = secondaryText == nil
    }

    private static func secondaryDestinationText(_ item: BusArrivalItem) -> String? {
        guard let time = item.secondaryConvertedTime,
              let stopID = item.destinationStopID,
              let stopName = BusDestinationStopName.localized(stopID) else { return nil }
        return String(format: String(localized: "bus.realtime.secondary.destination.%@.%@"), stopName, time)
    }
}

enum BusDestinationStopName {
    static func localized(_ stopID: Int32) -> String? {
        let key: String.LocalizationValue? = switch stopID {
        case 216_000_138: "bus.stop.sangnoksu_station"
        case 216_000_378: "bus.stop.convention"
        case 216_000_048: "bus.stop.hanyang_university"
        case 216_000_141: "bus.stop.entrance"
        case 202_000_208: "bus.stop.suwon_station"
        case 216_000_117: "bus.stop.seongpo"
        case 226_000_042: "bus.stop.uiwang_city_hall"
        case 225_000_116: "bus.stop.gunpo_city_hall"
        case 213_000_487: "home.destination.gwangmyeong"
        case 121_000_060: "bus.stop.seocho"
        case 121_000_929: "bus.stop.gyodae"
        case 121_000_974: "bus.stop.gangnam"
        case 121_000_970: "bus.stop.yangjae"
        case 121_000_220: "bus.stop.yangjae_forest"
        default: nil
        }
        guard let key else { return nil }
        return String(localized: key)
    }
}
