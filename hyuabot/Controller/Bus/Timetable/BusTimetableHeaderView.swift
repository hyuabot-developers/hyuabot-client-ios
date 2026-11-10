//
//  BusTimetableHeaderView.swift
//  hyuabot
//

import SnapKit
import UIKit

struct BusTimetableHeaderContent: Equatable {
    let routeNames: [String]
    let stopName: String
    let days: [BusTimetableDay]
    let selectedDay: BusTimetableDay
    let dayCounts: [Int]
    let filter: String?
    let state: BusTimetableHeaderState
}

enum BusTimetableHeaderState: Equatable {
    case loading
    case empty(title: String, detail: String)
    case list(hiddenPastCount: Int)

    static func noService(dayName: String) -> BusTimetableHeaderState {
        .empty(
            title: String(format: String(localized: "bus.timetable.empty.title.%@"), dayName),
            detail: String(localized: "bus.timetable.empty.detail")
        )
    }

    static func noData(route: String) -> BusTimetableHeaderState {
        let name = String(format: String(localized: "bus.realtime.route.%@"), route)
        return .empty(
            title: String(format: String(localized: "bus.timetable.empty.nodata.title.%@"), name),
            detail: String(localized: "bus.timetable.empty.nodata.detail")
        )
    }
}

final class BusTimetableHeaderView: UIView {
    var onSelectDay: ((BusTimetableDay) -> Void)?
    var onSelectFilter: ((String?) -> Void)?
    var onExpand: (() -> Void)?

    private let contentStack = UIStackView()
    private let titleRow = UIStackView()
    private let badgeStack = UIStackView()
    private let titleLabel = UILabel()
    private let segment = SubwaySegmentView(buttonIdentifierPrefix: "bus.timetable.day")
    private let filterSpacing = UIView()
    private let filterStack = UIStackView()
    private let stateContainer = UIView()
    private var lastContent: BusTimetableHeaderContent?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentStack.axis = .vertical
        addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview()
        }
        setupTitle()
        contentStack.addArrangedSubview(spacer(20))
        contentStack.addArrangedSubview(segment)
        segment.onSelect = { [weak self] index in
            guard let self, let content = self.lastContent, content.days.indices.contains(index) else { return }
            self.onSelectDay?(content.days[index])
        }
        filterStack.axis = .horizontal
        filterStack.spacing = 4
        filterStack.distribution = .fill
        contentStack.addArrangedSubview(filterSpacing)
        contentStack.addArrangedSubview(filterStack)
        contentStack.addArrangedSubview(spacer(16))
        contentStack.addArrangedSubview(stateContainer)
        stateContainer.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ content: BusTimetableHeaderContent) {
        guard content != lastContent else { return }
        lastContent = content
        configureTitle(content.routeNames, stopName: content.stopName)
        configureDays(content)
        configureFilters(content)
        configureState(content.state)
    }

    func fittingHeight(width: CGFloat) -> CGFloat {
        systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func setupTitle() {
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8
        titleRow.isLayoutMarginsRelativeArrangement = true
        titleRow.layoutMargins = .zero
        titleRow.insetsLayoutMarginsFromSafeArea = false
        badgeStack.axis = .horizontal
        badgeStack.spacing = 4
        titleRow.addArrangedSubview(badgeStack)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.accessibilityTraits = .header
        titleRow.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(titleRow)
        titleRow.snp.makeConstraints { $0.height.equalTo(40) }
    }

    private func configureTitle(_ routes: [String], stopName: String) {
        badgeStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        routes.forEach { route in
            let badge = BusRouteBadgeView(size: .regular)
            badge.configure(route: route)
            badgeStack.addArrangedSubview(badge)
        }
        let title = SettingsStyle.attributedText(
            stopName,
            font: SettingsStyle.font(24, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 32
        )
        let kernedTitle = title.mutableCopy() as? NSMutableAttributedString
        if let kernedTitle, kernedTitle.length > 0 {
            kernedTitle.addAttribute(.kern, value: -0.4, range: NSRange(location: 0, length: kernedTitle.length))
        }
        titleLabel.attributedText = kernedTitle ?? title
    }

    private func configureDays(_ content: BusTimetableHeaderContent) {
        let items = content.days.enumerated().map { index, day in
            let title: String
            switch day {
            case .weekdays: title = String(localized: "bus.timetable.weekdays")
            case .saturday: title = String(localized: "bus.timetable.saturdays")
            case .sunday: title = String(localized: "bus.timetable.sundays")
            case .weekends: title = String(localized: "bus.timetable.weekends")
            }
            let count = content.dayCounts.indices.contains(index) ? content.dayCounts[index] : 0
            let countText = count > 0
                ? String(format: String(localized: "bus.timetable.count.%lld"), count)
                : String(localized: "bus.timetable.count.none")
            return SubwaySegmentView.Item(title: title, dotColors: [], count: countText)
        }
        segment.configure(items: items, selected: content.days.firstIndex(of: content.selectedDay) ?? 0)
    }

    private func configureFilters(_ content: BusTimetableHeaderContent) {
        filterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        filterStack.isHidden = content.routeNames.count <= 1
        filterSpacing.isHidden = filterStack.isHidden
        filterSpacing.snp.remakeConstraints { $0.height.equalTo(filterStack.isHidden ? 0 : 12) }
        guard !filterStack.isHidden else { return }
        filterStack.addArrangedSubview(makeChip(
            title: String(localized: "bus.timetable.filter.all"),
            route: nil,
            selected: content.filter == nil
        ))
        for route in content.routeNames {
            let title = String(format: String(localized: "bus.realtime.route.%@"), route)
            filterStack.addArrangedSubview(makeChip(title: title, route: route, selected: content.filter == route))
        }
    }

    private func makeChip(title: String, route: String?, selected: Bool) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        config.baseForegroundColor = selected ? SettingsStyle.Color.onAccent : SettingsStyle.Color.text
        let button = UIButton(configuration: config)
        button.setAttributedTitle(SettingsStyle.attributedText(
            title,
            font: SettingsStyle.monospacedDigitFont(14, bold: selected),
            color: selected ? SettingsStyle.Color.onAccent : SettingsStyle.Color.text,
            lineHeight: 20
        ), for: .normal)
        button.backgroundColor = selected ? SettingsStyle.Color.accent : SettingsStyle.Color.card
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = (selected ? SettingsStyle.Color.accent : SettingsStyle.Color.busChipLine).cgColor
        button.snp.makeConstraints { $0.height.equalTo(32) }
        button.addAction(UIAction { [weak self] _ in self?.onSelectFilter?(route) }, for: .touchUpInside)
        return button
    }

    private func configureState(_ state: BusTimetableHeaderState) {
        stateContainer.subviews.forEach { $0.removeFromSuperview() }
        stateContainer.isHidden = false
        switch state {
        case .loading: makeSkeleton()
        case let .empty(title, detail): makeEmpty(title: title, detail: detail)
        case let .list(hiddenPastCount):
            stateContainer.isHidden = hiddenPastCount <= 0
            if hiddenPastCount > 0 { makeFoldButton(hiddenPastCount) }
        }
    }

    private func makeSkeleton() {
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        card.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stateContainer.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 12
        card.addSubview(rows)
        rows.snp.makeConstraints { $0.edges.equalTo(card.layoutMarginsGuide) }
        let widths: [CGFloat] = [22, 18, 26, 20, 24, 16, 22, 18, 20, 24]
        for percent in widths { addSkeletonRow(to: rows, percent: percent) }
    }

    private func addSkeletonRow(to rows: UIStackView, percent: CGFloat) {
        let row = UIView()
        rows.addArrangedSubview(row)
        row.snp.makeConstraints { $0.height.equalTo(44) }
        let time = skeletonBar(width: 48, height: 16, radius: 8)
        row.addSubview(time)
        time.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }
        let destination = skeletonBar(width: nil, height: 14, radius: 7)
        row.addSubview(destination)
        destination.snp.makeConstraints {
            $0.leading.equalTo(time.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(row.snp.width).offset(-60).multipliedBy(percent / 100)
        }
    }

    private func skeletonBar(width: CGFloat?, height: CGFloat, radius: CGFloat) -> UIView {
        let bar = UIView()
        bar.backgroundColor = SettingsStyle.Color.segmentBackground
        bar.layer.cornerRadius = radius
        bar.snp.makeConstraints {
            if let width { $0.width.equalTo(width) }
            $0.height.equalTo(height)
        }
        return bar
    }

    private func makeEmpty(title: String, detail: String) {
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        card.layoutMargins = UIEdgeInsets(top: 32, left: 24, bottom: 36, right: 24)
        stateContainer.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalTo(card.layoutMarginsGuide) }
        let icon = UIImageView(image: UIImage(systemName: "calendar"))
        icon.tintColor = SettingsStyle.Color.commuterFaint
        icon.backgroundColor = SettingsStyle.Color.segmentBackground
        icon.contentMode = .center
        icon.layer.cornerRadius = 22
        icon.snp.makeConstraints { $0.size.equalTo(44) }
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(spacer(8))
        stack.addArrangedSubview(makeStateLabel(title, size: 15, bold: true, color: SettingsStyle.Color.text, line: 20))
        stack.addArrangedSubview(makeStateLabel(detail, size: 13, bold: false, color: SettingsStyle.Color.secondaryText, line: 18))
    }

    private func makeStateLabel(_ text: String, size: CGFloat, bold: Bool, color: UIColor, line: CGFloat) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.attributedText = SettingsStyle.attributedText(
            text,
            font: SettingsStyle.font(size, bold: bold),
            color: color,
            lineHeight: line
        )
        return label
    }

    private func makeFoldButton(_ count: Int) {
        let button = UIButton(type: .system)
        button.backgroundColor = SettingsStyle.Color.card
        button.layer.cornerRadius = 16
        button.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.up")?.applyingSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        )
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.baseForegroundColor = SettingsStyle.Color.link
        config.attributedTitle = AttributedString(SettingsStyle.attributedText(
            String(format: String(localized: "bus.timetable.fold.%lld"), count),
            font: SettingsStyle.font(13, bold: true), color: SettingsStyle.Color.link, lineHeight: 18
        ))
        button.configuration = config
        button.addAction(UIAction { [weak self] _ in self?.onExpand?() }, for: .touchUpInside)
        let separator = UIView()
        separator.backgroundColor = SettingsStyle.Color.separator
        let stack = UIStackView(arrangedSubviews: [button, separator])
        stack.axis = .vertical
        stateContainer.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(44) }
        separator.snp.makeConstraints { $0.height.equalTo(1) }
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let view = UIView()
        view.snp.makeConstraints { $0.height.equalTo(height) }
        return view
    }
}

final class BusTimetableHourHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "BusTimetableHourHeaderView"
    private let strip = UIView()
    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundConfiguration = .clear()
        contentView.backgroundColor = SettingsStyle.Color.background
        contentView.addSubview(strip)
        strip.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(20); $0.top.bottom.equalToSuperview() }
        strip.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().inset(2)
            $0.height.equalTo(18)
        }
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func height(isFirst: Bool) -> CGFloat { (isFirst ? 12 : 6) + 18 + 2 }

    func configure(hour: Int, isFirst: Bool, roundsTop: Bool) {
        let hourText = String(format: "%02d", hour >= 24 ? hour - 24 : hour)
        let text: String
        if hour >= 24 {
            text = String(format: String(localized: "bus.timetable.hour.after_midnight.%@"), hourText)
        } else {
            text = String(format: String(localized: "bus.timetable.hour.%@"), hourText)
        }
        label.attributedText = SettingsStyle.attributedText(
            text,
            font: SettingsStyle.font(13, bold: true),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        label.snp.updateConstraints { $0.top.equalToSuperview().offset(isFirst ? 12 : 6) }
        strip.backgroundColor = SettingsStyle.Color.card
        strip.layer.cornerRadius = roundsTop ? 16 : 0
        strip.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
}

final class BusTimetableCardFooterView: UIView {
    private let cardStrip = UIView()
    private let footnote = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        addSubview(stack)
        stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.bottom.equalToSuperview().inset(40) }
        cardStrip.backgroundColor = SettingsStyle.Color.card
        cardStrip.layer.cornerRadius = 16
        cardStrip.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        stack.addArrangedSubview(cardStrip)
        cardStrip.snp.makeConstraints { $0.height.equalTo(8); $0.leading.trailing.equalToSuperview().inset(20) }
        footnote.numberOfLines = 0
        footnote.adjustsFontForContentSizeCategory = true
        footnote.attributedText = SettingsStyle.attributedText(
            String(localized: "bus.timetable.footnote"),
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16
        )
        stack.addArrangedSubview(footnote)
        footnote.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(20) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(showsCard: Bool) { cardStrip.isHidden = !showsCard }

    static func height(showsCard: Bool, width: CGFloat) -> CGFloat {
        let view = BusTimetableCardFooterView()
        view.configure(showsCard: showsCard)
        return view.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }
}
