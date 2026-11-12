//
//  HYUSheetView.swift
//  hyuabot
//

import SnapKit
import UIKit

@MainActor
final class HYUSheetView: UIView {
    let contentStack = UIStackView()
    let scrollView = UIScrollView()
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    let closeButton = UIButton(type: .system)

    init(title: String, titleIdentifier: String? = nil) {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.busSheetBackground
        buildLayout()
        setTitle(title)
        titleLabel.accessibilityIdentifier = titleIdentifier
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        titleLabel.font = SettingsStyle.font(20, bold: true)
        titleLabel.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 26
        )
    }

    /// Shows the design's circular X button at the trailing edge of the header.
    func showsCloseButton(_ shows: Bool, identifier: String? = nil) {
        closeButton.isHidden = !shows
        closeButton.accessibilityIdentifier = identifier
    }

    var contentHeight: CGFloat {
        layoutIfNeeded()
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        return 52 + 6 + contentStack.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func buildLayout() {
        let header = headerContainer
        header.addSubview(titleLabel)
        var closeConfig = UIButton.Configuration.plain()
        closeConfig.image = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        )
        closeConfig.baseForegroundColor = SettingsStyle.Color.secondaryText
        closeConfig.background.backgroundColor = SettingsStyle.Color.inset
        closeConfig.background.cornerRadius = 15
        closeButton.configuration = closeConfig
        closeButton.isHidden = true
        closeButton.accessibilityLabel = String(localized: "close")
        header.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(30)
        }
        addSubview(header)
        addSubview(scrollView)

        titleLabel.accessibilityTraits = .header
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        header.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(6)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }

        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 34, trailing: 16)
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
    }

    static func sectionHeader(_ title: String, isFirst: Bool = false) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(13, bold: true),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        label.accessibilityTraits = .header
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(isFirst ? 4 : 20)
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(8)
        }
        return container
    }

    static func card() -> UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 0
        view.backgroundColor = SettingsStyle.Color.sheet
        view.layer.cornerRadius = 16
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }

    static func separator(inset: CGFloat = 16) -> UIView {
        let container = UIView()
        let line = UIView()
        line.backgroundColor = SettingsStyle.Color.separator
        container.addSubview(line)
        container.snp.makeConstraints { $0.height.equalTo(1 / UIScreen.main.scale) }
        line.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(inset)
            make.trailing.equalToSuperview()
        }
        return container
    }

    static func actionButton(title: String, systemImage: String?, identifier: String?) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.background.backgroundColor = SettingsStyle.Color.accentFill
        configuration.background.cornerRadius = 12
        configuration.baseForegroundColor = SettingsStyle.Color.link
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: SettingsStyle.font(15, bold: true)]))
        if let systemImage {
            configuration.image = UIImage(
                systemName: systemImage,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            )
            configuration.imagePadding = 6
        }
        button.configuration = configuration
        button.accessibilityIdentifier = identifier
        button.snp.makeConstraints { $0.height.equalTo(48) }
        return button
    }

    static func primaryButton(title: String, identifier: String?) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.background.backgroundColor = SettingsStyle.Color.accent
        configuration.background.cornerRadius = 12
        configuration.baseForegroundColor = SettingsStyle.Color.onAccent
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([.font: SettingsStyle.font(16, bold: true)]))
        button.configuration = configuration
        button.accessibilityIdentifier = identifier
        button.snp.makeConstraints { $0.height.equalTo(50) }
        return button
    }

    static func footnote(_ text: String) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = SettingsStyle.attributedText(
            text,
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16
        )
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview()
        }
        return container
    }
}
