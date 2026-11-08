//
//  SubwayTimetableRowCell.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwayTimetableRowCell: UITableViewCell {
    static let reuseIdentifier = "SubwayTimetableRowCell"
    private let strip = UIView()
    private let timeLabel = UILabel()
    private let dot = UIView()
    private let destinationLabel = UILabel()
    private let chips = UIStackView()
    private let rowStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(strip)
        strip.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }
        strip.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        strip.addSubview(rowStack)
        rowStack.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(11)
            $0.bottom.lessThanOrEqualToSuperview().inset(11)
        }
        [timeLabel, dot, destinationLabel, chips].forEach { rowStack.addArrangedSubview($0) }
        rowStack.setCustomSpacing(8, after: dot)
        timeLabel.snp.makeConstraints { $0.width.equalTo(48) }
        dot.snp.makeConstraints {
            $0.width.equalTo(8).priority(999)
            $0.height.equalTo(8)
        }
        chips.axis = .horizontal
        chips.spacing = 4
        chips.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        destinationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        destinationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        destinationLabel.lineBreakMode = .byTruncatingTail
        timeLabel.textColor = SettingsStyle.Color.text
        destinationLabel.textColor = SettingsStyle.Color.text
        dot.layer.cornerRadius = 4
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ row: SubwayTimetableRowModel, merged: Bool = false) {
        let timeColor = row.isPast ? SettingsStyle.Color.subwayPast : (row.isNext ? SettingsStyle.Color.link : SettingsStyle.Color.text)
        timeLabel.attributedText = SettingsStyle.attributedText(
            row.timeText,
            font: SettingsStyle.monospacedDigitFont(17, bold: !row.isPast),
            color: timeColor,
            lineHeight: 22
        )
        destinationLabel.setKoreanTranslatedText(row.destination)
        destinationLabel.attributedText = SettingsStyle.attributedText(
            destinationLabel.text ?? "",
            font: SettingsStyle.font(15, bold: row.isNext),
            color: row.isPast ? SettingsStyle.Color.subwayPast : SettingsStyle.Color.text,
            lineHeight: 20
        )
        strip.backgroundColor = row.isNext ? SettingsStyle.Color.commuterNearRow : SettingsStyle.Color.card
        dot.isHidden = !merged
        dot.backgroundColor = SubwayDisplayLogic.routeLine(row.line).color
        chips.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let nextText = row.nextText {
            addChip(
                nextText,
                background: SettingsStyle.Color.accent,
                foreground: SettingsStyle.Color.onAccent
            )
        }
        if row.isFirst {
            addChip(
                String(localized: "subway.chip.first"),
                background: SettingsStyle.Color.segmentBackground,
                foreground: SettingsStyle.Color.secondaryText
            )
        }
        if row.isLast {
            addChip(
                String(localized: "subway.chip.last"),
                background: SettingsStyle.Color.subwayLastFill,
                foreground: SettingsStyle.Color.subwayLastText
            )
        }
        accessibilityLabel = row.accessibilityLabel
    }

    private func addChip(_ text: String, background: UIColor, foreground: UIColor) {
        let label = HYUPaddedLabel()
        label.padding = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        label.text = text
        label.attributedText = SettingsStyle.attributedText(
            text,
            font: SettingsStyle.monospacedDigitFont(12, bold: true),
            color: foreground,
            lineHeight: 16
        )
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.textColor = foreground
        label.backgroundColor = background
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.snp.makeConstraints { $0.height.equalTo(20) }
        chips.addArrangedSubview(label)
    }
}
