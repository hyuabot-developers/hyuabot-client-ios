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
        let fittingSize = footnoteLabel.sizeThatFits(CGSize(width: max(0, width - 40), height: .greatestFiniteMagnitude))
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: fittingSize.height + 8))
        addSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
