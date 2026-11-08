//
//  SubwaySegmentView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SubwaySegmentView: UIView {
    struct Item: Equatable { let title: String; let dotColors: [UIColor]; let count: String? }

    var onSelect: ((Int) -> Void)?
    private(set) var selectedIndex = 0
    private let prefix: String
    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var items: [Item] = []

    init(buttonIdentifierPrefix: String) {
        prefix = buttonIdentifierPrefix
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.segmentBackground
        layer.cornerRadius = SettingsStyle.Metric.segmentRadius
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = SettingsStyle.Metric.segmentInset
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(SettingsStyle.Metric.segmentInset) }
        snp.makeConstraints { $0.height.equalTo(44) }
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _: UITraitCollection) in
            view.applyShadow()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [Item], selected: Int) {
        if items != self.items {
            self.items = items
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buttons = items.enumerated().map { index, item in makeButton(item, index: index) }
        }
        selectedIndex = selected
        for (index, button) in buttons.enumerated() {
            style(button, item: items[index], selected: index == selected)
        }
        applyShadow()
    }

    func button(at index: Int) -> UIView? {
        buttons.indices.contains(index) ? buttons[index] : nil
    }

    private func makeButton(_ item: Item, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = index
        button.accessibilityIdentifier = "\(prefix).\(index)"
        button.layer.cornerRadius = SettingsStyle.Metric.segmentRadius - SettingsStyle.Metric.segmentInset + 1
        button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
        button.snp.makeConstraints { $0.height.equalTo(SettingsStyle.Metric.segmentButtonHeight) }
        let content = UIStackView()
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 6
        content.isUserInteractionEnabled = false
        button.addSubview(content)
        content.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().offset(4)
            $0.trailing.lessThanOrEqualToSuperview().offset(-4)
        }
        if !item.dotColors.isEmpty {
            let dots = UIStackView()
            dots.axis = .horizontal
            dots.spacing = 2
            for color in item.dotColors {
                let dot = UIView()
                dot.backgroundColor = color
                dot.layer.cornerRadius = 4
                dot.snp.makeConstraints { $0.width.height.equalTo(8) }
                dots.addArrangedSubview(dot)
            }
            content.addArrangedSubview(dots)
        }
        let title = UILabel()
        title.text = item.title
        title.lineBreakMode = .byTruncatingTail
        content.addArrangedSubview(title)
        if let count = item.count {
            let countLabel = UILabel()
            countLabel.text = count
            countLabel.font = SettingsStyle.monospacedDigitFont(12)
            countLabel.textColor = SettingsStyle.Color.commuterFaint
            content.addArrangedSubview(countLabel)
        }
        stack.addArrangedSubview(button)
        return button
    }

    private func style(_ button: UIButton, item: Item, selected: Bool) {
        guard let content = button.subviews.first as? UIStackView else { return }
        guard let title = content.arrangedSubviews.compactMap({ $0 as? UILabel }).first else { return }
        title.font = SettingsStyle.font(15, bold: selected)
        title.textColor = selected ? SettingsStyle.Color.text : SettingsStyle.Color.secondaryText
        button.backgroundColor = selected ? SettingsStyle.Color.segmentSelected : .clear
        button.accessibilityLabel = item.title + (item.count.map { " " + $0 } ?? "")
        button.accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    private func applyShadow() {
        for (index, button) in buttons.enumerated() {
            let selected = index == selectedIndex
            button.layer.shadowColor = SettingsStyle.Color.segmentShadow.resolvedColor(with: traitCollection).cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 1.5
            button.layer.shadowOpacity = selected && traitCollection.userInterfaceStyle != .dark ? 0.12 : 0
        }
    }

    @objc
    private func tapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        for (index, button) in buttons.enumerated() {
            style(button, item: items[index], selected: index == selectedIndex)
        }
        applyShadow()
        onSelect?(selectedIndex)
    }
}
