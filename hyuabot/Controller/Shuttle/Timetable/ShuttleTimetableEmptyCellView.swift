//
//  ShuttleTimetableEmptyCellView.swift
//  hyuabot
//

import UIKit

class ShuttleTimetableEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleTimetableEmptyCellView"
    private let cardView = UIView()
    private let stateView = StateView(sourceScreen: .shuttleTimetable)

    func configure(_ content: StateContent) {
        stateView.apply(content)
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
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.layer.cornerRadius = SettingsStyle.Metric.cardRadius
        cardView.layer.masksToBounds = true
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }

        contentView.addSubview(stateView)
        stateView.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.top).offset(32)
            make.leading.equalTo(cardView.snp.leading).offset(24)
            make.bottom.equalTo(cardView.snp.bottom).inset(28)
            make.trailing.equalTo(cardView.snp.trailing).inset(24)
        }
        stateView.apply(.empty(message: String(localized: "shuttle.timetable.empty")))
    }
}
