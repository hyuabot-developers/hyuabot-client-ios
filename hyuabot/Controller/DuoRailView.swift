//
//  DuoRailView.swift
//  hyuabot
//
//  Vertical tab rail shown instead of the floating capsule bar when unfolded.
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
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
        let divider = UIView()
        divider.backgroundColor = SettingsStyle.Color.tabEdge
        addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.topAnchor.constraint(equalTo: topAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
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
