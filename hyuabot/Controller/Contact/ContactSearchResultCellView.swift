//
//  ContactSearchResultCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class ContactSearchResultCellView: UITableViewCell {
    static let reuseIdentifier = "ContactSearchResultCellView"

    private let cardView = UIView()
    private let callArea = UIView()
    private let callBadge = UIView()
    private let callIcon = UIImageView(image: UIImage(
        systemName: "phone",
        withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
    ))
    private let titleLabel = UILabel()
    private let phoneLabel = UILabel()
    private let labelStack = UIStackView()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildView()
    }

    func configure(entry: ContactEntry, query: String, isFirst: Bool, isLast: Bool) {
        titleLabel.attributedText = highlighted(
            entry.name,
            range: ContactDirectory.highlightRange(of: query, in: entry.name),
            font: SettingsStyle.font(16, bold: true),
            color: SettingsStyle.Color.text
        )
        phoneLabel.attributedText = highlighted(
            entry.phoneNumber,
            range: ContactDirectory.phoneHighlightRange(of: query, in: entry.phoneNumber),
            font: SettingsStyle.monospacedDigitFont(15),
            color: SettingsStyle.Color.secondaryText
        )
        cardView.layer.cornerRadius = SettingsStyle.Metric.cardRadius
        cardView.layer.maskedCorners = corners(isFirst: isFirst, isLast: isLast)
        separator.isHidden = isFirst
        callArea.accessibilityLabel = String(
            format: String(localized: "contact.row.accessibility.%@.%@.%@"),
            entry.department,
            entry.name,
            entry.phoneNumber
        )
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        cardView.backgroundColor = highlighted ? SettingsStyle.Color.segmentBackground : SettingsStyle.Color.card
    }

    private func buildView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        isAccessibilityElement = false
        accessibilityElements = [callArea]

        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
            make.height.greaterThanOrEqualTo(64)
        }

        callArea.isAccessibilityElement = true
        callArea.accessibilityTraits = .button
        callArea.accessibilityIdentifier = "contact.row"

        titleLabel.font = SettingsStyle.font(16, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontForContentSizeCategory = true
        phoneLabel.font = SettingsStyle.monospacedDigitFont(15)
        phoneLabel.textColor = SettingsStyle.Color.secondaryText
        phoneLabel.adjustsFontForContentSizeCategory = true
        labelStack.axis = .vertical
        labelStack.spacing = 3
        labelStack.addArrangedSubview(titleLabel)
        labelStack.addArrangedSubview(phoneLabel)

        callBadge.backgroundColor = SettingsStyle.Color.accentFill
        callBadge.layer.cornerRadius = 20
        callBadge.addSubview(callIcon)
        callIcon.tintColor = SettingsStyle.Color.link
        callIcon.contentMode = .center

        separator.backgroundColor = SettingsStyle.Color.separator

        cardView.addSubview(callArea)
        cardView.addSubview(separator)
        [labelStack, callBadge].forEach(callArea.addSubview)

        setupConstraints()
    }

    private func setupConstraints() {
        callArea.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        labelStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(callBadge.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().inset(10)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }
        callBadge.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(labelStack.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        callIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(1 / traitCollection.displayScale)
        }
    }

    private func highlighted(
        _ text: String,
        range: NSRange?,
        font: UIFont,
        color: UIColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: color]
        )
        if let range {
            result.addAttributes([
                .backgroundColor: SettingsStyle.Color.highlight,
                .foregroundColor: SettingsStyle.Color.highlightText
            ], range: range)
        }
        return result
    }

    private func corners(isFirst: Bool, isLast: Bool) -> CACornerMask {
        var mask: CACornerMask = []
        if isFirst { mask.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast { mask.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        return mask
    }
}
