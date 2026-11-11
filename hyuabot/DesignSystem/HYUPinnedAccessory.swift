//
//  HYUPinnedAccessory.swift
//  hyuabot
//

import SnapKit
import UIKit

/// Keeps a header button (or button group) visible at the top-right while its screen scrolls.
///
/// The `placeholder` lives in the scrolling content and reserves the space of the real
/// `content`, which is hosted in a fixed container above the compact bar. `update()` places the
/// content at the placeholder until it would scroll under the navigation bar area, then pins it
/// there, matching the right bar button of navigation-bar based screens.
@MainActor
final class HYUPinnedAccessory {
    let placeholder = UIView()

    private let content: UIView
    private weak var container: UIView?
    private var topConstraint: Constraint?
    private var lastTop: CGFloat = .nan

    init(content: UIView) {
        self.content = content
        placeholder.isUserInteractionEnabled = false
    }

    func install(in container: UIView) {
        self.container = container
        container.addSubview(content)
        content.snp.makeConstraints { make in
            make.trailing.equalTo(placeholder.snp.trailing)
            topConstraint = make.top.equalToSuperview().constraint
        }
        placeholder.snp.makeConstraints { make in
            make.width.equalTo(content.snp.width)
            make.height.equalTo(content.snp.height)
        }
        update()
    }

    /// Pass `layoutNow: false` when called from a layout callback to avoid re-entrant layout.
    func update(layoutNow: Bool = true) {
        guard let container, placeholder.superview != nil else { return }
        let natural = placeholder.convert(placeholder.bounds, to: container).minY
        let pinned = container.safeAreaInsets.top + 22 - content.bounds.height / 2
        let top = max(natural, pinned)
        guard top != lastTop else { return }
        lastTop = top
        topConstraint?.update(offset: top)
        if layoutNow { container.layoutIfNeeded() }
    }
}
