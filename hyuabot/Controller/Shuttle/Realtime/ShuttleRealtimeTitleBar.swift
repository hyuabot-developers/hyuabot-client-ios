//
//  ShuttleRealtimeTitleBar.swift
//  hyuabot
//

import SnapKit
import UIKit

@MainActor
final class ShuttleRealtimeTitleBar: UIView {
    let settingsButton = UIButton(type: .custom)
    let homeButton = UIButton(type: .custom)
    var onSettingsTap: (() -> Void)?
    var onHomeTap: (() -> Void)?

    private let titleLabel = UILabel()

    init(showsHomeButton: Bool) {
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

        configureHomeButton()
        homeButton.isHidden = !showsHomeButton
        homeButton.accessibilityLabel = String(localized: "home.return")
        homeButton.accessibilityIdentifier = "shuttle.return_home"
        homeButton.addTarget(self, action: #selector(homeTapped), for: .touchUpInside)
        addSubview(homeButton)

        settingsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview().inset(6)
            $0.height.equalTo(44)
        }
        homeButton.snp.makeConstraints {
            $0.trailing.equalTo(settingsButton.snp.leading).offset(-8)
            $0.centerY.equalTo(settingsButton)
            $0.size.equalTo(44)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualTo(homeButton.snp.leading).offset(-8)
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

    private func configureHomeButton() {
        let circle = UIView()
        circle.backgroundColor = SettingsStyle.Color.segmentBackground
        circle.layer.cornerRadius = 18
        circle.isUserInteractionEnabled = false
        homeButton.addSubview(circle)
        circle.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(36)
        }
        let icon = UIImageView(image: UIImage(
            systemName: "house.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        ))
        icon.tintColor = SettingsStyle.Color.link
        circle.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    @objc
    private func settingsTapped() {
        onSettingsTap?()
    }

    @objc
    private func homeTapped() {
        onHomeTap?()
    }
}
