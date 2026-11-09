//
//  ShuttleTimetableCellView.swift
//  hyuabot
//

import Api
import UIKit

class ShuttleTimetableCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleTimetableCellView"
    var item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order?
    private let shuttleTypeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .regular)
    }

    private let shuttleTimeLabel = UILabel().then {
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

    private func setupUI() {
        contentView.addSubview(shuttleTypeLabel)
        contentView.addSubview(shuttleTimeLabel)
        selectionStyle = .none
        shuttleTypeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.verticalEdges.equalToSuperview().inset(15)
        }
        shuttleTimeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }
    }

    func setupUI(
        option: ShuttleTimetableOptions,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        switch option.start {
        case "shuttle.stop.dormitory.out", "shuttle.stop.shuttlecock.out":
            configureOutbound(option: option, item: item)
        case "shuttle.stop.station":
            configureStationDestination(option: option, item: item)
        case "shuttle.stop.terminal", "shuttle.stop.jungang.station", "shuttle.stop.shuttlecock.in":
            configureInbound(item: item)
        default:
            break
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: item.time.toLocalTime())
        shuttleTimeLabel.text = String(
            format: String(localized: "shuttle.time.%lld.%lld"),
            components.hour ?? 0,
            components.minute ?? 0
        )
        self.item = item
    }

    private func configureOutbound(
        option: ShuttleTimetableOptions,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        if option.end == "shuttle.destination.shorten.station" {
            configureOutboundStationRoute(item.route.tag)
        } else if option.end == "shuttle.destination.shorten.terminal" {
            configureTerminalRoute(item.route.tag)
        } else if option.end == "shuttle.destination.shorten.jungang_station" {
            setJungangStationType()
        }
    }

    private func configureOutboundStationRoute(_ routeTag: String) {
        if routeTag == "DH" || routeTag == "DJ" {
            shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
            shuttleTypeLabel.textColor = .busRed
        } else if routeTag == "C" {
            setCircularType()
        }
    }

    private func configureTerminalRoute(_ routeTag: String) {
        if routeTag == "DY" {
            shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
            shuttleTypeLabel.textColor = .busRed
        } else if routeTag == "C" {
            setCircularType()
        }
    }

    private func configureStationDestination(
        option: ShuttleTimetableOptions,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        if option.end == "shuttle.destination.shorten.campus" {
            configureCampusRoute(item.route.tag)
        } else if option.end == "shuttle.destination.shorten.terminal" {
            setCircularType()
        } else if option.end == "shuttle.destination.shorten.jungang_station" {
            setJungangStationType()
        }
    }

    private func configureCampusRoute(_ routeTag: String) {
        if routeTag == "DH" {
            shuttleTypeLabel.text = String(localized: "shuttle.type.direct")
            shuttleTypeLabel.textColor = .busRed
        } else if routeTag == "DJ" {
            setJungangStationType()
        } else if routeTag == "C" {
            setCircularType()
        }
    }

    private func configureInbound(
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        shuttleTypeLabel.textColor = .label
        if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
        } else if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
        }
    }

    private func setJungangStationType() {
        shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
        shuttleTypeLabel.textColor = .hanyangGreen
    }

    private func setCircularType() {
        shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
        shuttleTypeLabel.textColor = UITraitCollection.current.userInterfaceStyle == .light ? .busBlue : .white
    }
}
