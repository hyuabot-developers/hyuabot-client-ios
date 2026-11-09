//
//  SearchResultCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

class SearchResultCellView: UITableViewCell {
    static let reuseIdentifier = "SearchResultCellView"

    private let cardView = UIView()
    private let separator = UIView()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let numberLabel = UILabel()
    private let nameLabel = UILabel()
    private let buildingLabel = UILabel()
    private let trailingIconView = UIImageView()
    private let firstLine = UIStackView()
    private let textStack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupCard()
        setupSeparator()
        setupIcon()
        setupText()
        setupChevron()
    }

    private func setupCard() {
        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(64)
        }
    }

    private func setupSeparator() {
        separator.backgroundColor = SettingsStyle.Color.separator
        cardView.addSubview(separator)
        separator.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(68)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(1 / traitCollection.displayScale)
        }
    }

    private func setupIcon() {
        iconContainer.backgroundColor = SettingsStyle.Color.accentFill
        iconContainer.layer.cornerRadius = 20
        iconContainer.layer.cornerCurve = .continuous
        cardView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        let iconConfiguration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconView.image = UIImage(systemName: "door.left.hand.open", withConfiguration: iconConfiguration)
        iconView.tintColor = SettingsStyle.Color.link
        iconView.snp.makeConstraints { $0.center.equalToSuperview() }
        iconContainer.snp.makeConstraints {
            $0.size.equalTo(40)
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
    }

    private func setupText() {
        [numberLabel, nameLabel, buildingLabel].forEach { $0.adjustsFontForContentSizeCategory = true }
        numberLabel.font = SettingsStyle.monospacedDigitFont(16, bold: true)
        numberLabel.textColor = SettingsStyle.Color.text
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        numberLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.font = SettingsStyle.font(15)
        nameLabel.textColor = SettingsStyle.Color.text
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        buildingLabel.font = SettingsStyle.font(13)
        buildingLabel.textColor = SettingsStyle.Color.secondaryText
        buildingLabel.numberOfLines = 1
        buildingLabel.lineBreakMode = .byTruncatingTail
        firstLine.axis = .horizontal
        firstLine.alignment = .firstBaseline
        firstLine.spacing = 6
        firstLine.addArrangedSubview(numberLabel)
        firstLine.addArrangedSubview(nameLabel)
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.addArrangedSubview(firstLine)
        textStack.addArrangedSubview(buildingLabel)
        cardView.addSubview(textStack)
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
            $0.height.greaterThanOrEqualTo(40)
        }
    }

    private func setupChevron() {
        let trailingIconConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        trailingIconView.image = UIImage(systemName: "location.circle.fill", withConfiguration: trailingIconConfiguration)
        trailingIconView.tintColor = SettingsStyle.Color.link
        trailingIconView.isAccessibilityElement = false
        cardView.addSubview(trailingIconView)
        trailingIconView.snp.makeConstraints {
            $0.size.equalTo(24)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
            $0.leading.equalTo(textStack.snp.trailing).offset(12)
        }
        textStack.snp.makeConstraints { $0.trailing.lessThanOrEqualTo(trailingIconView.snp.leading).offset(-12) }
    }

    func configure(item: RoomItem, isFirst: Bool, isLast: Bool) {
        let numberText = MapSearchLogic.roomNumberText(item.number)
        numberLabel.text = numberText
        nameLabel.setKoreanTranslatedText(item.name)
        buildingLabel.setKoreanTranslatedText(item.building)
        separator.isHidden = isFirst
        cardView.layer.cornerRadius = isFirst || isLast ? 16 : 0
        if isFirst, isLast {
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cardView.layer.maskedCorners = []
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "\(item.building) \(numberText) \(item.name), \(String(localized: "map.room.show_on_map"))"
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        cardView.backgroundColor = highlighted ? SettingsStyle.Color.segmentBackground : SettingsStyle.Color.card
    }
}
