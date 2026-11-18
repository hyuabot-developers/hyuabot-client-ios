//
//  DuoRailView.swift
//  hyuabot
//
//  Vertical glass capsule shown instead of the floating tab bar when unfolded; sits on the right edge below the system clock.
//

import UIKit

final class DuoRailView: UIView {
    var onSelect: ((Int) -> Void)?
    var selectedIndex = 0 {
        didSet { buttons.enumerated().forEach { $0.element.isCurrent = $0.offset == selectedIndex } }
    }

    private let stack = UIStackView()
    private var buttons: [FloatingTabBarButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.tabGlass
        accessibilityIdentifier = "tab.rail"
        layer.cornerRadius = DuoLayout.railWidth / 2
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = SettingsStyle.Color.tabEdge.cgColor
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setItems(_ items: [UITabBarItem]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons = items.enumerated().map { index, item in
            let button = FloatingTabBarButton(item: item)
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            return button
        }
        selectedIndex = { selectedIndex }()
    }
}
