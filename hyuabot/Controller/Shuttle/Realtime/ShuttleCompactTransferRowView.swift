//
//  ShuttleCompactTransferRowView.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class ShuttleCompactTransferRowView: UIView {
    static let rowHeight: CGFloat = 48
    private let badge = BusRouteBadgeView(size: .shuttle)
    private let dividerView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.separator
    }

    private let routeLabel = UILabel().then {
        $0.font = SettingsStyle.font(14, bold: true)
        $0.textColor = SettingsStyle.Color.text
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.75
        $0.numberOfLines = 1
    }

    private let arrivalLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(15, bold: true)
        $0.textColor = SettingsStyle.Color.text
        $0.textAlignment = .right
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.65
    }

    var hidesDivider = false {
        didSet { dividerView.isHidden = hidesDivider }
    }

    init(row: TransferRow) {
        super.init(frame: .zero)
        backgroundColor = .clear
        badge.configure(text: row.name, fill: row.color)
        routeLabel.text = Self.routeText(row: row)
        arrivalLabel.text = Self.arrivalText(row: row)

        addSubview(dividerView)
        addSubview(badge)
        addSubview(routeLabel)
        addSubview(arrivalLabel)
        dividerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        badge.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(72)
        }
        routeLabel.snp.makeConstraints { make in
            make.leading.equalTo(badge.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        arrivalLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(routeLabel.snp.trailing).offset(10)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        arrivalLabel.setContentHuggingPriority(.required, for: .horizontal)
        arrivalLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        isAccessibilityElement = true
        accessibilityLabel = [row.name, routeLabel.text, arrivalLabel.text]
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
            row.timeline.first?.destination ?? ""
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
