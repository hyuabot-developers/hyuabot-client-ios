//
//  ShuttleRealtimeSkeletonCellView.swift
//  hyuabot
//

import UIKit

class ShuttleRealtimeSkeletonCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeSkeletonCellView"

    private let cardView = UIView()
    private let leadingPlaceholder = UIView()
    private let upperPlaceholder = UIView()
    private let lowerPlaceholder = UIView()
    private let trailingPlaceholder = UIView()
    private let centerStack = UIStackView()

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
        // Flat segment: the section header and footer own the card's rounded corners.
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SettingsStyle.Metric.cardInset)
        }

        for view in [leadingPlaceholder, upperPlaceholder, lowerPlaceholder, trailingPlaceholder] {
            view.backgroundColor = SettingsStyle.Color.segmentBackground
            view.layer.masksToBounds = true
        }
        leadingPlaceholder.layer.cornerRadius = 6
        trailingPlaceholder.layer.cornerRadius = 6
        upperPlaceholder.layer.cornerRadius = 7
        lowerPlaceholder.layer.cornerRadius = 7

        cardView.addSubview(leadingPlaceholder)
        cardView.addSubview(centerStack)
        cardView.addSubview(trailingPlaceholder)

        centerStack.axis = .vertical
        centerStack.spacing = 6
        centerStack.alignment = .leading
        centerStack.distribution = .fillEqually
        centerStack.addArrangedSubview(upperPlaceholder)
        centerStack.addArrangedSubview(lowerPlaceholder)

        leadingPlaceholder.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(20)
        }
        trailingPlaceholder.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(20)
        }
        centerStack.snp.makeConstraints { make in
            make.leading.equalTo(leadingPlaceholder.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(trailingPlaceholder.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(cardView.snp.width).multipliedBy(0.5)
            make.height.equalTo(34)
        }
        upperPlaceholder.snp.makeConstraints { make in
            make.width.equalTo(cardView.snp.width).multipliedBy(0.34)
            make.height.equalTo(14)
        }
        lowerPlaceholder.snp.makeConstraints { make in
            make.width.equalTo(cardView.snp.width).multipliedBy(0.5)
            make.height.equalTo(14)
        }

        startAnimating()
    }

    func setIsLast(_ isLast: Bool) {
        cardView.layer.cornerRadius = isLast ? SettingsStyle.Metric.cardRadius : 0
        cardView.layer.cornerCurve = .continuous
        cardView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cardView.clipsToBounds = isLast
    }

    private func startAnimating() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.45
        animation.toValue = 1.0
        animation.duration = 0.9
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        for view in [leadingPlaceholder, upperPlaceholder, lowerPlaceholder, trailingPlaceholder] {
            view.layer.removeAnimation(forKey: "shuttleRealtimeSkeletonOpacity")
            view.layer.add(animation, forKey: "shuttleRealtimeSkeletonOpacity")
        }
    }
}
