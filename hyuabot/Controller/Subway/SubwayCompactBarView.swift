//
//  SubwayCompactBarView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SubwayCompactBarView: UIView {
    private let titleLabel = UILabel()
    private var titleCenterConstraint: Constraint?

    init(maxTitleWidth: CGFloat?, titleCenterFromBottom: CGFloat? = nil) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        alpha = 0
        accessibilityElementsHidden = true
        accessibilityIdentifier = "subway.compactBar"
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blurView.contentView.backgroundColor = SettingsStyle.Color.subwayCompactBar
        addSubview(blurView)
        blurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let hairline = UIView()
        hairline.backgroundColor = SettingsStyle.Color.separator
        addSubview(hairline)
        hairline.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textAlignment = .center
        titleLabel.accessibilityTraits = .header
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            if let titleCenterFromBottom {
                titleCenterConstraint = make.centerY.equalTo(self.snp.bottom).offset(-titleCenterFromBottom).constraint
            } else {
                make.bottom.equalToSuperview().offset(-11)
            }
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            if let maxTitleWidth {
                make.width.lessThanOrEqualTo(maxTitleWidth)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitleCenterFromBottom(_ value: CGFloat) {
        titleCenterConstraint?.update(offset: -value)
    }

    func setTitle(_ title: String) {
        titleLabel.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(17, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 22
        )
    }

    func setRevealProgress(_ progress: CGFloat) {
        alpha = progress
        accessibilityElementsHidden = progress < 0.5
    }

    static func revealProgress(contentOffsetY: CGFloat, adjustedTopInset: CGFloat) -> CGFloat {
        min(max((contentOffsetY + adjustedTopInset - 36) / 16, 0), 1)
    }
}
