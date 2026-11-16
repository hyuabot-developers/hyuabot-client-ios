//
//  CafeteriaHeaderBarView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaHeaderBarView: UIView {
    let monthButton = UIButton(configuration: .plain())
    let todayButton = HYUHeaderButton(style: .capsule, symbolName: nil, title: String(localized: "cafeteria.today"))
    let shareButton = HYUHeaderButton(style: .capsule, symbolName: "square.and.arrow.up", title: String(localized: "common.share"))
    var onMonthTap: (() -> Void)?
    var onTodayTap: (() -> Void)?
    var onShareTap: (() -> Void)?

    private let campusLabel = UILabel()
    private let subtitleRow = HYUOverflowHitStackView()
    private var shareEnabled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        setupViews()
        setupConstraints()
        applyShareStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        campusLabel.adjustsFontForContentSizeCategory = true
        subtitleRow.axis = .horizontal
        subtitleRow.alignment = .center
        subtitleRow.spacing = 4
        subtitleRow.addArrangedSubview(campusLabel)

        monthButton.accessibilityIdentifier = "cafeteria.month_button"
        monthButton.addTarget(self, action: #selector(monthTapped), for: .touchUpInside)
        subtitleRow.addArrangedSubview(monthButton)
        addSubview(subtitleRow)

        todayButton.accessibilityIdentifier = "cafeteria.today_button"
        todayButton.addTarget(self, action: #selector(todayTapped), for: .touchUpInside)

        shareButton.accessibilityIdentifier = "cafeteria_share_button"
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        addSubview(todayButton)
    }

    private func setupConstraints() {
        subtitleRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.trailing.lessThanOrEqualTo(todayButton.snp.leading).offset(-12)
        }
        todayButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-4)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(44)
        }
        monthButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.centerY.equalTo(subtitleRow.snp.centerY)
        }
    }

    func configure(
        campusName: String,
        monthText: String,
        monthAccessibilityLabel: String,
        showsToday: Bool,
        shareEnabled: Bool,
        shareAccessibilityLabel: String
    ) {
        campusLabel.attributedText = SettingsStyle.attributedText(
            String(format: String(localized: "cafeteria.header.campus.format"), campusName),
            font: SettingsStyle.font(14), color: SettingsStyle.Color.secondaryText, lineHeight: 20
        )
        let title = NSAttributedString(string: monthText, attributes: [
            .font: SettingsStyle.monospacedDigitFont(14, bold: true),
            .foregroundColor: SettingsStyle.Color.link
        ])
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(title)
        configuration.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        )
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 2
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 4)
        monthButton.configuration = configuration
        monthButton.accessibilityLabel = monthAccessibilityLabel
        todayButton.accessibilityLabel = String(localized: "cafeteria.today.a11y")
        todayButton.isHidden = !showsToday
        self.shareEnabled = shareEnabled
        shareButton.accessibilityLabel = shareAccessibilityLabel
        applyShareStyle()
    }

    private func applyShareStyle() {
        shareButton.capsuleView.backgroundColor = shareEnabled
            ? SettingsStyle.Color.accentFill
            : SettingsStyle.Color.segmentBackground
        shareButton.isEnabled = shareEnabled
    }

    @objc
    private func monthTapped() {
        onMonthTap?()
    }

    @objc
    private func todayTapped() {
        onTodayTap?()
    }

    @objc
    private func shareTapped() {
        onShareTap?()
    }
}
