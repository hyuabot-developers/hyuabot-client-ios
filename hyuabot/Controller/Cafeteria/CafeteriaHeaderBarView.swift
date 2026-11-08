//
//  CafeteriaHeaderBarView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaHeaderBarView: UIView {
    let monthButton = UIButton(configuration: .plain())
    let todayButton = UIButton(type: .system)
    let shareButton = UIButton(type: .system)
    var onMonthTap: (() -> Void)?
    var onTodayTap: (() -> Void)?
    var onShareTap: (() -> Void)?

    private let titleLabel = UILabel()
    private let campusLabel = UILabel()
    private let subtitleRow = OverflowHitStackView()
    private let leftColumn = OverflowHitStackView()
    private let rightGroup = UIStackView()
    private let todayLabel = UILabel()
    private let todayCapsule = UIView()
    private let shareCircle = UIView()
    private let shareIcon = UIImageView()
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
        titleLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "tabbar.cafeteria"), font: SettingsStyle.font(32, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 40
        ).withKern(-0.5)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityIdentifier = "cafeteria.title"
        campusLabel.adjustsFontForContentSizeCategory = true
        subtitleRow.axis = .horizontal
        subtitleRow.alignment = .center
        subtitleRow.spacing = 4
        subtitleRow.addArrangedSubview(campusLabel)

        monthButton.accessibilityIdentifier = "cafeteria.month_button"
        monthButton.addTarget(self, action: #selector(monthTapped), for: .touchUpInside)
        subtitleRow.addArrangedSubview(monthButton)
        leftColumn.axis = .vertical
        leftColumn.alignment = .leading
        leftColumn.spacing = 2
        leftColumn.addArrangedSubview(titleLabel)
        leftColumn.addArrangedSubview(subtitleRow)
        addSubview(leftColumn)

        todayLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "cafeteria.today"), font: SettingsStyle.font(13, bold: true),
            color: SettingsStyle.Color.link, lineHeight: 16, alignment: .center
        )
        todayLabel.adjustsFontForContentSizeCategory = true
        todayLabel.isUserInteractionEnabled = false
        todayCapsule.backgroundColor = SettingsStyle.Color.accentFill
        todayCapsule.layer.cornerRadius = 16
        todayCapsule.isUserInteractionEnabled = false
        todayCapsule.addSubview(todayLabel)
        todayButton.addSubview(todayCapsule)
        todayButton.accessibilityIdentifier = "cafeteria.today_button"
        todayButton.addTarget(self, action: #selector(todayTapped), for: .touchUpInside)

        shareButton.accessibilityIdentifier = "cafeteria_share_button"
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        rightGroup.axis = .horizontal
        rightGroup.alignment = .center
        rightGroup.spacing = 4
        rightGroup.addArrangedSubview(todayButton)
        rightGroup.addArrangedSubview(shareButton)
        addSubview(rightGroup)
    }

    private func setupConstraints() {
        leftColumn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(rightGroup.snp.leading).offset(-12)
        }
        rightGroup.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-4)
            make.top.equalToSuperview().offset(-2)
        }
        subtitleRow.snp.makeConstraints { $0.height.equalTo(20) }
        monthButton.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.centerY.equalTo(subtitleRow.snp.centerY)
        }
        todayButton.snp.makeConstraints { $0.height.equalTo(44) }
        todayCapsule.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(32)
            make.leading.trailing.equalToSuperview().inset(2)
        }
        todayLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(12)
        }
        todayLabel.setContentHuggingPriority(.required, for: .horizontal)
        todayLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        shareButton.snp.makeConstraints { $0.size.equalTo(44) }
        shareCircle.layer.cornerRadius = 16
        shareCircle.isUserInteractionEnabled = false
        shareIcon.image = UIImage(
            systemName: "square.and.arrow.up",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        shareIcon.contentMode = .center
        shareCircle.addSubview(shareIcon)
        shareIcon.snp.makeConstraints { $0.edges.equalToSuperview() }
        shareButton.addSubview(shareCircle)
        shareCircle.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(32) }
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
        shareCircle.backgroundColor = shareEnabled ? SettingsStyle.Color.accentFill : SettingsStyle.Color.segmentBackground
        shareIcon.tintColor = shareEnabled ? SettingsStyle.Color.link : SettingsStyle.Color.commuterFaint
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

extension NSAttributedString {
    func withKern(_ kern: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        result.addAttribute(.kern, value: kern, range: NSRange(location: 0, length: result.length))
        return result
    }
}

/// Stack view that also hit-tests subviews extending beyond its bounds (e.g. a 44pt button in a 20pt row).
private final class OverflowHitStackView: UIStackView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }
        for subview in subviews.reversed() {
            let converted = subview.convert(point, from: self)
            if let hit = subview.hitTest(converted, with: event) { return hit }
        }
        return super.hitTest(point, with: event)
    }
}
