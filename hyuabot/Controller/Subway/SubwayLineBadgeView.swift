//
//  SubwayLineBadgeView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SubwayLineBadgeView: UIView {
    enum Size { case regular, large }

    private let size: Size
    private let label = UILabel()
    private var widthConstraint: Constraint!
    private var heightConstraint: Constraint!

    init(size: Size) {
        self.size = size
        super.init(frame: .zero)
        isAccessibilityElement = false
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(size == .regular ? 24 : 28).constraint
            widthConstraint = make.width.equalTo(size == .regular ? 24 : 28).constraint
        }
        layer.cornerRadius = size == .regular ? 12 : 14
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ badge: SubwaySectionBadge) {
        switch badge {
        case let .line(route):
            let text = route.badgeText
            label.attributedText = NSAttributedString(string: text, attributes: [.kern: 0])
            label.font = SettingsStyle.font(text.count > 1 ? (size == .regular ? 12 : 13) : (size == .regular ? 14 : 16), bold: true)
            label.textColor = .white
            backgroundColor = route.color
            let inset: CGFloat = text.count > 1 ? (size == .regular ? 6 : 8) : 0
            let badgeWidth: CGFloat = text.count > 1 ? label.intrinsicContentSize.width + inset * 2 : (size == .regular ? 24 : 28)
            widthConstraint.update(offset: badgeWidth)
            label.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(inset)
            }
        case .transfer:
            label.attributedText = NSAttributedString(string: "⇄", attributes: [.kern: 0])
            label.font = SettingsStyle.font(13, bold: true)
            label.textColor = SettingsStyle.Color.link
            backgroundColor = SettingsStyle.Color.accentFill
            label.snp.remakeConstraints { $0.center.equalToSuperview() }
            widthConstraint.update(offset: 24)
            heightConstraint.update(offset: 24)
        }
    }
}
