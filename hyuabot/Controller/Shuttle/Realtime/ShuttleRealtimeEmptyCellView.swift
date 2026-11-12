//
//  ShuttleRealtimeEmptyCellView.swift
//  hyuabot
//

import UIKit

class ShuttleRealtimeEmptyCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeEmptyCellView"
    private let cardView = UIView()
    private let stateView = StateView(sourceScreen: .shuttleRealtime)

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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        cardView.backgroundColor = SettingsStyle.Color.card
        cardView.layer.cornerRadius = SettingsStyle.Metric.cardRadius
        cardView.layer.masksToBounds = true
        contentView.addSubview(cardView)
        // Keep StateView directly under contentView so its unavailable content can
        // measure the cell correctly for self-sizing table rows.
        contentView.addSubview(stateView)
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }
        stateView.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.top).offset(20)
            make.leading.equalTo(cardView.snp.leading).offset(24)
            make.bottom.equalTo(cardView.snp.bottom).inset(22)
            make.trailing.equalTo(cardView.snp.trailing).inset(24)
        }
        stateView.apply(.empty(message: String(localized: "shuttle.realtime.empty")))
    }
}
