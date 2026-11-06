//
//  ReadingRoomSkeletonCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

class ReadingRoomSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "ReadingRoomSkeletonCellView"
    static let rowCount = 4
    private let cardView = UIView()
    private let separator = UIView()
    private let infoContainer = UIView()
    private let leftStack = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 8
    }
    private let barA = UIView()
    private let barB = UIView()
    private let block = UIView()
    private let circle = UIView()
    private let bar = UIView()
    private var barAWidthConstraint: Constraint?
    private var barBWidthConstraint: Constraint?
    private let placeholders: [UIView]
    private let fractions: [CGFloat] = [0.62, 0.48, 0.70, 0.55]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        placeholders = [barA, barB, block, circle, bar]
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        configure(index: 0, isFirst: true, isLast: true)
        restartPulse()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupUI() {
        selectionStyle = .none
        isAccessibilityElement = false
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupCardChrome()
        setupPlaceholders()
        setupInfoLayout()
        setupUsageBar()
    }

    private func setupCardChrome() {
        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }
        separator.backgroundColor = SettingsStyle.Color.separator
        cardView.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(1 / traitCollection.displayScale)
        }
    }

    private func setupPlaceholders() {
        for view in placeholders {
            view.backgroundColor = SettingsStyle.Color.segmentBackground
            cardView.addSubview(view)
        }
        for (view, radius) in [(barA, CGFloat(7)), (barB, 6), (block, 8), (circle, 18), (bar, 3)] {
            view.layer.cornerRadius = radius
            view.clipsToBounds = true
        }
        leftStack.addArrangedSubview(barA)
        leftStack.addArrangedSubview(barB)
    }

    private func setupInfoLayout() {
        cardView.addSubview(infoContainer)
        infoContainer.addSubview(leftStack)
        infoContainer.addSubview(block)
        infoContainer.addSubview(circle)
        infoContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0).priority(250)
        }
        leftStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
            barA.snp.makeConstraints { make in
                make.height.equalTo(14)
                barAWidthConstraint = make.width.equalTo(leftStack.snp.width).multipliedBy(0.62).constraint
            }
            barB.snp.makeConstraints { make in
                make.height.equalTo(12)
                barBWidthConstraint = make.width.equalTo(leftStack.snp.width).multipliedBy(0.45).constraint
            }
        }
        block.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 48, height: 28))
            make.leading.equalTo(leftStack.snp.trailing).offset(12)
            make.bottom.equalTo(leftStack.snp.bottom)
        }
        circle.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.leading.equalTo(block.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(infoContainer.snp.centerY)
        }
    }

    private func setupUsageBar() {
        cardView.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.top.equalTo(infoContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(6)
            make.bottom.equalToSuperview().inset(14)
        }
    }

    func configure(index: Int, isFirst: Bool, isLast: Bool) {
        let mask = corners(isFirst: isFirst, isLast: isLast)
        cardView.layer.maskedCorners = mask
        cardView.layer.cornerRadius = (isFirst || isLast) ? SettingsStyle.Metric.cardRadius : 0
        separator.isHidden = isFirst
        barAWidthConstraint?.deactivate()
        barA.snp.remakeConstraints { make in
            make.height.equalTo(14)
            make.width.equalTo(leftStack.snp.width).multipliedBy(fractions[index % fractions.count])
        }
        barBWidthConstraint?.deactivate()
        barB.snp.remakeConstraints { make in
            make.height.equalTo(12)
            make.width.equalTo(leftStack.snp.width).multipliedBy(0.45)
        }
        barAWidthConstraint = nil
        barBWidthConstraint = nil
        restartPulse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        restartPulse()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { restartPulse() } else { stopPulse() }
    }

    private func restartPulse() {
        stopPulse()
        guard window != nil else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.45
        animation.toValue = 1.0
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        placeholders.forEach { $0.layer.add(animation, forKey: "readingRoomSkeletonOpacity") }
    }

    private func stopPulse() {
        placeholders.forEach { $0.layer.removeAnimation(forKey: "readingRoomSkeletonOpacity") }
    }

    private func corners(isFirst: Bool, isLast: Bool) -> CACornerMask {
        var mask: CACornerMask = []
        if isFirst { mask.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast { mask.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        return mask
    }
}
