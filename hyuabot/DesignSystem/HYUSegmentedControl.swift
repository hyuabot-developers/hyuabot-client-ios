//
//  HYUSegmentedControl.swift
//  hyuabot
//

import SnapKit
import UIKit

/// Pill-style segmented control built from SettingsStyle tokens.
final class HYUSegmentedControl: UIView {
    var onSelect: ((Int) -> Void)?
    private(set) var selectedIndex = 0
    private var buttons: [UIButton] = []
    private var titles: [String] = []
    private let stack = UIStackView()

    init(buttonIdentifierPrefix: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.segmentBackground
        layer.cornerRadius = SettingsStyle.Metric.segmentRadius
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = SettingsStyle.Metric.segmentInset
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(SettingsStyle.Metric.segmentInset) }
        self.buttonIdentifierPrefix = buttonIdentifierPrefix
    }

    private var buttonIdentifierPrefix: String?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(titles: [String], selected: Int) {
        if titles != self.titles {
            self.titles = titles
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buttons = titles.indices.map { index in
                let button = UIButton(type: .custom)
                button.tag = index
                button.layer.cornerRadius = SettingsStyle.Metric.segmentRadius - SettingsStyle.Metric.segmentInset + 1
                button.accessibilityLabel = titles[index]
                if let prefix = buttonIdentifierPrefix { button.accessibilityIdentifier = "\(prefix).\(index)" }
                button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
                let label = UILabel()
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.8
                label.isUserInteractionEnabled = false
                label.tag = Self.labelTag
                button.addSubview(label)
                label.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(4) }
                button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(SettingsStyle.Metric.segmentButtonHeight) }
                stack.addArrangedSubview(button)
                return button
            }
        }
        selectedIndex = selected
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selected
            (button.viewWithTag(Self.labelTag) as? UILabel)?.attributedText = NSAttributedString(
                string: titles[index],
                attributes: [
                    .font: SettingsStyle.font(15, bold: isSelected),
                    .foregroundColor: isSelected ? SettingsStyle.Color.text : SettingsStyle.Color.secondaryText
                ]
            )
            button.backgroundColor = isSelected ? SettingsStyle.Color.segmentSelected : .clear
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }

    private static let labelTag = 100

    @objc
    private func tapped(_ sender: UIButton) {
        onSelect?(sender.tag)
    }
}
