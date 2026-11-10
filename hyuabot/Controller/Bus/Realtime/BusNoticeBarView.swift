//
//  BusNoticeBarView.swift
//  hyuabot
//

import UIKit
import SnapKit
import Then

final class BusNoticeBarView: UIView {
    let carousel = NoticeCarouselView()

    private let megaphoneView = UIImageView().then {
        $0.image = UIImage(systemName: "megaphone", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16))
        $0.tintColor = SettingsStyle.Color.link
        $0.contentMode = .scaleAspectFit
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }

    private let counterLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(12)
        $0.textColor = SettingsStyle.Color.commuterFaint
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.adjustsFontForContentSizeCategory = true
    }

    private let chevronView = UIImageView().then {
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        $0.image = UIImage(systemName: "chevron.right", withConfiguration: configuration)
        $0.tintColor = SettingsStyle.Color.chevron
        $0.contentMode = .scaleAspectFit
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }

    private lazy var contentStack = UIStackView(arrangedSubviews: [megaphoneView, carousel, counterLabel, chevronView]).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityIdentifier = "bus.notice.bar"
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 12
        clipsToBounds = true
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview()
        }
        megaphoneView.snp.makeConstraints { make in
            make.size.equalTo(18)
        }
        carousel.setContentHuggingPriority(.init(249), for: .horizontal)
        carousel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        carousel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        counterLabel.setContentHuggingPriority(.required, for: .horizontal)
        counterLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronView.snp.makeConstraints { make in
            make.size.equalTo(14)
        }
        carousel.titleColor = SettingsStyle.Color.text
        carousel.titleStyle = NoticeTitleStyle(
            font: SettingsStyle.font(14),
            alignment: .natural,
            horizontalInset: 0,
            lineHeight: 20,
            shrinksToFit: false
        )
        carousel.onPageChanged = { [weak self] index, count in
            self?.updateCounter(index: index, count: count)
        }
        snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCounter(index: Int, count: Int) {
        counterLabel.isHidden = count <= 1
        guard count > 1 else { return }
        let text = "\(index + 1)/\(count)"
        counterLabel.attributedText = SettingsStyle.attributedText(
            text,
            font: SettingsStyle.monospacedDigitFont(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
    }
}
