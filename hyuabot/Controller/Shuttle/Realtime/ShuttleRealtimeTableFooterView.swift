//
//  ShuttleRealtimeTableFooterView.swift
//  hyuabot
//

import UIKit

final class ShuttleRealtimeTableFooterView: UIView {
    private let footnoteLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.attributedText = SettingsStyle.attributedText(
            String(localized: "shuttle.realtime.footnote"),
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16
        )
    }

    init(parentView: UIView) {
        let width = parentView.bounds.width
        // The last section footer already ends with a card gap; pull the note up so the gap above it is contentToFootnote.
        let pullUp = HYUMetrics.Layout.cardGap - HYUMetrics.Layout.contentToFootnote
        let fittingSize = footnoteLabel.sizeThatFits(CGSize(width: max(0, width - 40), height: .greatestFiniteMagnitude))
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: fittingSize.height + 8 - pullUp))
        addSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-pullUp)
            make.leading.equalTo(safeAreaLayoutGuide).offset(20); make.trailing.equalTo(safeAreaLayoutGuide).offset(-20)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
