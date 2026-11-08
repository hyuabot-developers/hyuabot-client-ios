//
//  SubwayTimetableHeaderView.swift
//  hyuabot
//
import SnapKit
import UIKit

final class SubwayTimetableHeaderView: UIView {
    var onSelectDay: ((SubwayDayType) -> Void)?
    var onExpand: (() -> Void)?

    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let badgeStack = UIStackView()
    private let segment = SubwaySegmentView(buttonIdentifierPrefix: "subway.timetable.day")
    private let legendStack = UIStackView()
    private let skeletonCard = UIView()
    private let foldButton = UIButton(type: .system)
    private let foldSeparator = UIView()
    private var currentLine: SubwayLine?
    private var currentHeading: SubwayHeadingEnum?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentStack.axis = .vertical
        contentStack.spacing = 0
        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(1)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        makeTitleRow()
        contentStack.addArrangedSubview(spacer(20))
        contentStack.addArrangedSubview(segment)
        segment.onSelect = { [weak self] index in
            self?.onSelectDay?(index == 0 ? .weekdays : .weekends)
        }
        legendStack.axis = .horizontal
        legendStack.alignment = .center
        legendStack.spacing = 12
        contentStack.addArrangedSubview(legendStack)
        contentStack.addArrangedSubview(spacer(16))
        makeSkeleton()
        contentStack.addArrangedSubview(skeletonCard)
        makeFoldButton()
        contentStack.addArrangedSubview(foldButton)
        contentStack.addArrangedSubview(foldSeparator)
        legendStack.isHidden = true
        skeletonCard.isHidden = true
        foldButton.isHidden = true
        foldSeparator.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable:next function_parameter_count
    func configure(
        line: SubwayLine,
        heading: SubwayHeadingEnum,
        day: SubwayDayType,
        weekdayCount: Int?,
        weekendCount: Int?,
        isLoading: Bool,
        hiddenPastCount: Int
    ) {
        currentLine = line
        currentHeading = heading
        let merged = SubwayDisplayLogic.isMerged(line: line, heading: heading)
        configureBadges(line: line, heading: heading, merged: merged)
        updateTitle()
        legendStack.isHidden = !merged
        configureLegend()
        segment.configure(
            items: [
                .init(title: String(localized: "subway.timetable.weekdays"), dotColors: [], count: weekdayCount.map(countText)),
                .init(title: String(localized: "subway.timetable.weekends.holidays"), dotColors: [], count: weekendCount.map(countText))
            ],
            selected: day == .weekdays ? 0 : 1
        )
        skeletonCard.isHidden = !isLoading
        foldButton.isHidden = isLoading || hiddenPastCount <= 0
        foldSeparator.isHidden = isLoading || hiddenPastCount <= 0
        if hiddenPastCount > 0 {
            var configuration = foldButton.configuration ?? .plain()
            let title = String(format: String(localized: "subway.timetable.fold.%lld"), hiddenPastCount)
            configuration.attributedTitle = AttributedString(
                SettingsStyle.attributedText(
                    title,
                    font: SettingsStyle.font(13, bold: true),
                    color: SettingsStyle.Color.link,
                    lineHeight: 18
                )
            )
            foldButton.configuration = configuration
        }
    }

    /// T8 removes this adapter once its caller moves to the C9 header contract.
    func configure(
        line: SubwayLine,
        heading: SubwayHeadingEnum,
        day: SubwayDayType,
        counts: (weekday: Int?, weekend: Int?),
        isLoading: Bool,
        layout: SubwayTimetableLayout
    ) {
        configure(
            line: line,
            heading: heading,
            day: day,
            weekdayCount: counts.weekday,
            weekendCount: counts.weekend,
            isLoading: isLoading,
            hiddenPastCount: layout.hiddenPastCount
        )
    }

    func fittingHeight(width: CGFloat) -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func makeTitleRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        badgeStack.axis = .horizontal
        badgeStack.spacing = 4
        row.addArrangedSubview(badgeStack)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(row)
        row.snp.makeConstraints { $0.height.equalTo(40) }
        titleLabel.snp.makeConstraints { $0.height.equalTo(40) }
    }

    private func configureBadges(line: SubwayLine, heading: SubwayHeadingEnum, merged: Bool) {
        badgeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let lines: [SubwayRouteLine] = merged ? [.line4, .suin] : [SubwayDisplayLogic.routeLine(line)]
        for route in lines {
            let badge = SubwayLineBadgeView(size: .large)
            badge.configure(.line(route))
            badgeStack.addArrangedSubview(badge)
        }
        updateTitle()
    }

    private func updateTitle() {
        guard let line = currentLine, let heading = currentHeading else { return }
        let text = SubwayDisplayLogic.title(line: line, heading: heading)
        let attributed = NSMutableAttributedString(
            attributedString: SettingsStyle.attributedText(
                text,
                font: SettingsStyle.font(32, bold: true),
                color: SettingsStyle.Color.text,
                lineHeight: 40
            )
        )
        attributed.addAttribute(.kern, value: -0.5, range: NSRange(location: 0, length: attributed.length))
        titleLabel.attributedText = attributed
        titleLabel.accessibilityTraits = .header
    }

    private func configureLegend() {
        legendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        legendStack.isLayoutMarginsRelativeArrangement = true
        legendStack.layoutMargins = UIEdgeInsets(top: 12, left: 4, bottom: 0, right: 4)
        legendStack.addArrangedSubview(legendItem(line: .line4, title: String(localized: "subway.line.name.line4")))
        legendStack.addArrangedSubview(legendItem(line: .suin, title: String(localized: "subway.line.name.suin")))
        let note = UILabel()
        note.numberOfLines = 0
        note.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        note.attributedText = SettingsStyle.attributedText(
            String(localized: "subway.timetable.merged.note"),
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16
        )
        legendStack.addArrangedSubview(note)
    }

    private func legendItem(line: SubwayLine, title: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 6
        let dot = UIView()
        dot.backgroundColor = SubwayDisplayLogic.routeLine(line).color
        dot.layer.cornerRadius = 4
        dot.snp.makeConstraints { $0.size.equalTo(8) }
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 16
        )
        row.addArrangedSubview(dot)
        row.addArrangedSubview(label)
        return row
    }

    private func makeSkeleton() {
        skeletonCard.backgroundColor = SettingsStyle.Color.card
        skeletonCard.layer.cornerRadius = 16
        skeletonCard.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 12
        skeletonCard.addSubview(rows)
        rows.snp.makeConstraints { $0.edges.equalTo(skeletonCard.layoutMarginsGuide) }
        let widths: [CGFloat] = [34, 28, 40, 30, 36, 26, 38, 32, 30, 36]
        for (index, percent) in widths.enumerated() {
            let row = UIView()
            rows.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(44) }
            let time = skeletonBar(width: 48, height: 16, radius: 8, row: index)
            row.addSubview(time)
            time.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
            let remaining = UILayoutGuide()
            row.addLayoutGuide(remaining)
            remaining.snp.makeConstraints {
                $0.leading.equalTo(time.snp.trailing).offset(12)
                $0.trailing.top.bottom.equalToSuperview()
            }
            let destination = skeletonBar(width: nil, height: 14, radius: 7, row: index)
            row.addSubview(destination)
            destination.snp.makeConstraints {
                $0.leading.equalTo(time.snp.trailing).offset(12)
                $0.centerY.equalToSuperview()
                $0.width.equalTo(remaining.snp.width).multipliedBy(percent / 100)
            }
        }
    }

    private func skeletonBar(width: CGFloat?, height: CGFloat, radius: CGFloat, row: Int) -> UIView {
        let bar = UIView()
        bar.backgroundColor = SettingsStyle.Color.segmentBackground
        bar.layer.cornerRadius = radius
        bar.snp.makeConstraints {
            if let width {
                $0.width.equalTo(width)
            }
            $0.height.equalTo(height)
        }
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0.45
        pulse.duration = 0.8
        pulse.autoreverses = true
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulse.repeatCount = .infinity
        pulse.isRemovedOnCompletion = false
        pulse.beginTime = CACurrentMediaTime() + Double(row) * 0.06
        bar.layer.add(pulse, forKey: "cafeteria.skeleton.pulse")
        return bar
    }

    private func makeFoldButton() {
        foldButton.backgroundColor = SettingsStyle.Color.card
        foldButton.layer.cornerRadius = 16
        foldButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        foldButton.contentHorizontalAlignment = .leading
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.up")?.applyingSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        )
        configuration.imagePlacement = .leading
        configuration.imagePadding = 4
        configuration.baseForegroundColor = SettingsStyle.Color.link
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        foldButton.configuration = configuration
        foldButton.addTarget(self, action: #selector(expand), for: .touchUpInside)
        foldButton.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        foldSeparator.backgroundColor = SettingsStyle.Color.separator
        foldSeparator.snp.makeConstraints { $0.height.equalTo(1) }
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.snp.makeConstraints { $0.height.equalTo(height) }
        return view
    }

    private func countText(_ count: Int) -> String {
        String(format: String(localized: "subway.timetable.count.%lld"), count)
    }

    @objc
    private func expand() {
        onExpand?()
    }
}

final class SubwayTimetableHourHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "SubwayTimetableHourHeaderView"
    private let hourLabel = UILabel()
    private let strip = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundConfiguration = .clear()
        contentView.backgroundColor = .clear
        contentView.addSubview(strip)
        strip.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }
        strip.addSubview(hourLabel)
        hourLabel.snp
            .makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(16); $0.top.equalToSuperview().offset(6); $0.bottom.equalToSuperview()
                    .inset(2); $0
                    .height.equalTo(18)
            }
        hourLabel.attributedText = SettingsStyle.attributedText(
            "",
            font: SettingsStyle.font(13, bold: true),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        hourLabel.accessibilityTraits = .header
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ group: SubwayTimetableHourGroup, isFirst: Bool, roundsTop: Bool) {
        hourLabel.attributedText = SettingsStyle.attributedText(
            group.title,
            font: SettingsStyle.font(13, bold: true),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        hourLabel.accessibilityTraits = .header
        hourLabel.accessibilityLabel = group.accessibilityLabel
        strip.backgroundColor = SettingsStyle.Color.card
        strip.layer.cornerRadius = roundsTop ? 16 : 0
        strip.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        hourLabel.snp
            .remakeConstraints {
                $0.leading.trailing.equalToSuperview().inset(16); $0.top.equalToSuperview().offset(isFirst ? 12 : 6); $0.bottom
                    .equalToSuperview().inset(2); $0.height.equalTo(18)
            }
    }
}

final class SubwayTimetableCardFooterView: UIView {
    private let footnoteLabel = UILabel()
    private let cardStrip = UIView()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        addSubview(stack)
        stack.snp
            .makeConstraints { $0.top.equalToSuperview(); $0.leading.trailing.equalToSuperview(); $0.bottom.equalToSuperview().inset(40) }
        cardStrip.backgroundColor = SettingsStyle.Color.card
        cardStrip.layer.cornerRadius = 16
        cardStrip.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        stack.addArrangedSubview(cardStrip)
        cardStrip.snp.makeConstraints {
            $0.height.equalTo(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        footnoteLabel.numberOfLines = 0
        footnoteLabel.attributedText = SettingsStyle.attributedText(
            String(localized: "subway.timetable.footnote"),
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16
        )
        stack.addArrangedSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(20) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(showsCard: Bool, showsFootnote: Bool) {
        cardStrip.isHidden = !showsCard
        footnoteLabel.isHidden = !showsFootnote
    }

    func fittingHeight(width: CGFloat) -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }
}
