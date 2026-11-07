//
//  FloatingTabBar.swift
//  hyuabot
//

import UIKit

final class FloatingTabBarButton: UIControl {
    private(set) var item: UITabBarItem
    var isCurrent = false {
        didSet { applyState() }
    }

    private let imageView = UIImageView()
    private let label = UILabel()

    init(item: UITabBarItem) {
        self.item = item
        super.init(frame: .zero)

        layer.cornerRadius = 27
        layer.cornerCurve = .continuous
        isAccessibilityElement = true
        showsLargeContentViewer = true

        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        imageView.contentMode = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textAlignment = .center

        applyItemMetadata()
        applyState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(item: UITabBarItem) {
        self.item = item
        applyItemMetadata()
        applyState()
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    private func applyItemMetadata() {
        accessibilityLabel = item.title
        accessibilityIdentifier = item.accessibilityIdentifier
        largeContentTitle = item.title
        largeContentImage = item.image
    }

    private func applyState() {
        let color = isCurrent ? SettingsStyle.Color.accent : SettingsStyle.Color.tabUnselected
        backgroundColor = isCurrent ? SettingsStyle.Color.tabSelectionFill : .clear
        imageView.image = item.image?.applyingSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 19, weight: isCurrent ? .semibold : .regular)
        )
        imageView.tintColor = color
        label.attributedText = SettingsStyle.attributedText(
            item.title ?? "",
            font: UIFont.godo(size: 10, weight: isCurrent ? .bold : .regular),
            color: color,
            lineHeight: 12
        )
        label.textAlignment = .center
        accessibilityTraits = isCurrent ? [.button, .selected] : .button
    }
}

final class FloatingTabBar: UIView {
    static let barHeight: CGFloat = 64
    static let sideInset: CGFloat = 16
    static let bottomInset: CGFloat = 16
    static let maxWidth: CGFloat = 480

    var onSelect: ((Int) -> Void)?
    var selectedIndex: Int = 0 {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.updateCurrentButtons()
            }
        }
    }

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let stack = UIStackView()
    private var buttons: [FloatingTabBarButton] = []

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        layer.cornerRadius = 32
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 12

        blurView.layer.cornerRadius = 32
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false
        blurView.contentView.backgroundColor = SettingsStyle.Color.tabGlass
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 0
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])

        isAccessibilityElement = false
        accessibilityIdentifier = "tab.bar"
        accessibilityTraits = .tabBar
        addInteraction(UILargeContentViewerInteraction())
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
            view.updateLayerColors()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItems(_ items: [UITabBarItem]) {
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        buttons.removeAll()
        for (index, item) in items.enumerated() {
            let button = FloatingTabBarButton(item: item)
            button.addAction(UIAction { [weak self] _ in self?.onSelect?(index) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
        updateCurrentButtons()
    }

    func button(at index: Int) -> FloatingTabBarButton? {
        guard buttons.indices.contains(index) else { return nil }
        return buttons[index]
    }

    func updateItem(_ item: UITabBarItem, at index: Int) {
        button(at: index)?.update(item: item)
    }

    private func updateCurrentButtons() {
        for (index, button) in buttons.enumerated() {
            button.isCurrent = index == selectedIndex
        }
    }

    private func updateLayerColors() {
        layer.borderColor = SettingsStyle.Color.tabEdge.resolvedColor(with: traitCollection).cgColor
        if traitCollection.userInterfaceStyle == .dark {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.45
        } else {
            layer.shadowColor = UIColor(red: 17 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1).cgColor
            layer.shadowOpacity = 0.12
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 32).cgPath
    }
}
