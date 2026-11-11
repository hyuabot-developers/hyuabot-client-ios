//
//  HYUHeaderButton.swift
//  hyuabot
//

import UIKit
import SnapKit

class HYUHeaderButton: UIControl {
    enum Style {
        case capsule
        case circle
    }

    let capsuleView = UIView()

    private let style: Style
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let contentStack = UIStackView()

    init(style: Style, symbolName: String?, title: String?) {
        self.style = style
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title

        capsuleView.backgroundColor = SettingsStyle.Color.accentFill
        capsuleView.layer.cornerRadius = HYUMetrics.Layout.headerButtonHeight / 2
        capsuleView.layer.cornerCurve = HYUMetrics.cornerCurve
        capsuleView.isUserInteractionEnabled = false
        addSubview(capsuleView)

        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconView.tintColor = SettingsStyle.Color.link
        titleLabel.font = SettingsStyle.font(14, bold: true)
        titleLabel.textColor = SettingsStyle.Color.link
        contentStack.axis = .horizontal
        contentStack.spacing = 6
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        capsuleView.addSubview(contentStack)

        iconView.snp.makeConstraints { make in
            make.size.equalTo(18)
        }

        switch style {
        case .capsule:
            capsuleView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalTo(HYUMetrics.Layout.headerButtonHeight)
                make.leading.trailing.equalToSuperview()
            }
            contentStack.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(12)
                make.centerY.equalToSuperview()
            }
        case .circle:
            capsuleView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(HYUMetrics.Layout.headerButtonHeight)
            }
            contentStack.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            titleLabel.isHidden = true
        }

        setTitle(title)
        setSymbol(symbolName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
        titleLabel.isHidden = title == nil || style == .circle
        if let title {
            accessibilityLabel = title
        }
        invalidateIntrinsicContentSize()
    }

    func setSymbol(_ symbolName: String?) {
        iconView.image = symbolName.flatMap { UIImage(systemName: $0, withConfiguration: iconView.preferredSymbolConfiguration) }
        iconView.isHidden = symbolName == nil
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        switch style {
        case .circle:
            return CGSize(width: HYUMetrics.Layout.headerButtonHitHeight, height: HYUMetrics.Layout.headerButtonHitHeight)
        case .capsule:
            let hasIcon = !iconView.isHidden
            let hasTitle = !titleLabel.isHidden
            let width = 12
                + (hasIcon ? 18 : 0)
                + (hasIcon && hasTitle ? 6 : 0)
                + (hasTitle ? titleLabel.intrinsicContentSize.width : 0)
                + 12
            return CGSize(width: max(HYUMetrics.Layout.headerButtonHitHeight, width), height: HYUMetrics.Layout.headerButtonHitHeight)
        }
    }

    override var isHighlighted: Bool {
        didSet {
            capsuleView.alpha = isHighlighted ? 0.6 : 1
        }
    }

    override var isEnabled: Bool {
        didSet {
            capsuleView.alpha = isEnabled ? 1 : 0.4
            accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
        }
    }
}
