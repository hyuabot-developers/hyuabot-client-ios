//
//  ShuttleRealtimeEmptyCellView.swift
//  hyuabot
//

import UIKit

class ShuttleRealtimeEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeEmptyCellView"
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    func configure(title: String, body: String) {
        titleLabel.text = title
        bodyLabel.text = body
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        cardView.backgroundColor = SettingsStyle.Color.card
        // Middle segment between the rounded section header and footer; corners would notch the card.
        cardView.layer.cornerRadius = 0
        cardView.layer.masksToBounds = true
        contentView.addSubview(cardView)
        titleLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .boldSystemFont(ofSize: 15))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        bodyLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13))
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.textColor = .secondaryLabel
        for label in [titleLabel, bodyLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 4
        cardView.addSubview(stack)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }
        stack.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.top).offset(20)
            make.leading.equalTo(cardView.snp.leading).offset(24)
            make.bottom.equalTo(cardView.snp.bottom).inset(22)
            make.trailing.equalTo(cardView.snp.trailing).inset(24)
        }
        configure(
            title: String(localized: "shuttle.realtime.empty.not_operating.title"),
            body: String(localized: "shuttle.realtime.empty.not_operating.body")
        )
    }
}
