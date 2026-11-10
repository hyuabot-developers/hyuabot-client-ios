//
//  BusTimetableRowCell.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class BusTimetableRowCell: UITableViewCell {
    static let reuseIdentifier = "BusTimetableRowCell"
    static let rowHeight: CGFloat = 44

    private let container = UIView()
    private let rowStack = UIStackView()
    private let timeLabel = UILabel()
    private let spacer = UIView()
    private let chipsStack = UIStackView()
    private var routeBadge: BusRouteBadgeView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(Self.rowHeight)
        }
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.addArrangedSubview(timeLabel)
        rowStack.addArrangedSubview(spacer)
        rowStack.addArrangedSubview(chipsStack)
        container.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        timeLabel.snp.makeConstraints { $0.width.equalTo(48) }
        chipsStack.axis = .horizontal
        chipsStack.alignment = .center
        chipsStack.spacing = 4
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.numberOfLines = 1
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ row: BusTimetableRowModel, showsRouteBadge: Bool) {
        routeBadge?.removeFromSuperview()
        routeBadge = nil
        if showsRouteBadge {
            let badge = BusRouteBadgeView(size: .timetable)
            badge.configure(route: row.entry.route)
            rowStack.insertArrangedSubview(badge, at: 0)
            rowStack.setCustomSpacing(6, after: badge)
            routeBadge = badge
        }
        rowStack.spacing = showsRouteBadge ? 6 : 12
        let timeColor: UIColor
        switch row.state {
        case .past: timeColor = SettingsStyle.Color.subwayPast
        case .next: timeColor = SettingsStyle.Color.link
        case .upcoming: timeColor = SettingsStyle.Color.text
        }
        timeLabel.attributedText = SettingsStyle.attributedText(
            row.entry.timeText,
            font: SettingsStyle.monospacedDigitFont(17, bold: row.state != .past),
            color: timeColor,
            lineHeight: 22
        )
        container.backgroundColor = isNext(row.state) ? SettingsStyle.Color.commuterNearRow : SettingsStyle.Color.card
        chipsStack.arrangedSubviews.forEach { view in chipsStack.removeArrangedSubview(view); view.removeFromSuperview() }
        if case let .next(minutesUntil) = row.state {
            let text = minutesUntil <= 0
                ? String(localized: "bus.timetable.chip.soon")
                : String(format: String(localized: "bus.timetable.chip.minutes.%lld"), minutesUntil)
            chipsStack.addArrangedSubview(chip(
                text, fill: SettingsStyle.Color.accent, foreground: SettingsStyle.Color.onAccent
            ))
        }
        if row.entry.isFirst {
            chipsStack.addArrangedSubview(chip(
                String(localized: "bus.timetable.chip.first"),
                fill: SettingsStyle.Color.segmentBackground, foreground: SettingsStyle.Color.secondaryText
            ))
        }
        if row.entry.isLast {
            chipsStack.addArrangedSubview(chip(
                String(localized: "bus.timetable.chip.last"),
                fill: SettingsStyle.Color.subwayLastFill, foreground: SettingsStyle.Color.subwayLastText
            ))
        }
        accessibilityLabel = accessibilityText(row, showsRouteBadge: showsRouteBadge)
        isAccessibilityElement = true
    }

    private func isNext(_ state: BusTimetableRowModel.State) -> Bool {
        if case .next = state { return true }
        return false
    }

    private func chip(_ text: String, fill: UIColor, foreground: UIColor) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = SettingsStyle.monospacedDigitFont(12, bold: true)
        label.textColor = foreground
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        let view = UIView()
        view.backgroundColor = fill
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        view.addSubview(label)
        label.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(6); $0.centerY.equalToSuperview() }
        view.snp.makeConstraints { $0.height.equalTo(20) }
        return view
    }

    private func accessibilityText(_ row: BusTimetableRowModel, showsRouteBadge: Bool) -> String {
        var parts = [row.entry.timeText]
        if showsRouteBadge {
            parts.append(String(format: String(localized: "bus.realtime.route.%@"), row.entry.route))
        }
        if case .past = row.state { parts.append(String(localized: "bus.timetable.a11y.past")) }
        if case let .next(minutesUntil) = row.state {
            let text = minutesUntil <= 0
                ? String(localized: "bus.timetable.chip.soon")
                : String(format: String(localized: "bus.timetable.chip.minutes.%lld"), minutesUntil)
            parts.append(text)
        }
        if row.entry.isFirst { parts.append(String(localized: "bus.timetable.chip.first")) }
        if row.entry.isLast { parts.append(String(localized: "bus.timetable.chip.last")) }
        return parts.joined(separator: ", ")
    }
}
