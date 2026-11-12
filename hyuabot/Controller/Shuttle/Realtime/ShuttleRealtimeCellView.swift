//
//  ShuttleRealtimeCellView.swift
//  hyuabot
//

import Api
import RxSwift
import UIKit

// swiftlint:disable file_length

// swiftlint:disable:next type_body_length
class ShuttleRealtimeCellView: UITableViewCell {
    static let reuseIdentifier = "ShuttleRealtimeCellView"
    static let informationRowHeight: CGFloat = 56
    static let expandedRowHeight: CGFloat = 48
    private let cardBackground = UIView().then { $0.backgroundColor = SettingsStyle.Color.card }
    private let routeBadge = BusRouteBadgeView(size: .shuttle)

    private let shuttleTypeLabel = UILabel().then { $0.isHidden = true }
    private let primaryLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(17, bold: true)
        $0.textColor = SettingsStyle.Color.text
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let trailingLabel = UILabel().then {
        $0.font = SettingsStyle.monospacedDigitFont(20, bold: true)
        $0.textColor = SettingsStyle.Color.text
        $0.textAlignment = .right
    }

    private let subLabel = UILabel().then {
        $0.textColor = SettingsStyle.Color.secondaryText
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private var arrivalText: String?
    private var titleText: String?
    private let disposeBag = DisposeBag()
    private var showsRemainingTime = UserDefaults.standard.bool(forKey: "showRemainingTime")
    private var departureDate: Foundation.Date?
    /// Rounds the card's outer corners when the row is the first/last row of a standalone card (time-ordered list).
    func setCardCorners(isFirst: Bool, isLast: Bool) {
        var corners: CACornerMask = []
        if isFirst {
            corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        }
        if isLast {
            corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        cardBackground.layer.cornerRadius = corners.isEmpty ? 0 : 16
        cardBackground.layer.cornerCurve = .continuous
        cardBackground.layer.maskedCorners = corners
        cardBackground.clipsToBounds = !corners.isEmpty
    }

    var showsTopSeparator = false {
        didSet { topSeparator.isHidden = !showsTopSeparator }
    }

    private let topSeparator = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.separator
        $0.isHidden = true
    }

    private lazy var primaryStack = UIStackView(arrangedSubviews: [routeBadge, primaryLabel, lastRunView, shuttleAlertView]).then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 6
    }

    private lazy var leftStack = UIStackView(arrangedSubviews: [primaryStack, subLabel]).then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 4
        $0.isAccessibilityElement = true
    }

    private let shuttleAlertLabel = UILabel().then {
        $0.font = SettingsStyle.font(12, bold: true)
        $0.textColor = SettingsStyle.Color.warnText
        $0.text = String(localized: "shuttle.location.alert")
        $0.textAlignment = .center
    }

    private lazy var shuttleAlertView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.warnFill
        $0.layer.cornerRadius = 6
        $0.layer.masksToBounds = true
        $0.isHidden = true
        $0.isAccessibilityElement = true
        $0.accessibilityLabel = self.shuttleAlertLabel.text
        $0.addSubview(self.shuttleAlertLabel)
    }

    private let lastRunLabel = UILabel().then {
        $0.font = SettingsStyle.font(12, bold: true)
        $0.textColor = SettingsStyle.Color.subwayLastText
        $0.text = String(localized: "shuttle.last_run")
        $0.textAlignment = .center
    }

    private lazy var lastRunView = UIView().then {
        $0.backgroundColor = SettingsStyle.Color.subwayLastFill
        $0.layer.cornerRadius = 6
        $0.layer.masksToBounds = true
        $0.isHidden = true
        $0.isAccessibilityElement = true
        $0.accessibilityLabel = self.lastRunLabel.text
        $0.addSubview(self.lastRunLabel)
    }

    private let chevronView = UIImageView().then {
        $0.tintColor = SettingsStyle.Color.chevron
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    var itemByOrder: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order?
    var itemByDestination: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?
    private var isBoardingAlarmActive = false {
        didSet { renderSubtitle() }
    }

    private(set) var isRowExpanded = false

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
        setExpanded(false)
    }

    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        clipsToBounds = false
        contentView.clipsToBounds = false
        contentView.addSubview(cardBackground)
        cardBackground.addSubview(leftStack)
        cardBackground.addSubview(trailingLabel)
        cardBackground.addSubview(chevronView)
        cardBackground.addSubview(topSeparator)
        cardBackground.isAccessibilityElement = false
        cardBackground.accessibilityElements = [leftStack]
        selectionStyle = .none
        primaryLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        lastRunView.setContentCompressionResistancePriority(.required, for: .horizontal)
        shuttleAlertView.setContentCompressionResistancePriority(.required, for: .horizontal)
        setupConstraints()
        observeSubjects()
        setExpanded(false)
    }

    private func setupConstraints() {
        shuttleAlertLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
        shuttleAlertView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        lastRunLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
        lastRunView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        cardBackground.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        leftStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().inset(12)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
            make.trailing.lessThanOrEqualTo(trailingLabel.snp.leading).offset(-12)
        }
        trailingLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevronView.snp.leading).offset(-10)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(52)
        }
        chevronView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        topSeparator.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func setExpanded(_ expanded: Bool) {
        isRowExpanded = expanded
        chevronView.image = UIImage(
            systemName: expanded ? "chevron.up" : "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        )
        leftStack.accessibilityTraits = .button
        leftStack.accessibilityHint = String(localized: expanded ? "shuttle.row.collapse.hint" : "shuttle.row.expand.hint")
    }

    func setupUI(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order,
        isBoardingAlarmActive: Bool = false
    ) {
        shuttleTypeLabel.text = nil
        shuttleAlertView.isHidden = true
        lastRunView.isHidden = !isLastRun(stopID: stopID, indexPath: indexPath, item: item)
        itemByDestination = nil
        self.isBoardingAlarmActive = isBoardingAlarmActive
        setTypeText(stopID: stopID, item: item)
        itemByOrder = item
        let stopKey = ShuttleDisplayLogic.stopKey(stopID)
        applyRouteBadge(stopKey: stopKey, destinationKey: nil, routeTag: item.route.tag)
        let stops = item.stops.map { ShuttleDisplayLogic.StopTime(stop: $0.stop, time: $0.time) }
        titleText = ShuttleDisplayLogic.orderRowText(boardingStopID: stopKey, boardingTime: item.time, stops: stops)
        arrivalText = nil
        renderSubtitle()
        setUITimeLabel(time: item.time)
    }

    func setupUI(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry,
        isBoardingAlarmActive: Bool = false
    ) {
        shuttleTypeLabel.text = nil
        shuttleAlertView.isHidden = true
        lastRunView.isHidden = !isLastRun(stopID: stopID, indexPath: indexPath, item: item)
        itemByOrder = nil
        self.isBoardingAlarmActive = isBoardingAlarmActive
        setTypeText(stopID: stopID, indexPath: indexPath, item: item)
        itemByDestination = item
        let stopKey = ShuttleDisplayLogic.stopKey(stopID)
        let destinationKey = ShuttleDisplayLogic.destinationKey(stopID: stopKey, section: indexPath.section)
        applyRouteBadge(stopKey: stopKey, destinationKey: destinationKey, routeTag: item.route.tag)
        let stops = item.stops.map { ShuttleDisplayLogic.StopTime(stop: $0.stop, time: $0.time) }
        titleText = destinationKey.flatMap {
            ShuttleDisplayLogic.destinationRowText(destinationKey: $0, boardingTime: item.time, stops: stops)
        }
        arrivalText = nil
        renderSubtitle()
        setUITimeLabel(time: item.time)
    }

    func setUITimeLabel(time: LocalTime) {
        guard let date = time.toLocalTimeOrNil() else {
            departureDate = nil
            primaryLabel.text = nil
            trailingLabel.text = String(localized: "shuttle.time.remaining.0")
            return
        }
        departureDate = date
        renderTimes()
    }

    private func renderTimes() {
        guard let departureDate else { return }
        let times = ShuttleDisplayLogic.rowTimes(departure: departureDate, now: .now, showsRemainingTime: showsRemainingTime)
        primaryLabel.text = nil
        primaryLabel.isHidden = true
        trailingLabel.text = times.trailing
        trailingLabel.textColor = times.isSoon ? SettingsStyle.Color.subwaySoon : SettingsStyle.Color.text
        updateAccessibilityLabel()
    }

    private func applyRouteBadge(stopKey: String, destinationKey: String?, routeTag: String) {
        let text = shuttleTypeLabel.text ?? ""
        routeBadge.isHidden = text.isEmpty
        routeBadge.configure(
            text: text,
            fill: BusRouteBadgeView.shuttleFill(for: ShuttleDisplayLogic.routeChipKind(
                stopID: stopKey,
                destinationKey: destinationKey,
                routeTag: routeTag
            ))
        )
    }

    private func renderSubtitle() {
        let parts = [arrivalText, isBoardingAlarmActive ? String(localized: "shuttle.row.alarm.on") : nil].compactMap { $0 }
        subLabel.isHidden = parts.isEmpty
        subLabel.attributedText = SettingsStyle.attributedText(
            parts.joined(separator: " · "),
            font: SettingsStyle.font(15, bold: false),
            color: isBoardingAlarmActive ? SettingsStyle.Color.link : SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        updateAccessibilityLabel()
    }

    private func updateAccessibilityLabel() {
        var parts = [shuttleTypeLabel.text, titleText, trailingLabel.text].compactMap { $0 }.filter { !$0.isEmpty }
        if !subLabel.isHidden, let subtitle = subLabel.attributedText?.string {
            parts.append(subtitle)
        }
        if !lastRunView.isHidden, let text = lastRunLabel.text {
            parts.append(text)
        }
        if !shuttleAlertView.isHidden, let text = shuttleAlertLabel.text {
            parts.append(text)
        }
        leftStack.accessibilityLabel = parts.joined(separator: " ")
    }

    private func setTypeText(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        switch stopID {
        case .dormiotryOut, .shuttlecockOut:
            setCampusDepartureTypeText(stopID: stopID, item: item)
        case .station:
            setStationDepartureTypeText(item: item)
        case .terminal:
            setTerminalTypeText(item: item)
        case .jungangStation:
            shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
        case .shuttlecockIn:
            setShuttlecockArrivalTypeText(item: item)
        default:
            break
        }
    }

    private func setCampusDepartureTypeText(
        stopID: ShuttleStopEnum,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) {
        switch item.route.tag {
        case "DH":
            shuttleTypeLabel.text = String(localized: "shuttle_type_school_station")

        case "DY":
            shuttleTypeLabel.text = String(localized: "shuttle_type_school_terminal")

            shuttleAlertView.isHidden = stopID != .shuttlecockOut

        case "DJ":
            shuttleTypeLabel.text = String(localized: "shuttle_type_school_jungang_station")

        case "C":
            shuttleTypeLabel.text = String(localized: "shuttle_type_school_circular")

        default:
            break
        }
    }

    private func setStationDepartureTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        switch item.route.tag {
        case "DH":
            setStationDormitoryOrShuttlecockText(routeName: item.route.name)
        case "DJ":
            shuttleTypeLabel.text = String(localized: "shuttle_type_jungang_station")
        case "C":
            setStationCircularText(routeName: item.route.name)
        default:
            break
        }
    }

    private func setStationDormitoryOrShuttlecockText(routeName: String) {
        if routeName.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock")

        } else if routeName.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
        }
    }

    private func setStationCircularText(routeName: String) {
        if routeName.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_station_circular_shuttlecock")
        } else if routeName.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_station_circular_dormitory")
        }
    }

    private func setTerminalTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock")
        } else if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
        }
    }

    private func setShuttlecockArrivalTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) {
        if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_shuttlecock_finishing")
        } else if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle_type_dormitory")
        }
    }

    func observeSubjects() {
        ShuttleRealtimeData.shared.showRemainingTime.subscribe(onNext: { [weak self] showRemainingTime in
            self?.showsRemainingTime = showRemainingTime
            self?.renderTimes()
        }).disposed(by: disposeBag)
    }
}

extension ShuttleRealtimeCellView {
    private func setTypeText(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) {
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            setCampusDepartureTypeText(section: indexPath.section, item: item)
            shuttleAlertView.isHidden = stopID != .shuttlecockOut || item.route.tag != "DY"
        } else if stopID == .station {
            setStationDepartureTypeText(section: indexPath.section, item: item)
        } else if stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn {
            setCampusBoundTypeText(item: item)
        }
    }

    private func setCampusDepartureTypeText(
        section: Int,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) {
        if section == 0 {
            if item.route.tag == "DH" || item.route.tag == "DJ" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct")

            } else if item.route.tag == "C" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
            }
        } else if section == 1 {
            if item.route.tag == "DY" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct")

            } else if item.route.tag == "C" {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular")
            }
        } else if section == 2 {
            shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
        }
    }

    private func setStationDepartureTypeText(
        section: Int,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) {
        if section == 0 {
            setStationCampusRouteTypeText(item: item)
        } else if section == 1 {
            setStationTerminalRouteTypeText(item: item)
        } else if section == 2 {
            shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")
        }
    }

    private func setStationCampusRouteTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        if item.route.tag == "DH" {
            if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct.dormitory")
            } else if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.direct.shuttlecock")
            }

        } else if item.route.tag == "DJ" {
            shuttleTypeLabel.text = String(localized: "shuttle.type.jungang_station")

        } else if item.route.tag == "C" {
            if item.route.name.hasSuffix("D") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
            } else if item.route.name.hasSuffix("S") {
                shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
            }
        }
    }

    private func setStationTerminalRouteTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.circular.dormitory")
        } else if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.circular.shuttlecock")
        }
    }

    private func setCampusBoundTypeText(item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry) {
        if item.route.name.hasSuffix("S") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.shuttlecock")
        } else if item.route.name.hasSuffix("D") {
            shuttleTypeLabel.text = String(localized: "shuttle.type.dormitory")
        }
    }

    private func isLastRun(
        stopID: ShuttleStopEnum,
        indexPath _: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order
    ) -> Bool {
        let data: [ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]? = switch stopID {
        case .dormiotryOut:
            try? ShuttleRealtimeData.shared.shuttleDormitoryData.value()
        case .shuttlecockOut:
            try? ShuttleRealtimeData.shared.shuttleShuttlecockData.value()
        case .station:
            try? ShuttleRealtimeData.shared.shuttleStationData.value()
        case .terminal:
            try? ShuttleRealtimeData.shared.shuttleTerminalData.value()
        case .jungangStation:
            try? ShuttleRealtimeData.shared.shuttleJungangStationData.value()
        case .shuttlecockIn:
            try? ShuttleRealtimeData.shared.shuttleShuttlecockInData.value()
        }
        return data?.last?.seq == item.seq
    }

    private func isLastRun(
        stopID: ShuttleStopEnum,
        indexPath: IndexPath,
        item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry
    ) -> Bool {
        let data: [ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry]? = switch (stopID, indexPath.section) {
        case (.dormiotryOut, 0):
            try? ShuttleRealtimeData.shared.shuttleDormitoryToStationData.value()
        case (.dormiotryOut, 1):
            try? ShuttleRealtimeData.shared.shuttleDormitoryToTerminalData.value()
        case (.dormiotryOut, 2):
            try? ShuttleRealtimeData.shared.shuttleDormitoryToJungangStationData.value()
        case (.shuttlecockOut, 0):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockToStationData.value()
        case (.shuttlecockOut, 1):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockToTerminalData.value()
        case (.shuttlecockOut, 2):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockToJungangStationData.value()
        case (.station, 0):
            try? ShuttleRealtimeData.shared.shuttleStationToCampusData.value()
        case (.station, 1):
            try? ShuttleRealtimeData.shared.shuttleStationToTerminalData.value()
        case (.station, 2):
            try? ShuttleRealtimeData.shared.shuttleStationToJungangStationData.value()
        case (.terminal, 0):
            try? ShuttleRealtimeData.shared.shuttleTerminalToCampusData.value()
        case (.jungangStation, 0):
            try? ShuttleRealtimeData.shared.shuttleJungangStationToCampusData.value()
        case (.shuttlecockIn, 0):
            try? ShuttleRealtimeData.shared.shuttleShuttlecockInToDormitoryData.value()
        default:
            nil
        }
        return data?.last?.seq == item.seq
    }
}
