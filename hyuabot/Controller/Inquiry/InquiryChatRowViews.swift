//
//  InquiryChatRowViews.swift
//  hyuabot
//

import SnapKit
import UIKit

enum InquiryChatRowViews {
    static func make(for row: InquiryChatRow) -> UIView {
        switch row.kind {
        case let .date(title): makeDate(title)
        case let .system(body): makeSystem(body)
        case let .user(body, time, isRead): makeUser(body, time: time, isRead: isRead)
        case let .admin(body, time, showsSenderLabel): makeAdmin(body, time: time, showsSenderLabel: showsSenderLabel)
        }
    }

    private static func makeDate(_ title: String) -> UIView {
        let container = UIView()
        let pill = UIView()
        pill.backgroundColor = SettingsStyle.Color.segmentBackground
        pill.layer.cornerRadius = 12
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            title, font: SettingsStyle.font(12), color: SettingsStyle.Color.secondaryText, lineHeight: 16
        )
        pill.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)) }
        container.addSubview(pill)
        pill.snp.makeConstraints { $0.center.equalToSuperview() }
        container.accessibilityIdentifier = "inquiry.message.date"
        return container
    }

    private static func makeSystem(_ body: String) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = SettingsStyle.attributedText(
            body, font: SettingsStyle.font(12.5), color: SettingsStyle.Color.secondaryText, lineHeight: 18
        )
        container.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.lessThanOrEqualTo(300) }
        container.accessibilityIdentifier = "inquiry.message.system"
        return container
    }

    private static func makeUser(_ body: String, time: String, isRead: Bool) -> UIView {
        let bubble = InquiryTextBubbleView(
            side: .trailing, fillColor: SettingsStyle.Color.accent,
            textColor: SettingsStyle.Color.onAccent, maxWidth: 270
        )
        bubble.setText(body)
        bubble.accessibilityIdentifier = "inquiry.message.user"
        let meta = UIStackView()
        meta.axis = .horizontal
        meta.spacing = 6
        if isRead {
            let read = UILabel()
            read.attributedText = SettingsStyle.attributedText(
                String(localized: "inquiry.read"), font: SettingsStyle.font(11),
                color: SettingsStyle.Color.accent, lineHeight: 14
            )
            meta.addArrangedSubview(read)
        }
        let timeLabel = timeLabel(time)
        meta.addArrangedSubview(timeLabel)
        let metaContainer = UIView()
        metaContainer.addSubview(meta)
        meta.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.trailing.equalToSuperview().inset(4)
            $0.leading.greaterThanOrEqualToSuperview()
        }
        return InquiryUI.column(side: .trailing, views: [bubble, metaContainer])
    }

    private static func makeAdmin(_ body: String, time: String, showsSenderLabel: Bool) -> UIView {
        let bubble = InquiryTextBubbleView(
            side: .leading, fillColor: SettingsStyle.Color.card,
            textColor: SettingsStyle.Color.text, maxWidth: 310
        )
        bubble.setText(body)
        bubble.accessibilityIdentifier = "inquiry.message.admin"
        let timeContainer = UIView()
        let label = timeLabel(time)
        timeContainer.addSubview(label)
        label.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(4)
            $0.trailing.lessThanOrEqualToSuperview()
        }
        var views: [UIView] = []
        if showsSenderLabel { views.append(InquiryUI.captionRow(String(localized: "inquiry.admin"), side: .leading)) }
        views.append(contentsOf: [bubble, timeContainer])
        return InquiryUI.column(side: .leading, views: views)
    }

    private static func timeLabel(_ time: String) -> UILabel {
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            time, font: SettingsStyle.font(11), color: SettingsStyle.Color.secondaryText, lineHeight: 14
        )
        return label
    }
}
