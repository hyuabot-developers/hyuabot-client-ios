//
//  HYUOverflowHitStackView.swift
//  hyuabot
//

import UIKit

/// Stack view that also hit-tests subviews extending beyond its bounds (e.g. a 44pt button in a 20pt row).
final class HYUOverflowHitStackView: UIStackView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }
        for subview in subviews.reversed() {
            let converted = subview.convert(point, from: self)
            if let hit = subview.hitTest(converted, with: event) { return hit }
        }
        return super.hitTest(point, with: event)
    }
}

extension NSAttributedString {
    func withKern(_ kern: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        result.addAttribute(.kern, value: kern, range: NSRange(location: 0, length: result.length))
        return result
    }
}
