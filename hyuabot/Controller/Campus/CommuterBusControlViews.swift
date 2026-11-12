//
//  CommuterBusControlViews.swift
//  hyuabot
//

import UIKit

final class CommuterDirectionSegmentView: UIView {
    var onSelect: ((CommuterDirection) -> Void)?
    private let stack = UIStackView()
    private var items: [CommuterDirectionItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.segmentBackground
        layer.cornerRadius = 12
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 4
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        accessibilityLabel = String(localized: "commuter.direction.accessibility")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [CommuterDirectionItem]) {
        self.items = items
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for item in items {
            let control = UIControl()
            control.layer.cornerRadius = 9
            let title = item.direction == .toCampus
                ? String(localized: "commuter.direction.to")
                : String(localized: "commuter.direction.from")
            let count = String(localized: "commuter.direction.route_count.\(item.routeCount)")
            let titleLabel = UILabel()
            titleLabel.attributedText = SettingsStyle.attributedText(
                title,
                font: SettingsStyle.font(15, bold: item.isSelected),
                color: item.isSelected ? SettingsStyle.Color.text : SettingsStyle.Color.secondaryText,
                lineHeight: 20
            )
            let countLabel = UILabel()
            countLabel.attributedText = SettingsStyle.attributedText(
                count,
                font: SettingsStyle.monospacedDigitFont(12),
                color: SettingsStyle.Color.commuterFaint,
                lineHeight: 16
            )
            let content = UIStackView(arrangedSubviews: [titleLabel, countLabel])
            content.axis = .horizontal
            content.alignment = .center
            content.spacing = 6
            content.isUserInteractionEnabled = false
            control.addSubview(content)
            content.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                control.heightAnchor.constraint(equalToConstant: 36),
                content.centerXAnchor.constraint(equalTo: control.centerXAnchor),
                content.centerYAnchor.constraint(equalTo: control.centerYAnchor)
            ])
            control.isAccessibilityElement = true
            control.accessibilityLabel = "\(title), \(count)"
            control.accessibilityIdentifier = item.direction == .toCampus
                ? "commuter.direction.toCampus"
                : "commuter.direction.fromCampus"
            control.accessibilityTraits = item.isSelected ? [.button, .selected] : [.button]
            control.tag = CommuterDirection.allCases.firstIndex(of: item.direction) ?? 0

            if item.isSelected {
                control.backgroundColor = SettingsStyle.Color.segmentSelected
                control.layer.shadowOffset = CGSize(width: 0, height: 1)
                control.layer.shadowRadius = 1.5
                control.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0 : 0.12
                control.layer.shadowColor = SettingsStyle.Color.segmentShadow.cgColor
                control.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIControl, _) in
                    view.layer.shadowColor = SettingsStyle.Color.segmentShadow.cgColor
                    view.layer.shadowOpacity = view.traitCollection.userInterfaceStyle == .dark ? 0 : 0.12
                }
            }
            control.addTarget(self, action: #selector(selected(_:)), for: .touchUpInside)
            stack.addArrangedSubview(control)
        }
    }

    @objc
    private func selected(_ sender: UIControl) {
        guard items.indices.contains(sender.tag) else { return }
        onSelect?(items[sender.tag].direction)
    }
}

final class CommuterRouteSectionHeaderView: UIView {
    var onResetToNearest: (() -> Void)?
    private let resetButton = UIButton(configuration: .plain())
    private var headerHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        let title = UILabel()
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "commuter.route.section"),
            font: SettingsStyle.font(13, bold: true),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        addSubview(title)
        addSubview(resetButton)
        title.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.image = UIImage(
            systemName: "location",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        config.attributedTitle = AttributedString(
            String(localized: "commuter.route.reset_nearest"),
            attributes: .init([.font: SettingsStyle.font(13, bold: true)])
        )
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        resetButton.configuration = config
        resetButton.tintColor = SettingsStyle.Color.link
        resetButton.accessibilityIdentifier = "commuter.reset_nearest"
        resetButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        resetButton.isHidden = true
        let headerHeightConstraint = heightAnchor.constraint(equalToConstant: 18)
        self.headerHeightConstraint = headerHeightConstraint
        NSLayoutConstraint.activate([
            headerHeightConstraint,
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            resetButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(showsReset: Bool) {
        resetButton.isHidden = !showsReset
        headerHeightConstraint?.constant = showsReset ? 44 : 18
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
            || (!resetButton.isHidden && resetButton.frame.insetBy(dx: -8, dy: -13).contains(point))
    }

    @objc
    private func reset() {
        onResetToNearest?()
    }
}

final class CommuterRouteGridView: UIView {
    var onSelect: ((String) -> Void)?
    private let rows = UIStackView()
    private var items: [CommuterRouteItem] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        rows.axis = .vertical
        rows.spacing = 10
        addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: trailingAnchor),
            rows.topAnchor.constraint(equalTo: topAnchor),
            rows.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [CommuterRouteItem]) {
        self.items = items
        rows.arrangedSubviews.forEach {
            rows.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let columns = items.count > 1 ? 2 : 1
        for start in stride(from: 0, to: items.count, by: columns) {
            let row = UIStackView()
            row.alignment = .fill
            row.distribution = .fillEqually
            row.spacing = 10
            for offset in 0..<columns {
                let index = start + offset
                row.addArrangedSubview(
                    index < items.count ? makeCard(items[index], index: index) : UIView()
                )
            }
            rows.addArrangedSubview(row)
        }
    }

    private func makeCard(_ item: CommuterRouteItem, index: Int) -> UIControl {
        let card = UIControl()
        card.tag = index
        card.layer.cornerRadius = HYUMetrics.Radius.card
        card.layer.borderWidth = 2
        card.backgroundColor = SettingsStyle.Color.card
        func refresh(_ view: UIControl) {
            view.layer.borderColor = (item.isSelected ? SettingsStyle.Color.accent : UIColor.clear).cgColor
        }
        refresh(card)
        card.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: UIControl, _) in
            refresh(view)
        }

        let (badgeContainer, badge) = makeBadge(for: item)
        let label = UILabel()
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        label.accessibilityLabel = item.summary
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.attributedText = SettingsStyle.attributedText(
            item.summary,
            font: SettingsStyle.font(12, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20,
            alignment: .left,
            lineBreakMode: .byTruncatingTail
        )
        let content = UIStackView(arrangedSubviews: [badgeContainer, label])
        content.spacing = 10
        content.alignment = .center
        content.isUserInteractionEnabled = false
        card.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            badgeContainer.widthAnchor.constraint(
                equalToConstant: max(42, badge.intrinsicContentSize.width + 14)
            ),
            badgeContainer.heightAnchor.constraint(equalToConstant: 24),
            badge.heightAnchor.constraint(equalToConstant: 24),
            badge.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 7),
            badge.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -7),
            badge.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor)
        ])
        card.isAccessibilityElement = true
        card.accessibilityLabel = "\(item.name), \(item.summary)"
        card.accessibilityIdentifier = "commuter.route.\(item.name)"
        card.accessibilityTraits = item.isSelected ? [.button, .selected] : [.button]
        card.addTarget(self, action: #selector(selectCard(_:)), for: .touchUpInside)
        return card
    }

    private func makeBadge(for item: CommuterRouteItem) -> (UIView, UILabel) {
        let badge = UILabel()
        badge.text = item.name
        badge.textAlignment = .center
        badge.font = SettingsStyle.font(14, bold: true)
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.backgroundColor = item.isSelected
            ? SettingsStyle.Color.accent
            : SettingsStyle.Color.accentFill
        badge.textColor = item.isSelected ? SettingsStyle.Color.onAccent : SettingsStyle.Color.link
        let container = UIView()
        container.setContentHuggingPriority(.required, for: .horizontal)
        container.setContentCompressionResistancePriority(.required, for: .horizontal)
        container.addSubview(badge)
        badge.translatesAutoresizingMaskIntoConstraints = false
        return (container, badge)
    }

    @objc
    private func selectCard(_ sender: UIControl) {
        guard items.indices.contains(sender.tag) else { return }
        onSelect?(items[sender.tag].name)
    }
}

final class CommuterSkeletonCardView: UIView {
    private var shapes: [UIView] = []

    override init(frame: CGRect) {
        var animated: [UIView] = []
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = HYUMetrics.Radius.card
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        let widths: [CGFloat] = [0.62, 0.48, 0.70, 0.55, 0.66, 0.44]
        for index in 0..<6 {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            let block = UIView()
            block.backgroundColor = SettingsStyle.Color.segmentBackground
            block.layer.cornerRadius = 7
            let slot = UIView()
            let dot = UIView()
            dot.backgroundColor = SettingsStyle.Color.segmentBackground
            dot.layer.cornerRadius = 5
            slot.addSubview(dot)
            let bar = UIView()
            bar.backgroundColor = SettingsStyle.Color.segmentBackground
            bar.layer.cornerRadius = 7
            [block, slot, bar].forEach { row.addArrangedSubview($0) }
            [block, slot, dot, bar].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: 14),
                block.widthAnchor.constraint(equalToConstant: 44),
                block.heightAnchor.constraint(equalToConstant: 14),
                slot.widthAnchor.constraint(equalToConstant: 12),
                dot.widthAnchor.constraint(equalToConstant: 10),
                dot.heightAnchor.constraint(equalToConstant: 10),
                dot.centerXAnchor.constraint(equalTo: slot.centerXAnchor),
                dot.centerYAnchor.constraint(equalTo: slot.centerYAnchor),
                bar.heightAnchor.constraint(equalToConstant: 14),
                bar.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: widths[index])
            ])
            stack.addArrangedSubview(row)
            animated += [block, dot, bar]
        }
        shapes = animated
        isAccessibilityElement = true
        accessibilityLabel = String(localized: "commuter.loading.accessibility")
        accessibilityIdentifier = "commuter.skeleton"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startPulse() {
        for (index, shape) in shapes.enumerated() {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1
            animation.toValue = 0.45
            animation.duration = 0.8
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.beginTime = CACurrentMediaTime() + Double(index / 3) * 0.08
            shape.layer.add(animation, forKey: "commuterSkeletonPulse")
        }
    }

    func stopPulse() {
        shapes.forEach { $0.layer.removeAnimation(forKey: "commuterSkeletonPulse") }
    }
}
