//
//  ReadingRoomAlarmCardView.swift
//  hyuabot
//

import SnapKit
import UIKit

struct ReadingRoomAlarmSchedule: Equatable {
    let notifyAt: Foundation.Date
    let hours: Int?
    var endsAt: Foundation.Date { notifyAt.addingTimeInterval(10 * 60) }
}

final class ReadingRoomAlarmCardView: UIView {
    var onSchedule: ((Int) -> Void)?
    var onCancel: (() -> Void)?
    private let buttonsRow = UIStackView()
    private let scheduledView = UIView()
    private let timeLabel = UILabel()
    private let detailLabel = UILabel()
    let threeHourButton: UIButton
    let fourHourButton: UIButton
    let cancelButton: UIButton

    override init(frame: CGRect) {
        var threeConfig = UIButton.Configuration.filled()
        threeConfig.baseBackgroundColor = SettingsStyle.Color.accentFill
        threeConfig.baseForegroundColor = SettingsStyle.Color.link
        threeConfig.background.cornerRadius = 12
        threeConfig.cornerStyle = .fixed
        threeConfig.attributedTitle = AttributedString(
            String(localized: "reading_room.alarm.3hour"),
            attributes: AttributeContainer([.font: SettingsStyle.font(15, bold: true)])
        )
        threeHourButton = UIButton(configuration: threeConfig)
        var fourConfig = threeConfig
        fourConfig.attributedTitle = AttributedString(
            String(localized: "reading_room.alarm.4hour"),
            attributes: AttributeContainer([.font: SettingsStyle.font(15, bold: true)])
        )
        fourHourButton = UIButton(configuration: fourConfig)
        var cancelConfig = UIButton.Configuration.filled()
        cancelConfig.baseBackgroundColor = SettingsStyle.Color.card
        cancelConfig.baseForegroundColor = SettingsStyle.Color.danger
        cancelConfig.cornerStyle = .capsule
        cancelConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        cancelConfig.attributedTitle = AttributedString(
            String(localized: "reading_room.alarm.cancel"),
            attributes: AttributeContainer([.font: SettingsStyle.font(14, bold: true)])
        )
        cancelButton = UIButton(configuration: cancelConfig)
        super.init(frame: frame)

        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        layer.cornerCurve = .continuous
        let headerRow = makeHeaderRow()
        configureButtonsRow()
        configureScheduledView()
        let stack = UIStackView(arrangedSubviews: [headerRow, buttonsRow, scheduledView])
        stack.axis = .vertical
        stack.spacing = 16
        addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(16) }
        scheduledView.isHidden = true
    }

    private func makeHeaderRow() -> UIStackView {
        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 12
        let iconCircle = UIView()
        iconCircle.backgroundColor = SettingsStyle.Color.accentFill
        iconCircle.layer.cornerRadius = 20
        iconCircle.snp.makeConstraints { $0.size.equalTo(40) }
        let icon = UIImageView(
            image: UIImage(
                systemName: "timer",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
            )
        )
        icon.tintColor = SettingsStyle.Color.link
        iconCircle.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        headerRow.addArrangedSubview(iconCircle)
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        let titleLabel = UILabel()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "reading_room.alarm.title"),
            font: SettingsStyle.font(16, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22
        )
        let captionLabel = UILabel()
        captionLabel.numberOfLines = 1
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "reading_room.alarm.caption"),
            font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18,
            lineBreakMode: .byTruncatingTail
        )
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(captionLabel)
        headerRow.addArrangedSubview(textStack)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return headerRow
    }

    private func configureButtonsRow() {
        buttonsRow.axis = .horizontal
        buttonsRow.distribution = .fillEqually
        buttonsRow.spacing = 8
        buttonsRow.addArrangedSubview(threeHourButton)
        buttonsRow.addArrangedSubview(fourHourButton)
        [threeHourButton, fourHourButton].forEach { $0.snp.makeConstraints { $0.height.greaterThanOrEqualTo(48) } }
        threeHourButton.accessibilityIdentifier = "reading_room.alarm_3hour"
        fourHourButton.accessibilityIdentifier = "reading_room.alarm_4hour"
        threeHourButton.addTarget(self, action: #selector(scheduleThree), for: .touchUpInside)
        fourHourButton.addTarget(self, action: #selector(scheduleFour), for: .touchUpInside)

        scheduledView.backgroundColor = SettingsStyle.Color.accentFill
        scheduledView.layer.cornerRadius = 12
        scheduledView.layer.cornerCurve = .continuous
    }

    private func configureScheduledView() {
        let scheduledStack = UIStackView()
        scheduledStack.axis = .horizontal
        scheduledStack.alignment = .center
        scheduledStack.spacing = 12
        scheduledView.addSubview(scheduledStack)
        scheduledStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 12))
        }
        let detailStack = UIStackView(arrangedSubviews: [timeLabel, detailLabel])
        detailStack.axis = .vertical
        detailStack.spacing = 2
        detailStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        scheduledStack.addArrangedSubview(detailStack)
        scheduledStack.addArrangedSubview(cancelButton)
        cancelButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cancelButton.accessibilityIdentifier = "reading_room.alarm_cancel"
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        detailLabel.numberOfLines = 1
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.adjustsFontForContentSizeCategory = true

    }

    func setSchedule(_ schedule: ReadingRoomAlarmSchedule?) {
        guard let schedule else {
            buttonsRow.isHidden = false
            scheduledView.isHidden = true
            return
        }
        buttonsRow.isHidden = true
        scheduledView.isHidden = false
        let time = Self.formattedTime(schedule.notifyAt)
        let full = String(format: String(localized: "reading_room.alarm.scheduled_time.%@"), time)
        let attributed = NSMutableAttributedString(
            attributedString: SettingsStyle.attributedText(
                full,
                font: SettingsStyle.font(14),
                color: SettingsStyle.Color.link,
                lineHeight: 30
            )
        )
        attributed.addAttribute(.font, value: SettingsStyle.monospacedDigitFont(24, bold: true), range: (full as NSString).range(of: time))
        timeLabel.attributedText = attributed
        let detail: String
        if let hours = schedule.hours {
            detail = String(format: String(localized: "reading_room.alarm.detail.%lld.%@"), hours, Self.formattedTime(schedule.endsAt))
        } else {
            detail = String(format: String(localized: "reading_room.alarm.detail_end.%@"), Self.formattedTime(schedule.endsAt))
        }
        detailLabel.attributedText = SettingsStyle.attributedText(
            detail,
            font: SettingsStyle.monospacedDigitFont(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18,
            lineBreakMode: .byTruncatingTail
        )
    }

    private static func formattedTime(_ date: Foundation.Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @objc
    private func scheduleThree() { onSchedule?(3) }

    @objc
    private func scheduleFour() { onSchedule?(4) }

    @objc
    private func cancelTapped() { onCancel?() }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
