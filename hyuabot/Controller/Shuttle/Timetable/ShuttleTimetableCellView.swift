//
//  ShuttleTimetableCellView.swift
//  hyuabot
//

import Api
import SnapKit
import Then
import UIKit

class ShuttleTimetableCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleTimetableCellView"
    static let rowHeight: CGFloat = 44

    var item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order?

    private let chipView = BusRouteBadgeView(size: .shuttle)
    private let nextBadge = PaddedBadgeLabel()
    private var chipText: String?
    private let shuttleTimeLabel = UILabel().then {
        $0.numberOfLines = 1
    }

    private let arrivalLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(13)
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let cardBackground = UIView()
    private let rowStack = UIStackView()

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
        contentView.addSubview(cardBackground)
        cardBackground.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(Self.rowHeight)
        }
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.addArrangedSubview(shuttleTimeLabel)
        rowStack.addArrangedSubview(chipView)
        rowStack.addArrangedSubview(arrivalLabel)
        rowStack.addArrangedSubview(nextBadge)
        nextBadge.isHidden = true
        cardBackground.addSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
        shuttleTimeLabel.snp.makeConstraints { make in
            make.width.equalTo(52)
        }
        chipView.setContentHuggingPriority(.required, for: .horizontal)
        chipView.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrivalLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func setupUI(
        option: ShuttleTimetableOptions,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        resetChip()
        switch option.start {
        case "shuttle.stop.dormitory.out", "shuttle.stop.shuttlecock.out":
            configureOutbound(option: option, item: item)
        case "shuttle.stop.station":
            configureStationDestination(option: option, item: item)
        case "shuttle.stop.terminal", "shuttle.stop.jungang.station", "shuttle.stop.shuttlecock.in":
            configureInbound(item: item)
        default:
            break
        }
        let time = item.time.toLocalTimeOrNil().map {
            let components = Calendar.current.dateComponents([.hour, .minute], from: $0)
            return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
        } ?? item.time.substring(from: 0, to: 4)
        shuttleTimeLabel.attributedText = SettingsStyle.attributedText(
            time,
            font: SettingsStyle.monospacedDigitFont(17),
            color: SettingsStyle.Color.text,
            lineHeight: 22
        )
        let route = ShuttleDisplayLogic.timetableRoute(start: option.start, end: option.end)
        let arrivalText = ShuttleDisplayLogic.timetableArrivalText(
            destinationKey: route.destinationKey,
            boardingTime: item.time,
            stops: item.stops.map { ShuttleDisplayLogic.StopTime(stop: $0.stop, time: $0.time) }
        )
        arrivalLabel.text = arrivalText.map { "▸ \($0)" } ?? ""
        self.item = item
        updateAccessibilityLabel()
    }

    func apply(state: ShuttleDisplayLogic.TimetableRowState, roundsBottom: Bool) {
        let timeColor: UIColor
        let arrivalColor: UIColor
        switch state {
        case .past:
            timeColor = SettingsStyle.Color.subwayPast
            arrivalColor = SettingsStyle.Color.subwayPast
            cardBackground.backgroundColor = SettingsStyle.Color.card
            shuttleTimeLabel.font = SettingsStyle.monospacedDigitFont(17)
        case .next:
            timeColor = SettingsStyle.Color.link
            arrivalColor = SettingsStyle.Color.secondaryText
            cardBackground.backgroundColor = SettingsStyle.Color.commuterNearRow
            shuttleTimeLabel.font = SettingsStyle.monospacedDigitFont(17, bold: true)
        case .upcoming:
            timeColor = SettingsStyle.Color.text
            arrivalColor = SettingsStyle.Color.secondaryText
            cardBackground.backgroundColor = SettingsStyle.Color.card
            shuttleTimeLabel.font = SettingsStyle.monospacedDigitFont(17, bold: true)
        }
        if let time = shuttleTimeLabel.attributedText?.string {
            shuttleTimeLabel.attributedText = SettingsStyle.attributedText(
                time,
                font: shuttleTimeLabel.font,
                color: timeColor,
                lineHeight: 22
            )
        }
        arrivalLabel.textColor = arrivalColor
        cardBackground.layer.cornerRadius = roundsBottom ? 16 : 0
        cardBackground.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        cardBackground.layer.cornerCurve = .continuous
        updateAccessibilityLabel()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        item = nil
        arrivalLabel.text = nil
        resetChip()
        shuttleTimeLabel.attributedText = nil
        apply(state: .upcoming, roundsBottom: false)
    }

    private func updateAccessibilityLabel() {
        accessibilityLabel = [shuttleTimeLabel.attributedText?.string, chipText, arrivalLabel.text]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        isAccessibilityElement = true
    }

    private func configureOutbound(
        option: ShuttleTimetableOptions,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        if option.end == "shuttle.destination.shorten.station" {
            configureOutboundStationRoute(item.route.tag)
        } else if option.end == "shuttle.destination.shorten.terminal" {
            configureTerminalRoute(item.route.tag)
        } else if option.end == "shuttle.destination.shorten.jungang_station" {
            setJungangStationType()
        }
    }

    private func configureOutboundStationRoute(_ routeTag: String) {
        if routeTag == "DH" || routeTag == "DJ" {
            setChip(String(localized: "shuttle.type.direct"), kind: .direct)
        } else if routeTag == "C" {
            setCircularType()
        }
    }

    private func configureTerminalRoute(_ routeTag: String) {
        if routeTag == "DY" {
            setChip(String(localized: "shuttle.type.direct"), kind: .direct)
        } else if routeTag == "C" {
            setCircularType()
        }
    }

    private func configureStationDestination(
        option: ShuttleTimetableOptions,
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        if option.end == "shuttle.destination.shorten.campus" {
            configureCampusRoute(item.route.tag)
        } else if option.end == "shuttle.destination.shorten.terminal" {
            setCircularType()
        } else if option.end == "shuttle.destination.shorten.jungang_station" {
            setJungangStationType()
        }
    }

    private func configureCampusRoute(_ routeTag: String) {
        if routeTag == "DH" {
            setChip(String(localized: "shuttle.type.direct"), kind: .direct)
        } else if routeTag == "DJ" {
            setJungangStationType()
        } else if routeTag == "C" {
            setCircularType()
        }
    }

    private func configureInbound(
        item: ShuttleTimetablePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        if item.route.name.hasSuffix("S") {
            setChip(String(localized: "shuttle.type.shuttlecock"), kind: .terminal)
        } else if item.route.name.hasSuffix("D") {
            setChip(String(localized: "shuttle.type.dormitory"), kind: .fallback)
        }
    }

    private func resetChip() {
        chipText = nil
        chipView.isHidden = true
        setNextBadge(nil)
    }

    private func setChip(_ text: String, kind: ShuttleDisplayLogic.RouteChipKind) {
        chipText = text
        chipView.isHidden = false
        chipView.configure(text: text, fill: BusRouteBadgeView.shuttleFill(for: kind))
    }

    func setNextBadge(_ text: String?) {
        nextBadge.isHidden = text == nil
        nextBadge.text = text
    }

    private func setJungangStationType() {
        setChip(String(localized: "shuttle.type.jungang_station"), kind: .jungang)
    }

    private func setCircularType() {
        setChip(String(localized: "shuttle.type.circular"), kind: .circular)
    }
}

/// Small filled pill used for the "N분 후" marker on the next departure row.
private final class PaddedBadgeLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = SettingsStyle.font(12, bold: true)
        textColor = .white
        backgroundColor = SettingsStyle.Color.accent
        textAlignment = .center
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        clipsToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 16, height: 22)
    }
}
