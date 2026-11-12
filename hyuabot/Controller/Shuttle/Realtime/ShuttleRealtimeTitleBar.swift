//
//  ShuttleRealtimeTitleBar.swift
//  hyuabot
//

import SnapKit
import UIKit

@MainActor
final class ShuttleRealtimeTitleBar: UIView {
    let settingsButton = UIButton(type: .custom)
    var onSettingsTap: (() -> Void)?

    private let titleLabel = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.background
        snp.makeConstraints { $0.height.equalTo(56) }

        titleLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "tabbar.shuttle"), font: SettingsStyle.font(32, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 40
        ).withKern(-0.5)
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityIdentifier = "shuttle.title"
        titleLabel.adjustsFontForContentSizeCategory = true
        addSubview(titleLabel)

        configureSettingsButton()
        settingsButton.accessibilityLabel = String(localized: "shuttle.quick_settings.title")
        settingsButton.accessibilityIdentifier = "shuttle.quick_settings"
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        addSubview(settingsButton)

        settingsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(6)
            $0.height.equalTo(44)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualTo(settingsButton.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSettingsButton() {
        let capsule = UIView()
        capsule.backgroundColor = SettingsStyle.Color.accentFill
        capsule.layer.cornerRadius = 18
        capsule.isUserInteractionEnabled = false
        settingsButton.addSubview(capsule)
        capsule.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.equalTo(36)
            $0.leading.trailing.equalToSuperview()
        }
        let icon = UIImageView(image: UIImage(
            systemName: "slider.horizontal.3",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        ))
        icon.tintColor = SettingsStyle.Color.link
        let label = UILabel()
        label.text = String(localized: "shuttle.quick_settings.title")
        label.font = SettingsStyle.font(14, bold: true)
        label.textColor = SettingsStyle.Color.link
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        capsule.addSubview(stack)
        stack.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        icon.snp.makeConstraints { $0.size.equalTo(18) }
    }

    @objc
    private func settingsTapped() {
        onSettingsTap?()
    }

}
