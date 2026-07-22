//
//  ShuttlePresenceBannerView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class ShuttlePresenceBannerView: UIView {
    private let label = UILabel()
    private var isShowingCount = false

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: isShowingCount ? 34 : 0)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .hanyangBlue
        clipsToBounds = true
        label.font = .godo(size: 13, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 1
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(viewerCount: Int?) {
        isShowingCount = viewerCount != nil
        if let viewerCount {
            label.text = String(
                format: String(localized: "shuttle.presence.viewers"),
                locale: Locale.current,
                viewerCount
            )
            accessibilityLabel = label.text
        } else {
            label.text = nil
            accessibilityLabel = nil
        }
        invalidateIntrinsicContentSize()
        superview?.setNeedsLayout()
    }
}
