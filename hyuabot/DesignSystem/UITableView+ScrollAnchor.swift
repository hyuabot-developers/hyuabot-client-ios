//
//  UITableView+ScrollAnchor.swift
//  hyuabot
//

import UIKit

extension UITableView {
    /// Runs a reload and keeps the content the user is looking at where it was.
    ///
    /// Periodic data refreshes reload whole tables. Rows that are measured lazily (empty states, footers whose height
    /// depends on data) are first estimated and then resolved, which shifts the offset under the user's finger.
    /// The topmost visible row is used as an anchor and put back at the same distance from the viewport top.
    func reloadPreservingScrollPosition(_ reload: () -> Void) {
        let minOffset = -adjustedContentInset.top
        guard window != nil, contentOffset.y > minOffset + 1,
              let anchor = indexPathsForVisibleRows?.min() else {
            reload()
            return
        }
        let distanceFromTop = rectForRow(at: anchor).minY - contentOffset.y
        reload()
        layoutIfNeeded()
        guard anchor.section < numberOfSections, anchor.row < numberOfRows(inSection: anchor.section) else { return }
        let maxOffset = max(minOffset, contentSize.height + adjustedContentInset.bottom - bounds.height)
        let target = min(max(rectForRow(at: anchor).minY - distanceFromTop, minOffset), maxOffset)
        // Never fight a drag or a fling that is already moving the content.
        if abs(contentOffset.y - target) > 0.5, !isTracking, !isDecelerating {
            setContentOffset(CGPoint(x: 0, y: target), animated: false)
        }
    }

    func reloadDataPreservingScrollPosition() {
        reloadPreservingScrollPosition { reloadData() }
    }
}
