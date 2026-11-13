//
//  BusArrivalRowView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class BusArrivalRowView: UIView {
    private let routeBadge = BusRouteBadgeView(size: .small)
    private let primaryLabel = UILabel()
    private let lowFloorLabel = HYUPaddedLabel()
    private let detailLabel = UILabel()
    private let minutesLabel = UILabel()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildView()
    }

    func configure(_ model: BusArrivalRowModel, showsRouteBadge: Bool, showsSeparator: Bool) {
        isAccessibilityElement = true
        routeBadge.isHidden = !showsRouteBadge
        if showsRouteBadge {
            routeBadge.configure(route: model.route)
        }
        configurePrimary(model)
        configureLowFloor(model.isLowFloor)
        let details = detailParts(model)
        configureDetail(details, model: model)
        configureMinutes(model.remaining, isRealtime: model.isRealtime)
        separator.isHidden = !showsSeparator
        var accessibilityParts: [String] = []
        if showsRouteBadge {
            accessibilityParts.append(String(format: String(localized: "bus.realtime.route.%@"), model.route))
        }
        accessibilityParts.append(minutesLabel.text ?? "")
        accessibilityParts.append(primaryLabel.text ?? "")
        if model.isLowFloor {
            accessibilityParts.append(String(localized: "bus.realtime.low.floor"))
        }
        accessibilityParts.append(contentsOf: details)
        accessibilityLabel = accessibilityParts.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    private func configurePrimary(_ model: BusArrivalRowModel) {
        let value: String
        switch model.primary {
        case let .stopsBefore(count):
            value = String(format: String(localized: "bus.realtime.stops_before.%lld"), count)
        case .waitingAtOrigin:
            value = String(localized: "bus.realtime.waiting_at_origin")
        }
        primaryLabel.text = value
        primaryLabel.attributedText = SettingsStyle.attributedText(
            value, font: SettingsStyle.font(13), color: SettingsStyle.Color.secondaryText,
            lineHeight: 18, alignment: .right,
            lineBreakMode: .byTruncatingTail
        )
        primaryLabel.adjustsFontForContentSizeCategory = true
    }

    private func configureLowFloor(_ isLowFloor: Bool) {
        lowFloorLabel.text = String(localized: "bus.realtime.low.floor")
        lowFloorLabel.isHidden = !isLowFloor
    }

    private func detailParts(_ model: BusArrivalRowModel) -> [String] {
        var parts: [String] = []
        switch model.seats {
        case let .available(count):
            parts.append(String(format: String(localized: "bus.realtime.seats_left.%lld"), count))
        case .full:
            parts.append(String(localized: "bus.realtime.no_seats"))
        case .unknown:
            break
        }
        if let eta = BusDisplayLogic.destinationETA(model) {
            parts.append(eta)
        }
        return parts
    }

    private func configureDetail(_ parts: [String], model: BusArrivalRowModel) {
        let value = parts.joined(separator: " · ")
        let color = model.seats == .full && model.isRealtime
            ? SettingsStyle.Color.subwayLastText
            : SettingsStyle.Color.secondaryText
        detailLabel.text = value
        detailLabel.isHidden = value.isEmpty
        detailLabel.attributedText = value.isEmpty ? nil : SettingsStyle.attributedText(
            value,
            font: SettingsStyle.font(13),
            color: color,
            lineHeight: 18,
            lineBreakMode: .byTruncatingTail
        )
        detailLabel.adjustsFontForContentSizeCategory = true
    }

    private func configureMinutes(_ remaining: BusArrivalRowModel.Remaining, isRealtime: Bool) {
        let value = BusDisplayLogic.remainingText(remaining)
        let color = remaining == .soon
            ? SettingsStyle.Color.subwaySoon
            : (isRealtime ? SettingsStyle.Color.text : SettingsStyle.Color.commuterFaint)
        minutesLabel.text = value
        minutesLabel.attributedText = SettingsStyle.attributedText(
            value,
            font: SettingsStyle.monospacedDigitFont(20, bold: isRealtime),
            color: color,
            lineHeight: 24,
            alignment: .right
        )
        minutesLabel.adjustsFontForContentSizeCategory = true
    }

    private func buildView() {
        primaryLabel.numberOfLines = 1
        primaryLabel.lineBreakMode = .byTruncatingTail
        primaryLabel.textAlignment = .right
        detailLabel.numberOfLines = 1
        detailLabel.lineBreakMode = .byTruncatingTail
        lowFloorLabel.textColor = SettingsStyle.Color.busLowFloorText
        lowFloorLabel.backgroundColor = SettingsStyle.Color.busLowFloorFill
        lowFloorLabel.padding = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        lowFloorLabel.font = SettingsStyle.font(12, bold: true)
        lowFloorLabel.layer.cornerRadius = 6
        lowFloorLabel.clipsToBounds = true
        lowFloorLabel.adjustsFontForContentSizeCategory = true
        lowFloorLabel.snp.makeConstraints { $0.height.equalTo(20) }
        lowFloorLabel.setContentHuggingPriority(.required, for: .horizontal)
        lowFloorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLine = UIStackView(arrangedSubviews: [routeBadge, lowFloorLabel])
        titleLine.axis = .horizontal
        titleLine.alignment = .center
        titleLine.spacing = 6
        let leftColumn = UIStackView(arrangedSubviews: [titleLine, detailLabel])
        leftColumn.axis = .vertical
        leftColumn.alignment = .leading
        leftColumn.spacing = 4
        leftColumn.setContentHuggingPriority(.defaultLow, for: .horizontal)
        leftColumn.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let rightColumn = UIStackView(arrangedSubviews: [minutesLabel, primaryLabel])
        rightColumn.axis = .vertical
        rightColumn.alignment = .trailing
        rightColumn.spacing = 2
        rightColumn.setContentHuggingPriority(.required, for: .horizontal)
        rightColumn.setContentCompressionResistancePriority(.required, for: .horizontal)
        routeBadge.setContentHuggingPriority(.required, for: .horizontal)
        routeBadge.setContentCompressionResistancePriority(.required, for: .horizontal)
        let content = UIStackView(arrangedSubviews: [leftColumn, rightColumn])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        minutesLabel.textAlignment = .right
        minutesLabel.setContentHuggingPriority(.required, for: .horizontal)
        minutesLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        separator.backgroundColor = SettingsStyle.Color.separator
        addSubview(content)
        addSubview(separator)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.greaterThanOrEqualToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        minutesLabel.snp.makeConstraints { $0.width.greaterThanOrEqualTo(52) }
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(64) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
