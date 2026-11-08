//
//  CafeteriaStateViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaSkeletonListView: UIView {
    private struct SkeletonCard {
        let view: UIView
        let bars: [UIView]
    }

    private let stack = UIStackView()
    private var cards: [SkeletonCard] = []
    private var isAnimating = false

    init() {
        super.init(frame: .zero)
        accessibilityIdentifier = "cafeteria.skeleton"
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "cafeteria.loading.a11y")
        accessibilityTraits = .updatesFrequently
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (index, rowCount) in [3, 2, 2].enumerated() {
            let card = makeCard(index: index, rowCount: rowCount)
            cards.append(card)
            stack.addArrangedSubview(card.view)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAnimating(_ animating: Bool) {
        isAnimating = animating
        for (index, card) in cards.enumerated() {
            for bar in card.bars {
                bar.layer.removeAnimation(forKey: "cafeteria.skeleton.pulse")
                guard animating, !UIAccessibility.isReduceMotionEnabled else { continue }
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 1
                pulse.toValue = 0.45
                pulse.duration = 0.8
                pulse.autoreverses = true
                pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pulse.repeatCount = .infinity
                pulse.beginTime = CACurrentMediaTime() + 0.1 * Double(index)
                bar.layer.add(pulse, forKey: "cafeteria.skeleton.pulse")
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, isAnimating {
            setAnimating(true)
        }
    }

    private func makeCard(index: Int, rowCount: Int) -> SkeletonCard {
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = SettingsStyle.Metric.cardRadius
        card.clipsToBounds = true
        let bars = NSMutableArray()
        let header = UIStackView()
        header.axis = .vertical
        header.alignment = .leading
        header.spacing = 6
        header.addArrangedSubview(bar(width: 112, height: 16, into: bars))
        header.addArrangedSubview(bar(width: 140, height: 12, into: bars))
        card.addSubview(header)
        header.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        card.addSubview(separator)
        separator.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        let rows = UIStackView()
        rows.axis = .vertical
        rows.alignment = .fill
        rows.spacing = 0
        card.addSubview(rows)
        rows.snp.makeConstraints {
            $0.top.equalTo(separator.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        for rowIndex in 0 ..< rowCount {
            rows.addArrangedSubview(makeRow(index: rowIndex, rowCount: rowCount, bars: bars))
        }
        return SkeletonCard(view: card, bars: bars.compactMap { $0 as? UIView })
    }

    private func makeRow(index: Int, rowCount: Int, bars: NSMutableArray) -> UIView {
        let leftWidths: [CGFloat] = [0.58, 0.46, 0.64]
        let secondaryWidths: [CGFloat] = [0.82, 0.70, 0.76]
        let wrapper = UIView()
        if index > 0 {
            let line = UIView()
            line.backgroundColor = SettingsStyle.Color.separator
            wrapper.addSubview(line)
            line.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                $0.height.equalTo(1)
            }
        }
        let row = UIView()
        wrapper.addSubview(row)
        row.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(index == 0 ? 8 : 10)
            $0.bottom.equalToSuperview().inset(index == rowCount - 1 ? 12 : 10)
        }
        let left = UIStackView()
        left.axis = .vertical
        left.alignment = .leading
        left.spacing = 6
        row.addSubview(left)
        left.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview().offset(-64)
        }
        let primary = bar(width: 1, height: 14, into: bars)
        left.addArrangedSubview(primary)
        primary.snp.makeConstraints { $0.width.equalTo(left.snp.width).multipliedBy(leftWidths[index]) }
        let secondary = bar(width: 1, height: 12, into: bars)
        left.addArrangedSubview(secondary)
        secondary.snp.makeConstraints { $0.width.equalTo(left.snp.width).multipliedBy(secondaryWidths[index]) }
        let price = bar(width: 52, height: 14, into: bars)
        row.addSubview(price)
        price.snp.makeConstraints {
            $0.trailing.top.equalToSuperview()
            $0.width.equalTo(52)
            $0.leading.equalTo(left.snp.trailing).offset(12)
        }
        return wrapper
    }

    private func bar(width: CGFloat, height: CGFloat, into bars: NSMutableArray) -> UIView {
        let bar = UIView()
        bar.backgroundColor = SettingsStyle.Color.segmentBackground
        bar.layer.cornerRadius = height / 2
        bar.snp.makeConstraints { make in
            make.height.equalTo(height)
            if width > 1 {
                make.width.equalTo(width)
            }
        }
        bars.add(bar)
        return bar
    }
}

final class CafeteriaEmptyCardView: UIView {
    var onAction: (() -> Void)?
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    init() {
        super.init(frame: .zero)
        accessibilityIdentifier = "cafeteria.empty"
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .center
        content.spacing = 0
        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 32, left: 24, bottom: 32, right: 24)) }
        let iconCircle = UIView()
        iconCircle.backgroundColor = SettingsStyle.Color.segmentBackground
        iconCircle.layer.cornerRadius = 28
        let icon = UIImageView(image: UIImage(
            systemName: "fork.knife",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .light)
        ))
        icon.tintColor = SettingsStyle.Color.commuterFaint
        iconCircle.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        iconCircle.snp.makeConstraints { $0.size.equalTo(56) }
        content.addArrangedSubview(iconCircle)
        titleLabel.font = SettingsStyle.font(17, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = SettingsStyle.attributedText(
            "",
            font: SettingsStyle.font(17, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22,
            alignment: .center
        )
        content.addArrangedSubview(titleLabel)
        content.setCustomSpacing(16, after: iconCircle)
        messageLabel.font = SettingsStyle.font(13)
        messageLabel.textColor = SettingsStyle.Color.secondaryText
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakStrategy = .hangulWordPriority
        content.addArrangedSubview(messageLabel)
        content.setCustomSpacing(6, after: titleLabel)
        actionButton.accessibilityIdentifier = "cafeteria.empty.action"
        actionButton.titleLabel?.font = SettingsStyle.font(15, bold: true)
        actionButton.setTitleColor(SettingsStyle.Color.link, for: .normal)
        actionButton.backgroundColor = SettingsStyle.Color.accentFill
        actionButton.layer.cornerRadius = 12
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        content.addArrangedSubview(actionButton)
        content.setCustomSpacing(20, after: messageLabel)
        actionButton.snp.makeConstraints { $0.height.equalTo(44) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, message: String, actionTitle: String) {
        titleLabel.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(17, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22,
            alignment: .center
        )
        messageLabel.attributedText = SettingsStyle.attributedText(
            message,
            font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18,
            alignment: .center
        )
        actionButton.setTitle(actionTitle, for: .normal)
    }

    @objc
    private func actionTapped() {
        onAction?()
    }
}

final class CafeteriaBottomFadeView: UIView {
    private let gradient = CAGradientLayer()

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.locations = [0, 0.85]
        layer.addSublayer(gradient)
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    private func updateColors() {
        let background = SettingsStyle.Color.background.resolvedColor(with: traitCollection)
        gradient.colors = [background.withAlphaComponent(0).cgColor, background.cgColor]
    }
}
