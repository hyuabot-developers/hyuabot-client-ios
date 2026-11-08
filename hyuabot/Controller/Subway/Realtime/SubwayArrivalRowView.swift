//
//  SubwayArrivalRowView.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwayArrivalRowView: UIView {
    private let destinationLabel = UILabel()
    private let lastTrainLabel = HYUPaddedLabel()
    private let subtitleLabel = UILabel()
    private let minutesLabel = UILabel()
    private let separator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildView()
    }

    func configure(_ model: SubwayArrivalRowModel, showsSeparator: Bool) {
        isAccessibilityElement = true
        accessibilityLabel = model.accessibilityLabel

        destinationLabel.font = SettingsStyle.font(17, bold: true)
        destinationLabel.textColor = SettingsStyle.Color.text
        destinationLabel.setKoreanTranslatedText(model.destination)
        destinationLabel.lineBreakMode = .byTruncatingTail
        destinationLabel.attributedText = SettingsStyle.attributedText(
            destinationLabel.text ?? model.destination,
            font: SettingsStyle.font(17, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22,
            lineBreakMode: .byTruncatingTail
        )
        destinationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        lastTrainLabel.text = String(localized: "subway.chip.last")
        lastTrainLabel.isHidden = !model.isLast

        subtitleLabel.font = SettingsStyle.font(13)
        subtitleLabel.textColor = SettingsStyle.Color.secondaryText
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle == nil
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.attributedText = model.subtitle.map {
            SettingsStyle.attributedText(
                $0,
                font: SettingsStyle.font(13),
                color: SettingsStyle.Color.secondaryText,
                lineHeight: 18,
                lineBreakMode: .byTruncatingTail
            )
        }

        minutesLabel.text = model.minutesText
        minutesLabel.textAlignment = .right
        minutesLabel.font = SettingsStyle.monospacedDigitFont(20, bold: model.isRealtime)
        minutesLabel.textColor = model.isSoon
            ? SettingsStyle.Color.subwaySoon
            : (model.isRealtime ? SettingsStyle.Color.text : SettingsStyle.Color.commuterFaint)
        minutesLabel.attributedText = SettingsStyle.attributedText(
            model.minutesText,
            font: SettingsStyle.monospacedDigitFont(20, bold: model.isRealtime),
            color: minutesLabel.textColor,
            lineHeight: 24,
            alignment: .right
        )
        minutesLabel.setContentHuggingPriority(.required, for: .horizontal)
        minutesLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        separator.isHidden = !showsSeparator
    }

    private func buildView() {
        lastTrainLabel.padding = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        lastTrainLabel.font = SettingsStyle.font(12, bold: true)
        lastTrainLabel.textColor = SettingsStyle.Color.subwayLastText
        lastTrainLabel.backgroundColor = SettingsStyle.Color.subwayLastFill
        lastTrainLabel.layer.cornerRadius = 6
        lastTrainLabel.clipsToBounds = true
        lastTrainLabel.snp.makeConstraints { $0.height.equalTo(20) }
        lastTrainLabel.setContentHuggingPriority(.required, for: .horizontal)
        lastTrainLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleLine = UIStackView(arrangedSubviews: [destinationLabel, lastTrainLabel])
        titleLine.axis = .horizontal
        titleLine.alignment = .center
        titleLine.spacing = 6

        let leftColumn = UIStackView(arrangedSubviews: [titleLine, subtitleLabel])
        leftColumn.axis = .vertical
        leftColumn.spacing = 4

        let content = UIStackView(arrangedSubviews: [leftColumn, minutesLabel])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12

        separator.backgroundColor = SettingsStyle.Color.separator
        addSubview(content)
        addSubview(separator)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.greaterThanOrEqualToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        minutesLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(52)
        }
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
