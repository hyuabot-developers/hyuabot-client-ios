//
//  CafeteriaMealSegmentView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaMealSegmentView: UIView {
    var onSelect: ((CafeteriaMeal) -> Void)?

    private var selectedMeal: CafeteriaMeal = .breakfast
    private let buttons = CafeteriaMeal.allCases.map { _ in UIButton(type: .custom) }
    private let stack = UIStackView()

    init() {
        super.init(frame: .zero)
        accessibilityIdentifier = "cafeteria.meal_segment"
        accessibilityLabel = String(localized: "cafeteria.meal.segment.a11y")
        backgroundColor = SettingsStyle.Color.segmentBackground
        layer.cornerRadius = 12
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 4
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(4) }
        for (index, meal) in CafeteriaMeal.allCases.enumerated() {
            let button = buttons[index]
            button.accessibilityIdentifier = "cafeteria.meal.\(meal.rawValue)"
            button.layer.cornerRadius = 9
            button.tag = index
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            let title = UILabel()
            title.tag = 100
            title.textAlignment = .center
            title.adjustsFontSizeToFitWidth = true
            title.minimumScaleFactor = 0.8
            title.isUserInteractionEnabled = false
            button.addSubview(title)
            title.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.trailing.equalToSuperview().inset(4)
            }
            button.snp.makeConstraints { $0.height.equalTo(36) }
            stack.addArrangedSubview(button)
        }
        configure(selected: .breakfast)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(selected: CafeteriaMeal) {
        selectedMeal = selected
        for (index, meal) in CafeteriaMeal.allCases.enumerated() {
            let button = buttons[index]
            let title = button.viewWithTag(100) as? UILabel
            title?.attributedText = NSAttributedString(
                string: meal.title,
                attributes: [
                    .font: SettingsStyle.font(15, bold: meal == selected),
                    .foregroundColor: meal == selected ? SettingsStyle.Color.text : SettingsStyle.Color.secondaryText,
                ]
            )
            button.backgroundColor = meal == selected ? SettingsStyle.Color.segmentSelected : .clear
            button.accessibilityTraits = meal == selected ? [.button, .selected] : [.button]
            button.accessibilityLabel = meal.title
            button.layer.shadowColor = UIColor.clear.cgColor
            button.layer.shadowOpacity = 0
        }
    }

    @objc
    private func tapped(_ sender: UIButton) {
        onSelect?(CafeteriaMeal.allCases[sender.tag])
    }
}
