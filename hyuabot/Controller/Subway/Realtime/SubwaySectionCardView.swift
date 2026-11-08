//
//  SubwaySectionCardView.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwaySectionCardView: UIView {
    var onTimetableTap: ((SubwayTimetableTarget) -> Void)?
    private let badgeView = SubwayLineBadgeView(size: .regular)
    private let titleLabel = UILabel()
    private let header = UIView()
    private let separator = UIView()
    private let bodyStack = UIStackView()
    private var timetableTarget: SubwayTimetableTarget?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = SettingsStyle.Metric.cardRadius
        clipsToBounds = true
        titleLabel.font = SettingsStyle.font(15, bold: true)
        titleLabel.textColor = SettingsStyle.Color.text
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.accessibilityTraits = .header
        separator.backgroundColor = SettingsStyle.Color.separator
        bodyStack.axis = .vertical
        bodyStack.spacing = 0
        [header, separator, bodyStack].forEach(addSubview)
        header.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(48) }
        separator.snp.makeConstraints { $0.top.equalTo(header.snp.bottom); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        bodyStack.snp.makeConstraints { $0.top.equalTo(separator.snp.bottom); $0.leading.trailing.bottom.equalToSuperview() }
        header.addSubview(badgeView)
        header.addSubview(titleLabel)
        badgeView.snp.makeConstraints { $0.leading.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        titleLabel.snp
            .makeConstraints {
                $0.leading.equalTo(badgeView.snp.trailing).offset(10); $0.centerY.equalToSuperview(); $0.trailing
                    .lessThanOrEqualToSuperview()
                    .inset(16)
            }
    }

    func configure(_ content: SubwaySectionContent) {
        badgeView.configure(content.badge)
        titleLabel.text = content.title
        titleLabel.attributedText = SettingsStyle.attributedText(
            content.title,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20,
            lineBreakMode: .byTruncatingTail
        )
        timetableTarget = content.timetable
        header.subviews.filter { $0 is UIButton }.forEach { $0.removeFromSuperview() }
        if let target = content.timetable {
            let button = timetableButton(target)
            header.addSubview(button)
            button.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(8)
                make.centerY.equalToSuperview()
                make.height.equalTo(44)
            }
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(badgeView.snp.trailing).offset(10)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(button.snp.leading).offset(-10)
            }
        } else {
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(badgeView.snp.trailing).offset(10)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualToSuperview().inset(16)
            }
        }
        for view in bodyStack.arrangedSubviews {
            bodyStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if content.isEmpty {
            bodyStack.addArrangedSubview(emptyView(message: content.emptyMessage))
            return
        }
        switch content.rows {
        case let .arrivals(rows):
            for (index, model) in rows.enumerated() {
                let row = SubwayArrivalRowView()
                row.configure(model, showsSeparator: index > 0)
                bodyStack.addArrangedSubview(row)
            }
        case let .transfers(rows):
            for (index, model) in rows.enumerated() {
                let row = SubwayTransferRouteView()
                row.configure(model, showsSeparator: index > 0)
                bodyStack.addArrangedSubview(row)
            }
        }
    }

    private func timetableButton(_ target: SubwayTimetableTarget) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
        config.title = String(localized: "subway.realtime.timetable")
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var attributes = incoming
            attributes.font = SettingsStyle.font(13, bold: true)
            return attributes
        }
        config.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))
        config.imagePlacement = .trailing
        config.imagePadding = 2
        config.baseForegroundColor = SettingsStyle.Color.link
        let button = UIButton(configuration: config)
        button.accessibilityLabel = target.accessibilityLabel
        button.addTarget(self, action: #selector(timetableTapped), for: .touchUpInside)
        return button
    }

    @objc
    private func timetableTapped() {
        guard let timetableTarget else { return }
        onTimetableTap?(timetableTarget)
    }

    private func emptyView(message: String) -> UIView {
        let container = UIView()
        let icon = UIImageView(image: UIImage(
            systemName: "moon.stars",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        ))
        icon.tintColor = SettingsStyle.Color.commuterFaint
        icon.contentMode = .center
        icon.backgroundColor = SettingsStyle.Color.segmentBackground
        icon.layer.cornerRadius = 22
        let title = UILabel()
        let emptyTitle = String(localized: "subway.realtime.empty.title")
        title.text = emptyTitle
        title.font = SettingsStyle.font(15, bold: true)
        title.textColor = SettingsStyle.Color.text
        title.textAlignment = .center
        title.attributedText = SettingsStyle.attributedText(
            emptyTitle,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20,
            alignment: .center
        )
        title.numberOfLines = 0
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        let detail = UILabel()
        detail.text = message
        detail.font = SettingsStyle.font(13)
        detail.textColor = SettingsStyle.Color.secondaryText
        detail.textAlignment = .center
        detail.attributedText = SettingsStyle.attributedText(
            message,
            font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18,
            alignment: .center
        )
        detail.numberOfLines = 0
        detail.setContentCompressionResistancePriority(.required, for: .vertical)
        let stack = UIStackView(arrangedSubviews: [icon, title, detail])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        stack.setCustomSpacing(12, after: icon)
        stack.setCustomSpacing(4, after: title)
        container.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 24, bottom: 28, right: 24)) }
        icon.snp.makeConstraints { $0.size.equalTo(44) }
        title.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        detail.snp.makeConstraints { $0.leading.trailing.equalToSuperview() }
        return container
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
