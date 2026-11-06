//
//  CalendarPanelViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CalendarPanelHeaderView: UIView {
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    let clearButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        snp.makeConstraints { $0.height.equalTo(32) }
        titleLabel.font = SettingsStyle.font(17, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.lineBreakMode = .byTruncatingTail
        countLabel.font = SettingsStyle.monospacedDigitFont(13)
        countLabel.textColor = SettingsStyle.Color.secondaryText
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        clearButton.setTitle(String(localized: "calendar.clear_selection"), for: .normal)
        clearButton.titleLabel?.font = SettingsStyle.font(14, bold: true)
        clearButton.tintColor = SettingsStyle.Color.link
        clearButton.setTitleColor(SettingsStyle.Color.link, for: .normal)
        clearButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        clearButton.accessibilityIdentifier = "calendar.clear_selection"
        addSubview(titleLabel)
        addSubview(countLabel)
        addSubview(clearButton)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
        }
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.firstBaseline.equalTo(titleLabel.snp.firstBaseline)
        }
        clearButton.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(countLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
        }
    }

    func configure(title: String, count: Int?, showsClear: Bool) {
        titleLabel.text = title
        if let count, count > 0 {
            countLabel.text = String(format: String(localized: "calendar.count"), count)
            countLabel.isHidden = false
        } else {
            countLabel.text = nil
            countLabel.isHidden = true
        }
        clearButton.isHidden = !showsClear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CalendarEmptyStateView: UIView {
    private let titleLabel = UILabel()
    private let captionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        let iconCircle = UIView()
        iconCircle.backgroundColor = SettingsStyle.Color.segmentBackground
        iconCircle.layer.cornerRadius = 20
        let icon = UIImageView(image: UIImage(
            systemName: "calendar",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18)
        ))
        icon.tintColor = SettingsStyle.Color.secondaryText
        iconCircle.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        iconCircle.snp.makeConstraints { $0.size.equalTo(40) }
        titleLabel.font = SettingsStyle.font(15, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        captionLabel.font = SettingsStyle.font(13)
        captionLabel.textColor = SettingsStyle.Color.secondaryText
        captionLabel.textAlignment = .center
        captionLabel.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [iconCircle, titleLabel, captionLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(title: String, caption: String) {
        titleLabel.text = title
        captionLabel.text = caption
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CalendarSkeletonListView: UIView {
    private let animatedViews: [UIView]
    private let animationKey = "calendarSkeletonOpacity"

    override init(frame: CGRect) {
        var rows: [UIView] = []
        var animated: [UIView] = []
        for index in 0..<3 {
            let row = UIView()
            let stripe = UIView()
            stripe.backgroundColor = SettingsStyle.Color.segmentBackground
            stripe.layer.cornerRadius = 2
            row.addSubview(stripe)
            let barA = UIView()
            let barB = UIView()
            for (bar, radius, height) in [(barA, CGFloat(7), CGFloat(14)), (barB, 6, 12)] {
                bar.backgroundColor = SettingsStyle.Color.segmentBackground
                bar.layer.cornerRadius = radius
                bar.snp.makeConstraints { $0.height.equalTo(height) }
                animated.append(bar)
            }
            let content = UIStackView(arrangedSubviews: [barA, barB])
            content.axis = .vertical
            content.alignment = .leading
            content.spacing = 8
            row.addSubview(content)
            stripe.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.top.bottom.equalToSuperview().inset(10)
                make.width.equalTo(4)
            }
            content.snp.makeConstraints { make in
                make.leading.equalTo(stripe.snp.trailing).offset(12)
                make.trailing.equalToSuperview().inset(16)
                make.top.bottom.equalToSuperview().inset(13)
            }
            barA.snp.makeConstraints { make in
                make.width.equalTo(content.snp.width).multipliedBy([0.64, 0.52, 0.70][index])
            }
            barB.snp.makeConstraints { $0.width.equalTo(content.snp.width).multipliedBy(0.40) }
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = SettingsStyle.Color.separator
                row.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.top.trailing.equalToSuperview()
                    make.leading.equalToSuperview().offset(32)
                    make.height.equalTo(1)
                }
            }
            rows.append(row)
            animated.append(stripe)
        }
        animatedViews = animated
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    func startPulse() {
        for view in animatedViews {
            view.layer.removeAnimation(forKey: animationKey)
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1
            animation.toValue = 0.45
            animation.duration = 0.8
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            view.layer.add(animation, forKey: animationKey)
        }
    }

    func stopPulse() {
        animatedViews.forEach { $0.layer.removeAnimation(forKey: animationKey) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CalendarHintLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        numberOfLines = 1
        lineBreakMode = .byTruncatingTail
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 17
        paragraphStyle.maximumLineHeight = 17
        paragraphStyle.lineBreakMode = .byTruncatingTail
        attributedText = NSAttributedString(
            string: String(localized: "calendar.swipe.hint"),
            attributes: [
                .font: SettingsStyle.font(12.5),
                .foregroundColor: SettingsStyle.Color.secondaryText,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
