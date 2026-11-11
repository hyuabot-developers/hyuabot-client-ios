//
//  InquiryHomeViews.swift
//  hyuabot
//

import SnapKit
import UIKit

final class InquiryWelcomeView: UIView {
    init() {
        super.init(frame: .zero)
        let bubble = InquiryTextBubbleView(
            side: .leading,
            fillColor: SettingsStyle.Color.card,
            textColor: SettingsStyle.Color.text,
            maxWidth: 310
        )
        bubble.setText(String(localized: "inquiry.welcome"))
        let column = InquiryUI.column(
            side: .leading,
            views: [InquiryUI.captionRow(String(localized: "inquiry.bot.name"), side: .leading), bubble]
        )
        addSubview(column)
        column.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class InquiryQuickReplyListView: UIView {
    var onSelect: ((InquiryQuickReply) -> Void)? {
        didSet { rows.forEach { $0.onSelect = onSelect } }
    }

    private var rows: [InquiryQuickReplyRow] = []

    init() {
        super.init(frame: .zero)
        let header = UILabel()
        header.font = SettingsStyle.font(13)
        header.textColor = SettingsStyle.Color.secondaryText
        header.text = String(localized: "inquiry.quick.header")
        let headerContainer = UIView()
        headerContainer.addSubview(header)
        header.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)) }

        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = HYUMetrics.Radius.card
        card.layer.cornerCurve = .continuous
        card.clipsToBounds = true
        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.spacing = 0
        for reply in InquiryQuickReply.allCases {
            let row = InquiryQuickReplyRow(reply: reply)
            row.onSelect = { [weak self] selected in self?.onSelect?(selected) }
            rows.append(row)
            rowStack.addArrangedSubview(row)
        }
        card.addSubview(rowStack)
        rowStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView(arrangedSubviews: [headerContainer, card])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private final class InquiryQuickReplyRow: UIControl {
    let reply: InquiryQuickReply
    var onSelect: ((InquiryQuickReply) -> Void)?

    init(reply: InquiryQuickReply) {
        self.reply = reply
        super.init(frame: .zero)
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = reply.question
        accessibilityIdentifier = "inquiry.quick.\(reply.rawValue)"
        addTarget(self, action: #selector(didTap), for: .touchUpInside)

        let iconTile = UIView()
        iconTile.backgroundColor = SettingsStyle.Color.accentFill
        iconTile.layer.cornerRadius = 10
        let iconImage = UIImage(systemName: reply.iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
        let icon = UIImageView(image: iconImage)
        icon.tintColor = SettingsStyle.Color.accent
        icon.contentMode = .center
        iconTile.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }

        let question = UILabel()
        question.attributedText = SettingsStyle.attributedText(
            reply.question,
            font: SettingsStyle.font(15),
            color: SettingsStyle.Color.text,
            lineHeight: 20
        )
        question.numberOfLines = 0
        let detail = UILabel()
        detail.attributedText = SettingsStyle.attributedText(
            reply.detail,
            font: SettingsStyle.font(12.5),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        detail.numberOfLines = 0
        let labels = UIStackView(arrangedSubviews: [question, detail])
        labels.axis = .vertical
        labels.spacing = 2
        let chevronImage = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        let chevron = UIImageView(image: chevronImage)
        chevron.tintColor = SettingsStyle.Color.secondaryText
        chevron.contentMode = .scaleAspectFit
        let content = UIStackView(arrangedSubviews: [iconTile, labels, chevron])
        content.axis = .horizontal
        content.spacing = 12
        content.alignment = .center
        content.isUserInteractionEnabled = false
        addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)) }
        iconTile.snp.makeConstraints { $0.width.height.equalTo(36) }
        chevron.snp.makeConstraints { $0.width.height.equalTo(16) }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(64) }

        if reply != InquiryQuickReply.allCases.first {
            let separator = UIView()
            separator.backgroundColor = SettingsStyle.Color.separator
            addSubview(separator)
            separator.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        }
        observeTraits()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet { refreshHighlight() }
    }

    private func refreshHighlight() {
        backgroundColor = isHighlighted ? SettingsStyle.Color.segmentBackground : .clear
    }

    private func observeTraits() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: InquiryQuickReplyRow, _: UITraitCollection) in
            view.refreshHighlight()
        }
    }

    @objc
    private func didTap() { onSelect?(reply) }
}

final class InquiryErrorCardView: UIView {
    var onRetry: (() -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = HYUMetrics.Radius.card
        layer.cornerCurve = .continuous
        let iconImage = UIImage(
            systemName: "arrow.triangle.2.circlepath",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        )
        let icon = UIImageView(image: iconImage)
        icon.tintColor = SettingsStyle.Color.secondaryText
        let title = UILabel()
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "inquiry.loadFailed"),
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20
        )
        title.textAlignment = .center
        title.numberOfLines = 0
        let detail = UILabel()
        detail.attributedText = SettingsStyle.attributedText(
            String(localized: "inquiry.error.detail"),
            font: SettingsStyle.font(13.5),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 20
        )
        detail.textAlignment = .center
        detail.numberOfLines = 0
        let textStack = UIStackView(arrangedSubviews: [title, detail])
        textStack.axis = .vertical
        textStack.spacing = 4
        let retry = UIButton(configuration: .plain())
        var config = retry.configuration ?? .plain()
        config.title = String(localized: "inquiry.retry")
        var attributes = AttributeContainer()
        attributes.font = SettingsStyle.font(15, bold: true)
        config.attributedTitle = AttributedString(String(localized: "inquiry.retry"), attributes: attributes)
        config.baseForegroundColor = SettingsStyle.Color.accent
        config.background.backgroundColor = SettingsStyle.Color.accentFill
        config.background.cornerRadius = 12
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        retry.configuration = config
        retry.accessibilityIdentifier = "inquiry.retry"
        retry.addAction(UIAction { [weak self] _ in self?.onRetry?() }, for: .touchUpInside)
        retry.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        let stack = UIStackView(arrangedSubviews: [icon, textStack, retry])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
