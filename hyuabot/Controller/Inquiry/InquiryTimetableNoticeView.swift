//
//  InquiryTimetableNoticeView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class InquiryTimetableNoticeView: UIView {
    var onOpenTimetable: (() -> Void)?

    init() {
        super.init(frame: .zero)
        let card = InquiryAnswerCardView(
            title: String(localized: "inquiry.timetable.title"),
            detail: String(localized: "inquiry.timetable.detail")
        )
        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        card.addContent(makeCallout())
        card.addContent(InquiryUI.infoGrid([
            InquiryInfoRow(String(localized: "inquiry.phoneLabel"), "031-400-4406")
        ]))
        let timetableButton = InquiryUI.actionButton(
            title: String(localized: "inquiry.timetable.open"),
            systemImage: "calendar",
            filled: false
        )
        timetableButton.accessibilityIdentifier = "inquiry.timetable.open"
        timetableButton.addTarget(self, action: #selector(openTimetable), for: .touchUpInside)
        let callButton = InquiryUI.actionButton(
            title: String(localized: "inquiry.timetable.call"),
            systemImage: "phone",
            filled: true
        )
        callButton.accessibilityIdentifier = "inquiry.timetable.call"
        callButton.addTarget(self, action: #selector(callOffice), for: .touchUpInside)
        card.addContent(InquiryUI.actionRow([timetableButton, callButton]))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func makeCallout() -> UIView {
        let container = UIView()
        container.backgroundColor = SettingsStyle.Color.inquiryCallout
        container.accessibilityIdentifier = "inquiry.timetable.callout"
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous
        let configuration = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold, scale: .medium)
        let icon = UIImageView(image: UIImage(systemName: "exclamationmark.circle"))
        icon.preferredSymbolConfiguration = configuration
        icon.accessibilityIdentifier = "inquiry.timetable.callout.icon"
        icon.tintColor = SettingsStyle.Color.inquiryCalloutIcon
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityIdentifier = "inquiry.timetable.callout.label"
        let emphasis = String(localized: "inquiry.timetable.callout.emphasis")
        let full = String(localized: "inquiry.timetable.callout.\(emphasis)")
        let baseText = SettingsStyle.attributedText(
            full, font: SettingsStyle.font(14), color: SettingsStyle.Color.text, lineHeight: 21
        )
        let attributed = NSMutableAttributedString(attributedString: baseText)
        let range = (full as NSString).range(of: emphasis)
        if range.location != NSNotFound {
            attributed.addAttribute(.font, value: SettingsStyle.font(14, bold: true), range: range)
        }
        label.attributedText = attributed
        let iconContainer = UIView()
        iconContainer.addSubview(icon)
        let row = UIStackView(arrangedSubviews: [iconContainer, label])
        row.axis = .horizontal
        row.spacing = 4
        row.alignment = .top
        container.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        iconContainer.snp.makeConstraints { $0.height.equalTo(21); $0.width.equalTo(18) }
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        return container
    }

    @objc
    private func openTimetable() { onOpenTimetable?() }

    @objc
    private func callOffice() {
        guard let url = URL(string: "tel:0314004406") else { return }
        UIApplication.shared.open(url)
    }
}
