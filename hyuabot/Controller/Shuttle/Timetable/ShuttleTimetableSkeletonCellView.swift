//
//  ShuttleTimetableSkeletonCellView.swift
//  hyuabot
//

import UIKit

final class ShuttleTimetableSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleTimetableSkeletonCellView"

    private let cardView = UIView()
    private let typePlaceholder = UIView()
    private let timePlaceholder = UIView()
    private let trailingPlaceholder = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startAnimating()
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
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            make.height.equalTo(44)
        }

        for view in [typePlaceholder, timePlaceholder, trailingPlaceholder] {
            view.backgroundColor = SettingsStyle.Color.segmentBackground
            view.layer.cornerRadius = 7
            view.layer.masksToBounds = true
            cardView.addSubview(view)
        }
        timePlaceholder.layer.cornerRadius = 6

        typePlaceholder.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(14)
        }
        timePlaceholder.snp.makeConstraints { make in
            make.leading.equalTo(typePlaceholder.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(20)
        }
        trailingPlaceholder.snp.makeConstraints { make in
            make.leading.equalTo(timePlaceholder.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(cardView.snp.width).multipliedBy(0.4)
            make.height.equalTo(14)
        }

        startAnimating()
    }

    private func startAnimating() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.45
        animation.toValue = 1.0
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        for view in [typePlaceholder, timePlaceholder, trailingPlaceholder] {
            view.layer.removeAnimation(forKey: "shuttleTimetableSkeletonOpacity")
            view.layer.add(animation, forKey: "shuttleTimetableSkeletonOpacity")
        }
    }
}
