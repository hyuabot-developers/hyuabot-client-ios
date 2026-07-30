//
//  InquiryMessageCellView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class InquiryMessageCellView: UITableViewCell {
    static let reuseIdentifier = "InquiryMessageCellView"

    private let bubbleView = UIView().then {
        $0.layer.cornerRadius = 16
        $0.layer.cornerCurve = .continuous
    }

    private let messageLabel = UILabel().then {
        $0.font = .godo(size: 15, weight: .regular)
        $0.numberOfLines = 0
    }

    private let readLabel = UILabel().then {
        $0.font = .godo(size: 11, weight: .regular)
        $0.textColor = .tertiaryLabel
        $0.text = String(localized: "inquiry.read")
        $0.isHidden = true
    }

    private let timeLabel = UILabel().then {
        $0.font = .godo(size: 11, weight: .regular)
        $0.textColor = .tertiaryLabel
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(bubbleView)
        contentView.addSubview(readLabel)
        contentView.addSubview(timeLabel)
        bubbleView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with message: InquiryMessageDTO) {
        messageLabel.text = message.body
        timeLabel.text = Self.timeFormatter.string(from: Self.date(from: message.createdAt) ?? .now)
        switch message.senderType {
        case "USER":
            configureUser()
        case "ADMIN":
            configureAdmin(readAt: message.readAt)
        default:
            configureSystem()
        }
    }

    private func configureUser() {
        readLabel.isHidden = true
        timeLabel.isHidden = false
        bubbleView.backgroundColor = .systemBlue
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMinXMaxYCorner,
        ]
        messageLabel.textColor = .white
        messageLabel.textAlignment = .left
        bubbleView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(64)
        }
        timeLabel.snp.remakeConstraints { make in
            make.top.equalTo(bubbleView.snp.bottom).offset(2)
            make.trailing.equalTo(bubbleView)
            make.bottom.equalToSuperview().inset(6)
        }
    }

    private func configureAdmin(readAt: String?) {
        bubbleView.backgroundColor = .secondarySystemGroupedBackground
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner,
        ]
        messageLabel.textColor = .label
        messageLabel.textAlignment = .left
        readLabel.isHidden = readAt == nil
        timeLabel.isHidden = false
        bubbleView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(64)
        }
        timeLabel.snp.remakeConstraints { make in
            make.top.equalTo(bubbleView.snp.bottom).offset(2)
            make.leading.equalTo(bubbleView)
            make.bottom.equalToSuperview().inset(6)
        }
        if readAt != nil {
            readLabel.snp.remakeConstraints { make in
                make.leading.equalTo(timeLabel.snp.trailing).offset(6)
                make.centerY.equalTo(timeLabel)
            }
        }
    }

    private func configureSystem() {
        readLabel.isHidden = true
        timeLabel.isHidden = true
        timeLabel.snp.remakeConstraints { make in
            make.size.equalTo(0)
            make.top.leading.equalToSuperview()
        }
        bubbleView.backgroundColor = .clear
        bubbleView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner,
        ]
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        bubbleView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    private static func date(from raw: String) -> Date? {
        ISO8601DateFormatter().date(from: String(raw.split(separator: "[", maxSplits: 1).first ?? ""))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
