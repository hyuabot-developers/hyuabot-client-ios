//
//  CalendarHeaderViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CalendarTodayPillView: UIControl {
    private let titleLabel = UILabel()

    override var intrinsicContentSize: CGSize {
        CGSize(width: 16 + 6 + titleLabel.intrinsicContentSize.width + 24, height: 44)
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let capsule = UIView()
        capsule.backgroundColor = SettingsStyle.Color.accentFill
        capsule.layer.cornerRadius = 18
        capsule.layer.cornerCurve = .continuous
        capsule.isUserInteractionEnabled = false
        addSubview(capsule)
        capsule.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
            make.leading.trailing.equalToSuperview()
        }

        let image = UIImageView(image: UIImage(
            systemName: "calendar",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        ))
        image.tintColor = SettingsStyle.Color.link
        let stack = UIStackView(arrangedSubviews: [image, titleLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        capsule.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
        image.snp.makeConstraints { $0.size.equalTo(16) }
        titleLabel.text = String(localized: "calendar.today")
        titleLabel.font = SettingsStyle.font(14, bold: true)
        titleLabel.textColor = SettingsStyle.Color.link
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = "calendar.today_button"
        accessibilityLabel = String(localized: "calendar.today.accessibility")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CalendarCategoryFilterView: UIView {
    var onToggle: ((Int) -> Void)?
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var buttons: [CategoryChipButton] = []

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.clipsToBounds = false
        scrollView.accessibilityLabel = String(localized: "calendar.filter.accessibility")
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        scrollView.addSubview(stack)
        scrollView.contentLayoutGuide.snp.makeConstraints { make in
            make.height.equalTo(scrollView.frameLayoutGuide.snp.height)
        }
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.centerY.equalTo(scrollView.frameLayoutGuide.snp.centerY)
            make.height.equalTo(32)
        }
    }

    func configure(items: [CalendarCategoryItem], hidden: Set<Int>) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        for item in items {
            let button = CategoryChipButton(item: item, isHiddenCategory: hidden.contains(item.id))
            button.addAction(UIAction { [weak self] _ in self?.onToggle?(item.id) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class CategoryChipButton: UIButton {
    private let item: CalendarCategoryItem
    private let isHiddenCategory: Bool
    private let dotView = UIView()

    init(item: CalendarCategoryItem, isHiddenCategory: Bool) {
        self.item = item
        self.isHiddenCategory = isHiddenCategory
        super.init(frame: .zero)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        let label = UILabel()
        label.text = item.name
        label.font = SettingsStyle.font(13, bold: true)
        label.textColor = isHiddenCategory ? SettingsStyle.Color.secondaryText : SettingsStyle.Color.text
        label.numberOfLines = 1
        label.isUserInteractionEnabled = false
        dotView.layer.cornerRadius = 4
        dotView.isUserInteractionEnabled = false
        let content = UIStackView(arrangedSubviews: [dotView, label])
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = 6
        content.isUserInteractionEnabled = false
        addSubview(content)
        content.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        dotView.snp.makeConstraints { $0.size.equalTo(8) }
        snp.makeConstraints { $0.height.equalTo(32) }
        accessibilityLabel = item.name
        accessibilityIdentifier = "calendar.category_chip.\(item.id)"
        accessibilityTraits = isHiddenCategory ? .button : [.button, .selected]
        updateColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
            view.updateColors()
        }
    }

    private func updateColors() {
        backgroundColor = isHiddenCategory ? .clear : SettingsStyle.Color.card
        let border = isHiddenCategory ? SettingsStyle.Color.separator : SettingsStyle.Color.card
        layer.borderColor = border.resolvedColor(with: traitCollection).cgColor
        if isHiddenCategory {
            dotView.backgroundColor = .clear
            dotView.layer.borderWidth = 1.5
            dotView.layer.borderColor = SettingsStyle.Color.faint.resolvedColor(with: traitCollection).cgColor
        } else {
            dotView.backgroundColor = SettingsStyle.Color.calendarCategoryStrong(item.id)
            dotView.layer.borderWidth = 0
            dotView.layer.borderColor = nil
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
