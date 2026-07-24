//
//  TransferConnectorView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class TransferConnectorView: UIStackView {
    private let connectorTintColor: UIColor
    private let linkIcon = UIImageView(image: UIImage(systemName: "link"))
    private let titleLabel = UILabel()

    init(title: String, travelMinutes: Int? = nil, tintColor: UIColor) {
        connectorTintColor = tintColor
        super.init(frame: .zero)

        axis = .horizontal
        alignment = .center
        spacing = 4
        layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        isLayoutMarginsRelativeArrangement = true
        layer.cornerRadius = 12
        layer.borderWidth = 1

        linkIcon.contentMode = .scaleAspectFit
        linkIcon.isAccessibilityElement = false
        titleLabel.text = if let travelMinutes {
            String(
                format: String(localized: "home.transfer.connector.travel_time"),
                locale: Locale.current,
                title,
                travelMinutes
            )
        } else {
            title
        }
        isAccessibilityElement = true
        accessibilityLabel = titleLabel.text
        accessibilityTraits = .staticText
        titleLabel.font = .godo(size: 10, weight: .bold)
        titleLabel.numberOfLines = 1
        titleLabel.isAccessibilityElement = false

        addArrangedSubview(linkIcon)
        addArrangedSubview(titleLabel)
        linkIcon.snp.makeConstraints { make in
            make.width.height.equalTo(11)
        }
        updateAppearance()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateAppearance()
    }

    private func updateAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        backgroundColor = isDarkMode ? .secondarySystemBackground : .systemBackground
        layer.borderColor = connectorTintColor
            .withAlphaComponent(isDarkMode ? 0.60 : 0.18)
            .resolvedColor(with: traitCollection)
            .cgColor
        linkIcon.tintColor = isDarkMode ? .white : connectorTintColor.withAlphaComponent(0.72)
        titleLabel.textColor = isDarkMode ? .white : connectorTintColor
    }
}
