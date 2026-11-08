//
//  HYUPaddedLabel.swift
//  hyuabot
//

import UIKit

/// A label that draws its text inset by `padding`, for pill/chip styles.
final class HYUPaddedLabel: UILabel {
    var padding = UIEdgeInsets.zero

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + padding.left + padding.right, height: size.height + padding.top + padding.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let inner = CGSize(
            width: max(0, size.width - padding.left - padding.right),
            height: max(0, size.height - padding.top - padding.bottom)
        )
        let fitted = super.sizeThatFits(inner)
        return CGSize(width: fitted.width + padding.left + padding.right, height: fitted.height + padding.top + padding.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }
}
