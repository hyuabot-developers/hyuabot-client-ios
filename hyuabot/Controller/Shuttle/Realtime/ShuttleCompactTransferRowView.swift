//
//  ShuttleCompactTransferRowView.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class ShuttleCompactTransferRowView: UIView {
    private let accentView = UIView()
    private let dividerView = UIView().then {
        $0.backgroundColor = .separator
    }

    private let routeLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .bold)
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.75
    }

    private let arrivalLabel = UILabel().then {
        $0.font = .godo(size: 16, weight: .medium)
        $0.textAlignment = .right
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.65
    }

    init(row: TransferRow) {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        accentView.backgroundColor = row.color
        routeLabel.textColor = row.color
        routeLabel.text = Self.routeText(row: row)
        arrivalLabel.text = Self.arrivalText(row: row)

        addSubview(accentView)
        addSubview(dividerView)
        addSubview(routeLabel)
        addSubview(arrivalLabel)
        accentView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(4)
        }
        dividerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        routeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.42)
        }
        arrivalLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(routeLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        isAccessibilityElement = true
        accessibilityLabel = [routeLabel.text, arrivalLabel.text]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func arrivalText(row: TransferRow) -> String {
        guard let entry = row.timeline.first else { return "" }
        if let waitingText = entry.waitingText {
            return waitingText
        }
        if let scheduledArrivalText = entry.scheduledArrivalText {
            return scheduledArrivalText
        }
        var components: [String] = []
        switch row.vehicleType {
        case .subway:
            if let stops = entry.stops {
                components.append(String(
                    format: String(localized: "home.transfer.subway.realtime.stops"),
                    locale: Locale.current,
                    stops
                ))
            }
        case .bus:
            if let stops = entry.stops {
                components.append(String(
                    format: String(localized: "home.transfer.bus50.realtime.stops"),
                    locale: Locale.current,
                    stops
                ))
            }
        }
        if let minutes = entry.minutes {
            components.append(String(
                format: String(localized: "home.minutes"),
                locale: Locale.current,
                minutes
            ))
        }
        return components.joined(separator: " · ")
    }

    private static func routeText(row: TransferRow) -> String {
        switch row.vehicleType {
        case .bus:
            row.name
        case .subway:
            if let destination = row.timeline.first?.destination {
                String(
                    format: String(localized: "subway.terminal.%@"),
                    locale: Locale.current,
                    destination
                )
            } else {
                row.name
            }
        }
    }
}
