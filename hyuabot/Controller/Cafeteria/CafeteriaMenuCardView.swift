//
//  CafeteriaMenuCardView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaMenuCardView: UIView {
    let infoButton = UIButton(type: .system)
    var onInfoTap: ((Int) -> Void)?

    private let header = UIView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let statusChip = UIStackView()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let separator = UIView()
    private let rowsStack = UIStackView()
    private var model: CafeteriaCardModel?
    private var configurationID = UUID()
    private var translationTask: Task<Void, Never>?
    private var translatedRows: [[String?]] = []

    init() {
        super.init(frame: .zero)
        clipsToBounds = true
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        backgroundColor = SettingsStyle.Color.card
        addSubview(header)
        addSubview(separator)
        addSubview(rowsStack)
        nameLabel.font = SettingsStyle.font(17, bold: true)
        nameLabel.textColor = SettingsStyle.Color.text
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        let left = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        left.axis = .vertical
        left.alignment = .leading
        left.spacing = 4
        header.addSubview(left)
        header.addSubview(statusChip)
        header.addSubview(infoButton)
        timeLabel.font = SettingsStyle.monospacedDigitFont(13)
        timeLabel.textColor = SettingsStyle.Color.secondaryText
        timeLabel.numberOfLines = 1
        infoButton.setImage(
            UIImage(systemName: "info.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)),
            for: .normal
        )
        infoButton.tintColor = SettingsStyle.Color.commuterFaint
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        statusChip.axis = .horizontal
        statusChip.alignment = .center
        statusChip.spacing = 5
        statusChip.isLayoutMarginsRelativeArrangement = true
        statusChip.layoutMargins = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
        statusDot.layer.cornerRadius = 3
        statusDot.snp.makeConstraints { $0.size.equalTo(6) }
        statusLabel.font = SettingsStyle.font(12, bold: true)
        statusChip.addArrangedSubview(statusDot)
        statusChip.addArrangedSubview(statusLabel)
        statusChip.snp.makeConstraints { $0.height.equalTo(SettingsStyle.Metric.chipHeight) }
        statusChip.setContentHuggingPriority(.required, for: .horizontal)
        statusChip.setContentCompressionResistancePriority(.required, for: .horizontal)
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        header.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        left.snp
            .makeConstraints {
                $0.leading.equalToSuperview().offset(16); $0.top.equalToSuperview().offset(14); $0.bottom.equalToSuperview().inset(8); $0
                    .trailing.lessThanOrEqualTo(statusChip.snp.leading).offset(-8)
            }
        infoButton.snp.makeConstraints { $0.size.equalTo(44); $0.trailing.equalToSuperview().inset(4); $0.centerY.equalTo(left) }
        statusChip.snp.makeConstraints { $0.trailing.equalTo(infoButton.snp.leading).offset(2); $0.centerY.equalTo(left) }
        separator.backgroundColor = SettingsStyle.Color.separator
        separator.snp.makeConstraints { $0.top.equalTo(header.snp.bottom); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        rowsStack.spacing = 0
        rowsStack.snp.makeConstraints { $0.top.equalTo(separator.snp.bottom); $0.leading.trailing.bottom.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ model: CafeteriaCardModel) {
        translationTask?.cancel()
        let id = UUID()
        configurationID = id
        self.model = model
        accessibilityIdentifier = "cafeteria.card.\(model.seq)"
        infoButton.accessibilityIdentifier = "cafeteria.card.\(model.seq).info"
        infoButton.accessibilityLabel = String(format: String(localized: "cafeteria.info.a11y.format"), model.name)
        nameLabel.text = model.name
        timeLabel.text = model.timeText ?? String(localized: "cafeteria.running.time.unknown")
        configureStatus(model.status)
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translatedRows = model.rows.map { [$0.tag, $0.main, $0.sides] }
        for (index, row) in model.rows.enumerated() {
            rowsStack.addArrangedSubview(makeRow(
                row,
                translated: nil,
                index: index,
                total: model.rows.count
            ))
        }
        guard KoreanTextTranslator.shared.shouldTranslateKorean else { return }
        translationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for (index, row) in model.rows.enumerated() {
                let tag: String? = if let value = row.tag {
                    await KoreanTextTranslator.shared.translate(value)
                } else {
                    nil
                }
                let main = await KoreanTextTranslator.shared.translate(row.main)
                let sides: String? = if let value = row.sides {
                    await KoreanTextTranslator.shared.translate(value)
                } else {
                    nil
                }
                guard !Task.isCancelled, configurationID == id else { return }
                translatedRows[index] = [tag, main, sides]
                rowsStack.arrangedSubviews[index].removeFromSuperview()
                rowsStack.insertArrangedSubview(
                    makeRow(row, translated: translatedRows[index], index: index, total: model.rows.count),
                    at: index
                )
            }
        }
    }

    private func configureStatus(_ status: CafeteriaCardStatus?) {
        statusChip.isHidden = status == nil
        guard let status else { return }
        statusLabel.text = status.title
        switch status {
        case .beforeOpen, .closed:
            statusChip.backgroundColor = SettingsStyle.Color.segmentBackground
            statusLabel.textColor = SettingsStyle.Color.secondaryText
            statusDot.backgroundColor = SettingsStyle.Color.commuterFaint
        case .closingSoon:
            statusChip.backgroundColor = SettingsStyle.Color.levelMidFill
            statusLabel.textColor = SettingsStyle.Color.levelMidText
            statusDot.backgroundColor = SettingsStyle.Color.levelMidText
        case .open:
            statusChip.backgroundColor = SettingsStyle.Color.accentFill
            statusLabel.textColor = SettingsStyle.Color.link
            statusDot.backgroundColor = SettingsStyle.Color.accent
        }
        statusChip.layer.cornerRadius = SettingsStyle.Metric.chipRadius
    }

    private func makeRow(_ row: CafeteriaMenuRowModel, translated: [String?]?, index: Int, total: Int) -> UIView {
        let tag = translated?[0] ?? row.tag
        let main = translated?[1] ?? row.main
        let sides = translated?[2] ?? row.sides
        let container = UIView()
        let column = UIStackView()
        column.axis = .vertical
        column.alignment = .leading
        column.spacing = 4
        if let tag {
            column.addArrangedSubview(makeTagChip(tag))
        }
        column.addArrangedSubview(makeMainLabel(main))
        if let sides {
            column.addArrangedSubview(makeSideLabel(sides))
        }
        container.addSubview(column)
        let price = makePriceLabel(row.price)
        container.addSubview(price)
        column.snp.makeConstraints { $0.leading.equalToSuperview(); $0.top.equalToSuperview(); $0.bottom.equalToSuperview() }
        price.snp.makeConstraints { make in
            make.trailing.equalToSuperview(); make.centerY.equalToSuperview(); make.width
                .greaterThanOrEqualTo(64); make.leading.greaterThanOrEqualTo(column.snp.trailing).offset(12)
        }
        let accessibility = [tag, main, sides, row.price].compactMap { $0 }.joined(separator: ", ")
        container.isAccessibilityElement = true
        container.accessibilityLabel = accessibility
        container.accessibilityIdentifier = "cafeteria.row.\(index)"
        let wrapper = UIView()
        wrapper.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(index == 0 ? 8 : 10)
            make.bottom.equalToSuperview().inset(index == total - 1 ? 12 : 10)
        }
        if index > 0 {
            let line = UIView()
            line.backgroundColor = SettingsStyle.Color.separator
            wrapper.addSubview(line)
            line.snp.makeConstraints { $0.top.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(1) }
        }
        return wrapper
    }

    private func makeTagChip(_ tag: String) -> UILabel {
        let chip = HYUPaddedLabel()
        chip.text = tag
        chip.font = SettingsStyle.font(12, bold: true)
        chip.textColor = SettingsStyle.Color.levelMidText
        chip.backgroundColor = SettingsStyle.Color.levelMidFill
        chip.layer.cornerRadius = SettingsStyle.Metric.chipRadius
        chip.clipsToBounds = true
        chip.padding = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        chip.snp.makeConstraints { $0.height.equalTo(SettingsStyle.Metric.chipHeight) }
        chip.setContentHuggingPriority(.required, for: .horizontal)
        chip.setContentCompressionResistancePriority(.required, for: .horizontal)
        return chip
    }

    private func makeMainLabel(_ main: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = SettingsStyle.font(15, bold: true)
        label.textColor = SettingsStyle.Color.text
        label.attributedText = SettingsStyle.attributedText(
            main,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20
        )
        label.lineBreakStrategy = .hangulWordPriority
        return label
    }

    private func makeSideLabel(_ sides: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.lineBreakStrategy = .hangulWordPriority
        label.attributedText = SettingsStyle.attributedText(
            sides,
            font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        return label
    }

    private func makePriceLabel(_ text: String?) -> UILabel {
        let label = UILabel()
        label.font = SettingsStyle.monospacedDigitFont(15, bold: true)
        label.textColor = SettingsStyle.Color.link
        label.textAlignment = .right
        label.text = text
        return label
    }

    @objc
    private func infoTapped() {
        guard let model else { return }
        AnalyticsManager.logSelect(.cafeteriaInfoButton)
        onInfoTap?(model.seq)
    }
}
