//
//  CalendarEventOverlayView.swift
//  hyuabot
//

import UIKit

final class CalendarEventOverlayView: UIView {
    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(weeks: [CalendarWeekLayout], titlesByID: [Int: String], width: CGFloat) {
        subviews.forEach { $0.removeFromSuperview() }
        let columnWidth = width / 7
        for (row, week) in weeks.enumerated() {
            for segment in week.bars {
                let bar = makeBar(segment, title: titlesByID[segment.spanID] ?? "", columnWidth: columnWidth, row: row)
                addSubview(bar)
            }
            for (column, count) in week.overflow {
                let label = UILabel(frame: CGRect(
                    x: CGFloat(column) * columnWidth, y: CGFloat(row) * CalendarGridCell.rowHeight + 50,
                    width: columnWidth, height: 15
                ))
                label.text = "+\(count)"
                label.font = SettingsStyle.monospacedDigitFont(10, bold: true)
                label.textColor = SettingsStyle.Color.secondaryText
                label.textAlignment = .center
                label.isAccessibilityElement = false
                addSubview(label)
            }
        }
    }

    private func makeBar(_ segment: CalendarBarSegment, title: String, columnWidth: CGFloat, row: Int) -> UIView {
        let left: CGFloat = segment.roundLeft ? 2 : 0
        let right: CGFloat = segment.roundRight ? 2 : 0
        let width = CGFloat(segment.endCol - segment.startCol + 1) * columnWidth - left - right
        let bar = UIView(frame: CGRect(
            x: CGFloat(segment.startCol) * columnWidth + left,
            y: CGFloat(row) * CalendarGridCell.rowHeight + 33 + CGFloat(segment.slot) * 17,
            width: width, height: 15
        ))
        bar.backgroundColor = SettingsStyle.Color.calendarCategoryFill(segment.categoryID)
        bar.alpha = segment.dimmed ? 0.45 : 1
        bar.clipsToBounds = true
        bar.isAccessibilityElement = false
        bar.accessibilityElementsHidden = true
        var corners: CACornerMask = []
        if segment.roundLeft { corners.formUnion([.layerMinXMinYCorner, .layerMinXMaxYCorner]) }
        if segment.roundRight { corners.formUnion([.layerMaxXMinYCorner, .layerMaxXMaxYCorner]) }
        bar.layer.maskedCorners = corners
        bar.layer.cornerRadius = corners.isEmpty ? 0 : 4
        if segment.showsLabel {
            let label = UILabel(frame: CGRect(x: 4, y: 0, width: max(0, width - 8), height: 15))
            label.text = title
            label.font = SettingsStyle.font(10, bold: true)
            label.textColor = SettingsStyle.Color.calendarCategoryStrong(segment.categoryID)
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.isAccessibilityElement = false
            bar.addSubview(label)
        }
        return bar
    }
}
