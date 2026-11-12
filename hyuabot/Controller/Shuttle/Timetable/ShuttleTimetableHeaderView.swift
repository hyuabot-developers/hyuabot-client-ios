//
//  ShuttleTimetableHeaderView.swift
//  hyuabot
//

import SnapKit
import UIKit

@MainActor
final class ShuttleTimetableHeaderView: UIView {
    let routeButton = UIButton(type: .system)
    let daySegment = SubwaySegmentView(buttonIdentifierPrefix: "shuttle.timetable.day")
    var onRouteTap: (() -> Void)?
    var onSelectDay: ((Bool) -> Void)?

    private let stack = UIStackView()
    private let periodLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.alignment = .fill
        addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview()
        }

        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero
        configuration.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )?.withTintColor(SettingsStyle.Color.text, renderingMode: .alwaysOriginal)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 6
        routeButton.configuration = configuration
        routeButton.accessibilityIdentifier = "shuttle.timetable.route"
        routeButton.accessibilityHint = String(localized: "shuttle.timetable.filter")
        routeButton.contentHorizontalAlignment = .leading
        routeButton.addTarget(self, action: #selector(routeTapped), for: .touchUpInside)

        periodLabel.numberOfLines = 1
        stack.addArrangedSubview(routeButton)
        stack.setCustomSpacing(4, after: routeButton)
        stack.addArrangedSubview(periodLabel)
        stack.setCustomSpacing(20, after: periodLabel)
        stack.addArrangedSubview(daySegment)
        let bottomSpacing = UIView()
        bottomSpacing.snp.makeConstraints { $0.height.equalTo(16) }
        stack.addArrangedSubview(bottomSpacing)

        daySegment.configure(items: [
            .init(title: String(localized: "shuttle.timetable.weekdays"), dotColors: [], count: nil),
            .init(title: String(localized: "shuttle.timetable.weekends"), dotColors: [], count: nil)
        ], selected: 0)
        daySegment.onSelect = { [weak self] index in
            self?.onSelectDay?(index == 0)
        }
    }

    func configure(start: String, end: String, period: String?, isWeekdays: Bool) {
        let title = "\(start) → \(end)"
        let titleText = NSMutableAttributedString(attributedString: SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(24, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 32
        ))
        titleText.addAttribute(.kern, value: -0.4, range: NSRange(location: 0, length: titleText.length))
        var configuration = routeButton.configuration ?? .plain()
        configuration.attributedTitle = AttributedString(titleText)
        routeButton.configuration = configuration

        periodLabel.attributedText = period.map { period in
            let text = NSMutableAttributedString(
                string: "● ",
                attributes: [.font: SettingsStyle.font(9), .foregroundColor: SettingsStyle.Color.levelGood, .baselineOffset: 1]
            )
            text.append(SettingsStyle.attributedText(
                String(format: String(localized: "shuttle.timetable.period.%@"), period),
                font: SettingsStyle.font(13),
                color: SettingsStyle.Color.secondaryText,
                lineHeight: 18
            ))
            return text
        }
        periodLabel.isHidden = period == nil
        daySegment.setSelected(isWeekdays ? 0 : 1)
        invalidateIntrinsicContentSize()
    }

    func fittingHeight(width: CGFloat) -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    @objc
    private func routeTapped() {
        onRouteTap?()
    }
}
