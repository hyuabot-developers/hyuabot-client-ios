//
//  ShuttleHelpItemCell.swift
//  hyuabot
//

import RxSwift
import SnapKit
import UIKit

class ShuttleHelpItemCell: UITableViewCell {
    static let reuseIdentifier = "ShuttleHelpItemCell"
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()

    private lazy var cellStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.contentLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardView.backgroundColor = SettingsStyle.Color.sheet
        cardView.layer.cornerRadius = 16
        cardView.layer.cornerCurve = .continuous
        cardView.clipsToBounds = true
        titleLabel.numberOfLines = 0
        contentLabel.numberOfLines = 0
        contentView.addSubview(cardView)
        cardView.addSubview(cellStackView)
        cardView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
        }
        cellStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16))
        }
    }

    func setupUI(title: String.LocalizationValue, content: String.LocalizationValue) {
        titleLabel.attributedText = SettingsStyle.attributedText(
            String(localized: title),
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20
        )
        contentLabel.attributedText = SettingsStyle.attributedText(
            String(localized: content),
            font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
    }
}
