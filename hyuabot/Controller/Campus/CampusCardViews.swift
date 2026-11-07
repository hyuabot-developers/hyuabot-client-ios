//
//  CampusCardViews.swift
//  hyuabot
//

import UIKit

private struct CampusIconTileSpec {
    let size: CGFloat
    let radius: CGFloat
    let pointSize: CGFloat
}

private func campusIconTile(
    symbol: String,
    spec: CampusIconTileSpec,
    background: UIColor,
    tint: UIColor
) -> UIView {
    let tile = UIView()
    tile.translatesAutoresizingMaskIntoConstraints = false
    tile.backgroundColor = background
    tile.layer.cornerRadius = spec.radius
    tile.layer.cornerCurve = .continuous

    let imageView = UIImageView(
        image: UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: spec.pointSize, weight: .semibold)
        )
    )
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.tintColor = tint
    imageView.contentMode = .center
    tile.addSubview(imageView)
    NSLayoutConstraint.activate([
        tile.widthAnchor.constraint(equalToConstant: spec.size),
        tile.heightAnchor.constraint(equalToConstant: spec.size),
        imageView.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: tile.centerYAnchor)
    ])
    return tile
}

private func campusLabel(_ text: String, size: CGFloat, bold: Bool, color: UIColor, lineHeight: CGFloat) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    label.attributedText = SettingsStyle.attributedText(
        text,
        font: SettingsStyle.font(size, bold: bold),
        color: color,
        lineHeight: lineHeight
    )
    return label
}

private func campusChevron(symbol: String, pointSize: CGFloat, dimension: CGFloat) -> UIImageView {
    let view = UIImageView(
        image: UIImage(
            systemName: symbol,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        )
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    view.tintColor = SettingsStyle.Color.chevron
    view.contentMode = .center
    NSLayoutConstraint.activate([
        view.widthAnchor.constraint(equalToConstant: dimension),
        view.heightAnchor.constraint(equalToConstant: dimension)
    ])
    return view
}

@MainActor
private func constrainCampusTitleRow(_ titleRow: UIView, titleLabel: UILabel, badgeView: UIView) {
    NSLayoutConstraint.activate([
        titleLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
        titleLabel.topAnchor.constraint(equalTo: titleRow.topAnchor),
        titleLabel.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),
        badgeView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 6),
        badgeView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
        badgeView.trailingAnchor.constraint(lessThanOrEqualTo: titleRow.trailingAnchor)
    ])
}

@MainActor
private func prepareControl(_ control: UIControl, radius: CGFloat) {
    control.translatesAutoresizingMaskIntoConstraints = false
    control.layer.cornerRadius = radius
    control.layer.cornerCurve = .continuous
    control.isAccessibilityElement = true
    control.accessibilityTraits = .button
}

final class CampusFeatureCardControl: UIControl {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.85 : 1
            }
        }
    }

    init(title: String, subtitle: String, badge: String, symbol: String) {
        super.init(frame: .zero)
        prepareControl(self, radius: 16)
        backgroundColor = SettingsStyle.Color.card
        accessibilityLabel = title
        accessibilityValue = "\(badge), \(subtitle)"

        let icon = campusIconTile(
            symbol: symbol,
            spec: CampusIconTileSpec(size: 36, radius: 10, pointSize: 18),
            background: SettingsStyle.Color.accent,
            tint: SettingsStyle.Color.onAccent
        )
        let titleLabel = campusLabel(title, size: 15, bold: true, color: SettingsStyle.Color.text, lineHeight: 20)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let badgeLabel = campusLabel(badge, size: 11, bold: true, color: SettingsStyle.Color.link, lineHeight: 18)
        let badgeView = UIView()
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.backgroundColor = SettingsStyle.Color.accentFill
        badgeView.layer.cornerRadius = 9
        badgeView.layer.cornerCurve = .continuous
        badgeView.addSubview(badgeLabel)
        NSLayoutConstraint.activate([
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -6),
            badgeLabel.topAnchor.constraint(equalTo: badgeView.topAnchor),
            badgeLabel.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor),
            badgeView.heightAnchor.constraint(equalToConstant: 18)
        ])
        badgeView.setContentHuggingPriority(.required, for: .horizontal)
        badgeView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleRow = UIView()
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        titleRow.addSubview(titleLabel)
        titleRow.addSubview(badgeView)
        constrainCampusTitleRow(titleRow, titleLabel: titleLabel, badgeView: badgeView)

        let subtitleLabel = campusLabel(subtitle, size: 13, bold: false, color: SettingsStyle.Color.secondaryText, lineHeight: 18)
        let textStack = UIStackView(arrangedSubviews: [titleRow, subtitleLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 2
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chevron = campusChevron(symbol: "chevron.right", pointSize: 14, dimension: 18)
        let row = UIStackView(arrangedSubviews: [icon, textStack, chevron])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
        disableInteraction(in: row)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CampusToolCardControl: UIControl {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.85 : 1
            }
        }
    }

    init(title: String, subtitle: String, symbol: String) {
        super.init(frame: .zero)
        prepareControl(self, radius: 16)
        backgroundColor = SettingsStyle.Color.card
        accessibilityLabel = title
        accessibilityValue = subtitle

        let icon = campusIconTile(
            symbol: symbol,
            spec: CampusIconTileSpec(size: 32, radius: 10, pointSize: 16),
            background: SettingsStyle.Color.accentFill,
            tint: SettingsStyle.Color.link
        )
        let titleLabel = campusLabel(title, size: 15, bold: true, color: SettingsStyle.Color.text, lineHeight: 20)
        let header = UIStackView(arrangedSubviews: [icon, titleLabel])
        header.translatesAutoresizingMaskIntoConstraints = false
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 10
        let subtitleLabel = campusLabel(subtitle, size: 13, bold: false, color: SettingsStyle.Color.secondaryText, lineHeight: 18)
        let content = UIStackView(arrangedSubviews: [header, subtitleLabel])
        content.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 8
        addSubview(content)
        let bottomLessThan = content.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14)
        let bottomEqual = content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        bottomEqual.priority = .defaultHigh
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            bottomLessThan,
            bottomEqual
        ])
        disableInteraction(in: content)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CampusSupportRowControl: UIControl {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.85 : 1
            }
        }
    }

    init(title: String, symbol: String, iconBackground: UIColor, trailingSymbol: String = "chevron.right") {
        super.init(frame: .zero)
        prepareControl(self, radius: 0)
        backgroundColor = .clear
        accessibilityLabel = title

        let icon = campusIconTile(
            symbol: symbol,
            spec: CampusIconTileSpec(size: 28, radius: 8, pointSize: 14),
            background: iconBackground,
            tint: .white
        )
        let titleLabel = campusLabel(title, size: 15, bold: false, color: SettingsStyle.Color.text, lineHeight: 20)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let trailing = campusChevron(symbol: trailingSymbol, pointSize: 13, dimension: 16)
        let row = UIStackView(arrangedSubviews: [icon, titleLabel, trailing])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])
        disableInteraction(in: row)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class CampusSupportGroupView: UIView {
    init(rows: [UIView]) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        for (index, row) in rows.enumerated() {
            stack.addArrangedSubview(row)
            guard index < rows.count - 1 else { continue }
            let separator = UIView()
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.isAccessibilityElement = false
            let line = UIView()
            line.translatesAutoresizingMaskIntoConstraints = false
            line.backgroundColor = SettingsStyle.Color.separator
            separator.addSubview(line)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 1),
                line.leadingAnchor.constraint(equalTo: separator.leadingAnchor, constant: 54),
                line.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
                line.topAnchor.constraint(equalTo: separator.topAnchor),
                line.bottomAnchor.constraint(equalTo: separator.bottomAnchor)
            ])
            stack.addArrangedSubview(separator)
        }
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

@MainActor
private func disableInteraction(in view: UIView) {
    view.isUserInteractionEnabled = false
    for child in view.subviews {
        disableInteraction(in: child)
    }
}
