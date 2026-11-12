//
//  SettingsComponents.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SettingsIconTileView: UIView {
    init(symbolName: String, color: UIColor, size: CGFloat = 30, radius: CGFloat = 8, glyphPointSize: CGFloat = 16) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        isAccessibilityElement = false
        isUserInteractionEnabled = false
        let image = UIImageView(image: UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: glyphPointSize, weight: .semibold)
        ))
        image.tintColor = .white
        image.contentMode = .scaleAspectFit
        image.isUserInteractionEnabled = false
        addSubview(image)
        snp.makeConstraints { $0.size.equalTo(size) }
        image.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(glyphPointSize)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class SettingsCardView: UIView {
    private let stack = UIStackView()

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func addRow(_ row: UIView, separatorInset: CGFloat = SettingsStyle.Metric.separatorInset) {
        if !stack.arrangedSubviews.isEmpty {
            let container = UIView()
            let line = UIView()
            line.backgroundColor = SettingsStyle.Color.separator
            container.addSubview(line)
            stack.addArrangedSubview(container)
            container.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
            line.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: separatorInset, bottom: 0, right: 0))
            }
        }
        stack.addArrangedSubview(row)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class SettingsSectionView: UIView {
    init(header: String?, content: UIView, footer: String? = nil, trailingHeader: String? = nil) {
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .vertical
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        if let header {
            let row = UIStackView()
            row.alignment = .firstBaseline
            row.distribution = .equalSpacing
            let label = headerLabel(header)
            label.accessibilityTraits = .header
            row.addArrangedSubview(label)
            if let trailingHeader { row.addArrangedSubview(headerLabel(trailingHeader)) }
            let headerContainer = UIView()
            headerContainer.addSubview(row)
            row.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(SettingsStyle.Metric.sectionHeaderTop)
                make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.sectionHeaderInsetX)
                make.bottom.equalToSuperview()
            }
            stack.addArrangedSubview(headerContainer)
            stack.setCustomSpacing(8, after: headerContainer)
        }
        stack.addArrangedSubview(content)
        content.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset) }
        if let footer {
            let label = UILabel()
            label.font = SettingsStyle.font(12.5)
            label.textColor = SettingsStyle.Color.secondaryText
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
            label.text = footer
            let footerContainer = UIView()
            footerContainer.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.sectionHeaderInsetX)
                make.top.bottom.equalToSuperview()
            }
            stack.addArrangedSubview(footerContainer)
            stack.setCustomSpacing(HYUMetrics.Layout.contentToFootnote, after: content)
        }
    }

    private func headerLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = SettingsStyle.font(13)
        label.textColor = SettingsStyle.Color.secondaryText
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        return label
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

enum SettingsRowAccessory {
    case none
    case chevron
    case externalLink
    case value(String)
    case valueAndExternalLink(String, accessibilityLabel: String)
    case action(String)
    case toggle(UISwitch)
}

final class SettingsRowView: UIControl {
    private let title: String
    private let subtitle: String?
    private let accessory: SettingsRowAccessory
    var onTap: (() -> Void)?

    init(
        symbolName: String?, tileColor: UIColor?, title: String, subtitle: String? = nil,
        accessory: SettingsRowAccessory = .none, minHeight: CGFloat = SettingsStyle.Metric.rowMinHeight,
        verticalPadding: CGFloat = 0, subtitleMonospacedDigits: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        super.init(frame: .zero)
        let content = UIStackView()
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 12
        content.isUserInteractionEnabled = false
        addSubview(content)
        content.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(verticalPadding)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.greaterThanOrEqualTo(minHeight - verticalPadding * 2)
        }
        if let symbolName, let tileColor {
            content.addArrangedSubview(SettingsIconTileView(symbolName: symbolName, color: tileColor))
        }
        let labels = UIStackView()
        labels.axis = .vertical
        labels.spacing = 4
        labels.isUserInteractionEnabled = false
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = SettingsStyle.font(16)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.numberOfLines = 0
        titleLabel.isUserInteractionEnabled = false
        labels.addArrangedSubview(titleLabel)
        if let subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = subtitle
            subtitleLabel.font = subtitleMonospacedDigits ? monospacedFont() : SettingsStyle.font(13)
            subtitleLabel.textColor = SettingsStyle.Color.secondaryText
            subtitleLabel.numberOfLines = 0
            subtitleLabel.isUserInteractionEnabled = false
            labels.addArrangedSubview(subtitleLabel)
        }
        content.addArrangedSubview(labels)
        labels.setContentHuggingPriority(.defaultLow, for: .horizontal)
        appendAccessory(to: content)
        isAccessibilityElement = true
        accessibilityLabel = [title, subtitle, accessoryText].compactMap { $0 }.joined(separator: ", ")
        accessibilityTraits = .button
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        if case let .toggle(toggle) = accessory {
            isAccessibilityElement = false
            titleLabel.isAccessibilityElement = false
            labels.accessibilityElements = []
            accessibilityElements = [toggle]
            toggle.onTintColor = SettingsStyle.Color.accent
            toggle.accessibilityLabel = title
            toggle.accessibilityHint = subtitle
        }
    }

    private var accessoryText: String? {
        switch accessory {
        case let .value(value), let .valueAndExternalLink(value, _), let .action(value): value
        default: nil
        }
    }

    private func appendAccessory(to stack: UIStackView) {
        switch accessory {
        case .none, .toggle:
            if case let .toggle(toggle) = accessory { stack.addArrangedSubview(toggle) }
        case .chevron: stack.addArrangedSubview(icon("chevron.right"))
        case .externalLink: stack.addArrangedSubview(icon("arrow.up.right"))
        case let .value(text): stack.addArrangedSubview(valueLabel(text))
        case let .valueAndExternalLink(text, accessibilityLabel):
            let group = UIStackView(arrangedSubviews: [valueLabel(text), icon("arrow.up.right")])
            group.spacing = 6
            group.alignment = .center
            group.setContentHuggingPriority(.required, for: .horizontal)
            group.setContentCompressionResistancePriority(.required, for: .horizontal)
            group.arrangedSubviews.forEach {
                $0.setContentHuggingPriority(.required, for: .horizontal)
                $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            group.isUserInteractionEnabled = false
            stack.addArrangedSubview(group)
            self.accessibilityHint = accessibilityLabel
        case let .action(text):
            let label = valueLabel(text)
            label.font = SettingsStyle.font(14, bold: true)
            label.textColor = SettingsStyle.Color.link
            stack.addArrangedSubview(label)
        }
    }

    private func icon(_ name: String) -> UIImageView {
        let view = UIImageView(image: UIImage(
            systemName: name,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        ))
        view.isUserInteractionEnabled = false
        view.tintColor = SettingsStyle.Color.secondaryText
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        if name == "chevron.right" {
            view.snp.makeConstraints { $0.width.equalTo(7); $0.height.equalTo(12) }
        } else {
            view.snp.makeConstraints { $0.size.equalTo(14) }
        }
        return view
    }

    private func valueLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = SettingsStyle.font(15)
        label.textColor = SettingsStyle.Color.secondaryText
        label.isUserInteractionEnabled = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func monospacedFont() -> UIFont {
        let settings = [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                         UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]]
        let descriptor = UIFont.godo(size: 12.5, weight: .regular).fontDescriptor.addingAttributes([
            .featureSettings: settings
        ])
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont(descriptor: descriptor, size: 12.5))
    }

    @objc
    private func didTap() {
        onTap?()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if case let .toggle(toggle) = accessory {
            let togglePoint = convert(point, to: toggle)
            if toggle.bounds.contains(togglePoint) {
                return toggle.hitTest(togglePoint, with: event)
            }
        }
        return super.hitTest(point, with: event)
    }

    override var isHighlighted: Bool {
        didSet {
            guard case .toggle = accessory else {
                backgroundColor = isHighlighted ? SettingsStyle.Color.separator.withAlphaComponent(0.6) : .clear
                return
            }
            backgroundColor = .clear
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class SettingsAppInfoFooterView: UIView {
    init(appName: String, versionText: String, developerText: String) {
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(48)
        }
        let name = label(appName, size: 15, color: SettingsStyle.Color.text)
        name.font = SettingsStyle.font(15, bold: true)
        stack.addArrangedSubview(name)
        stack.addArrangedSubview(label(versionText, size: 13, color: SettingsStyle.Color.secondaryText))
        stack.addArrangedSubview(label(developerText, size: 13, color: SettingsStyle.Color.secondaryText))
    }

    private func label(_ text: String, size: CGFloat, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = SettingsStyle.font(size)
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
