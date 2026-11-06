//
//  MapBuildingCardView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class MapBuildingCardView: UIView {
    struct Content: Equatable {
        let title: String
        let caption: String
        let translatesCaption: Bool
        let hasGuide: Bool
        let showsShowAll: Bool
    }

    let primaryButton: UIButton
    let showAllButton: UIButton
    let deselectButton: UIButton
    var onDeselect: (() -> Void)?
    var onShowAll: (() -> Void)?
    var onOpenGuide: (() -> Void)?

    private let titleLabel = UILabel()
    private let captionLabel = UILabel()

    override init(frame: CGRect) {
        var primary = Self.buttonConfiguration(title: String(localized: "map.building.open_guide"))
        primary.baseBackgroundColor = SettingsStyle.Color.accent
        primary.baseForegroundColor = SettingsStyle.Color.onAccent
        primaryButton = UIButton(configuration: primary)

        var showAll = Self.buttonConfiguration(title: String(localized: "map.building.show_all"))
        showAll.baseBackgroundColor = SettingsStyle.Color.segmentBackground
        showAll.baseForegroundColor = SettingsStyle.Color.text
        showAllButton = UIButton(configuration: showAll)

        var deselectConfig = UIButton.Configuration.plain()
        deselectConfig.contentInsets = .zero
        deselectButton = UIButton(configuration: deselectConfig)
        super.init(frame: frame)
        configure()
        updateLayerColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.updateLayerColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func apply(_ content: Content) {
        titleLabel.setKoreanTranslatedText(content.title)
        if content.translatesCaption {
            captionLabel.setKoreanTranslatedText(content.caption)
        } else {
            captionLabel.text = content.caption
        }
        accessibilityLabel = content.title
        showAllButton.isHidden = !content.showsShowAll
        var config = Self.buttonConfiguration(
            title: String(localized: content.hasGuide ? "map.building.open_guide" : "map.building.no_guide")
        )
        config.baseBackgroundColor = content.hasGuide ? SettingsStyle.Color.accent : SettingsStyle.Color.segmentBackground
        config.baseForegroundColor = content.hasGuide ? SettingsStyle.Color.onAccent : SettingsStyle.Color.secondaryText
        primaryButton.configuration = config
        primaryButton.isEnabled = content.hasGuide
    }

    private func configure() {
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowOpacity = 0.10
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: -4)

        configureGrabber()
        configureHeaderLabels()
        let header = makeHeader()
        let actions = makeActions()
        configureContent(header: header, actions: actions)
        configureButtonActions()
    }

    private func configureGrabber() {
        let grabber = UIView()
        grabber.backgroundColor = SettingsStyle.Color.grabber
        grabber.layer.cornerRadius = 2.5
        grabber.layer.cornerCurve = .continuous
        addSubview(grabber)
        grabber.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 36, height: 5))
        }
    }

    private func configureHeaderLabels() {
        titleLabel.font = SettingsStyle.font(17, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontForContentSizeCategory = true
        captionLabel.font = SettingsStyle.font(13)
        captionLabel.textColor = SettingsStyle.Color.secondaryText
        captionLabel.numberOfLines = 1
        captionLabel.lineBreakMode = .byTruncatingTail
        captionLabel.adjustsFontForContentSizeCategory = true
    }

    private func makeHeader() -> UIStackView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = SettingsStyle.Color.accentFill
        iconContainer.layer.cornerRadius = 20
        iconContainer.layer.cornerCurve = .continuous
        let symbol = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: "building.2", withConfiguration: symbol))
        icon.tintColor = SettingsStyle.Color.link
        iconContainer.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        let textStack = UIStackView(arrangedSubviews: [titleLabel, captionLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        let header = UIStackView(arrangedSubviews: [iconContainer, textStack, deselectButton])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        iconContainer.snp.makeConstraints { $0.size.equalTo(40) }
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        configureDeselectButton()
        return header
    }

    private func makeActions() -> UIStackView {
        let actions = UIStackView(arrangedSubviews: [showAllButton, primaryButton])
        actions.axis = .horizontal
        actions.distribution = .fillEqually
        actions.spacing = 8
        for button in [showAllButton, primaryButton] {
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(48) }
        }
        return actions
    }

    private func configureContent(header: UIStackView, actions: UIStackView) {
        let content = UIStackView(arrangedSubviews: [header, actions])
        content.axis = .vertical
        content.spacing = 16
        addSubview(content)
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).inset(16)
        }
        header.snp.makeConstraints { $0.trailing.equalToSuperview().offset(12) }
    }

    private func configureButtonActions() {
        showAllButton.addTarget(self, action: #selector(showAllTapped), for: .touchUpInside)
        primaryButton.addTarget(self, action: #selector(openGuideTapped), for: .touchUpInside)
        deselectButton.addTarget(self, action: #selector(deselectTapped), for: .touchUpInside)
        primaryButton.configurationUpdateHandler = { button in
            guard !button.isEnabled else { return }
            button.configuration?.baseBackgroundColor = SettingsStyle.Color.segmentBackground
            button.configuration?.baseForegroundColor = SettingsStyle.Color.secondaryText
        }
    }

    private func configureDeselectButton() {
        let circle = UIView()
        circle.backgroundColor = SettingsStyle.Color.segmentBackground
        circle.layer.cornerRadius = 15
        circle.layer.cornerCurve = .continuous
        circle.isUserInteractionEnabled = false
        let symbol = UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        let icon = UIImageView(image: UIImage(systemName: "xmark", withConfiguration: symbol))
        icon.tintColor = SettingsStyle.Color.secondaryText
        circle.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        deselectButton.addSubview(circle)
        circle.snp.makeConstraints { make in make.center.equalToSuperview(); make.size.equalTo(30) }
        deselectButton.accessibilityLabel = String(localized: "map.building.deselect")
        deselectButton.snp.makeConstraints { $0.size.equalTo(44) }
    }

    private func updateLayerColors() {
        layer.shadowColor = UIColor.black.resolvedColor(with: traitCollection).cgColor
    }

    private static func buttonConfiguration(title: String) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.background.cornerRadius = 12
        configuration.cornerStyle = .fixed
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: SettingsStyle.font(15, bold: true)]))
        return configuration
    }

    @objc
    private func deselectTapped() {
        onDeselect?()
    }

    @objc
    private func showAllTapped() {
        onShowAll?()
    }

    @objc
    private func openGuideTapped() {
        onOpenGuide?()
    }
}
