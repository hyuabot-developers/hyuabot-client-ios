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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(bubbleView)
        contentView.addSubview(readLabel)
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
        bubbleView.backgroundColor = .systemBlue
        messageLabel.textColor = .white
        messageLabel.textAlignment = .left
        bubbleView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.trailing.equalToSuperview().inset(16)
            make.leading.greaterThanOrEqualToSuperview().inset(64)
        }
    }

    private func configureAdmin(readAt: String?) {
        bubbleView.backgroundColor = .secondarySystemGroupedBackground
        messageLabel.textColor = .label
        messageLabel.textAlignment = .left
        readLabel.isHidden = readAt == nil
        bubbleView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualToSuperview().inset(64)
            if readAt == nil {
                make.bottom.equalToSuperview().inset(6)
            }
        }
        if readAt != nil {
            readLabel.snp.remakeConstraints { make in
                make.top.equalTo(bubbleView.snp.bottom).offset(2)
                make.leading.equalTo(bubbleView.snp.leading).offset(4)
                make.bottom.equalToSuperview().inset(6)
            }
        }
    }

    private func configureSystem() {
        readLabel.isHidden = true
        bubbleView.backgroundColor = .clear
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        bubbleView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }
}
