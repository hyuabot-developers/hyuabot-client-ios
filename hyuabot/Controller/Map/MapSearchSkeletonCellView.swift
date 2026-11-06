//
//  MapSearchSkeletonCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class MapSearchSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "MapSearchSkeletonCellView"

    private let cardView = UIView()
    private let separator = UIView()
    private let circle = UIView()
    private let textStack = UIStackView()
    private let barA = UIView()
    private let barB = UIView()
    private var fraction: CGFloat = 0.56

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(64)
        }
        separator.backgroundColor = SettingsStyle.Color.separator
        cardView.addSubview(separator)
        separator.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().inset(68)
            $0.trailing.equalToSuperview()
            $0.height.equalTo(1 / traitCollection.displayScale)
        }
        circle.backgroundColor = SettingsStyle.Color.segmentBackground
        circle.layer.cornerRadius = 20
        circle.layer.cornerCurve = .continuous
        cardView.addSubview(circle)
        circle.snp.makeConstraints { $0.size.equalTo(40); $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 8
        barA.backgroundColor = SettingsStyle.Color.segmentBackground
        barA.layer.cornerRadius = 7
        barA.layer.cornerCurve = .continuous
        barB.backgroundColor = SettingsStyle.Color.segmentBackground
        barB.layer.cornerRadius = 6
        barB.layer.cornerCurve = .continuous
        textStack.addArrangedSubview(barA)
        textStack.addArrangedSubview(barB)
        cardView.addSubview(textStack)
        textStack.snp.makeConstraints {
            $0.leading.equalTo(circle.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalTo(circle.snp.centerY)
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        barA.snp.makeConstraints { $0.height.equalTo(14); $0.width.equalTo(textStack.snp.width).multipliedBy(fraction) }
        barB.snp.makeConstraints { $0.height.equalTo(12); $0.width.equalTo(textStack.snp.width).multipliedBy(0.34) }
    }

    func configure(index: Int, isFirst: Bool, isLast: Bool) {
        fraction = [0.56, 0.42, 0.64, 0.48][index % 4]
        barA.snp.remakeConstraints { $0.height.equalTo(14); $0.width.equalTo(textStack.snp.width).multipliedBy(fraction) }
        separator.isHidden = isFirst
        cardView.layer.cornerRadius = isFirst || isLast ? 16 : 0
        if isFirst && isLast {
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else if isFirst {
            cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if isLast {
            cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cardView.layer.maskedCorners = []
        }
        isAccessibilityElement = false
    }
}
