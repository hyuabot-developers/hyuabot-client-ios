import Api
import SnapKit
import UIKit

// swiftlint:disable file_length

private extension UIColor {
    static let line4Color = UIColor(red: 0, green: 160 / 255, blue: 233 / 255, alpha: 1)
    static let suinColor = UIColor(red: 0.72, green: 0.48, blue: 0, alpha: 1)
    static let seohaeColor = UIColor(red: 0.56, green: 0.76, blue: 0.12, alpha: 1)
    static let transferBusColor = UIColor(named: "busGreen") ?? .systemGreen
}

enum TransferVehicleType {
    case subway
    case bus
}

enum TransferTimelineSource: Equatable {
    case realtime
    case timetable
    case arrivalLog
}

private func localizedTransferMinuteText(_ minutes: Int) -> String {
    let language = Locale.current.language.languageCode?.identifier ?? "ko"
    guard !language.hasPrefix("ko") else {
        return String(format: String(localized: "transfer.bus.time.format"), minutes)
    }
    return "\(minutes)m"
}

struct TransferTimelineEntry: Equatable {
    let destination: String
    let minutes: Int?
    let stops: Int?
    let locationLabel: String?
    let direction: Int
    let source: TransferTimelineSource
    let clockTime: Foundation.Date?
    let waitingMinutes: Int?

    var scheduledArrivalText: String? {
        guard let clockTime else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: clockTime)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        let key: String
        switch source {
        case .realtime:
            return nil
        case .timetable:
            key = "home.transfer.subway.timetable.arrival"
        case .arrivalLog:
            key = "home.transfer.bus50.log.arrival_record"
        }
        return String(
            format: String(localized: String.LocalizationValue(key)),
            locale: Locale.current,
            hour,
            minute
        )
    }

    var waitingText: String? {
        guard let waitingMinutes else { return nil }
        guard waitingMinutes > 0 else {
            return String(localized: "home.transfer.wait.immediate")
        }
        return String(
            format: String(localized: "home.transfer.wait.minutes"),
            locale: Locale.current,
            waitingMinutes
        )
    }
}

struct TransferRow: Equatable {
    let name: String
    let targetName: String
    let color: UIColor
    let vehicleType: TransferVehicleType
    let timeline: [TransferTimelineEntry]
    let connectorTitle: String?
    let connectorTravelMinutes: Int?

    init(
        name: String,
        targetName: String,
        color: UIColor,
        vehicleType: TransferVehicleType,
        timeline: [TransferTimelineEntry],
        connectorTitle: String? = nil,
        connectorTravelMinutes: Int? = nil
    ) {
        self.name = name
        self.targetName = targetName
        self.color = color
        self.vehicleType = vehicleType
        self.timeline = timeline
        self.connectorTitle = connectorTitle
        self.connectorTravelMinutes = connectorTravelMinutes
    }

    var preferredHeight: CGFloat {
        switch vehicleType {
        case .subway:
            100
        case .bus:
            84
        }
    }

    static func == (lhs: TransferRow, rhs: TransferRow) -> Bool {
        lhs.name == rhs.name &&
            lhs.targetName == rhs.targetName &&
            lhs.vehicleType == rhs.vehicleType &&
            lhs.timeline == rhs.timeline &&
            lhs.connectorTitle == rhs.connectorTitle &&
            lhs.connectorTravelMinutes == rhs.connectorTravelMinutes
    }
}

private struct TransferLine {
    let stationID: String
    let name: String
    let color: UIColor
}

private struct SubwayTransferCandidate {
    let line: TransferLine
    let terminalStationID: String
    let terminalName: String
    let arrivalDate: Foundation.Date
    let minutes: Int?
    let stops: Int?
    let direction: Int
    let source: TransferTimelineSource
}

enum ShuttleTransferDestination {
    case all
    case station
    case terminal
    case jungangStation
}

enum ShuttleTransferPresentation {
    case summary
    case inline
}

// swiftlint:disable:next type_body_length
private final class TransferTimelineView: UIView {
    private let sideStations = 3
    private let visibleBusStops = 7
    private let compressedNearBusStop = 4
    private let bubbleWidth: CGFloat = 72
    private let bubbleHeight: CGFloat = 30
    private let targetTrackGap: CGFloat = 16
    private var row: TransferRow?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(row: TransferRow) {
        self.row = row
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let row, !row.timeline.isEmpty, let context = UIGraphicsGetCurrentContext() else { return }

        let left = bounds.minX + 28
        let right = bounds.maxX - 28
        let centerY = bounds.midY
        let targetX = row.vehicleType == .subway ? (left + right) / 2 : right
        let color = row.color
        let entriesByDirection = Dictionary(grouping: row.timeline.prefix(4), by: { $0.direction })

        context.setLineCap(.round)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2)

        if row.vehicleType == .subway {
            drawSubwayTrack(
                context: context,
                entriesByDirection: entriesByDirection,
                targetX: targetX,
                centerY: centerY,
                left: left,
                right: right,
                color: color
            )
        }

        for (direction, entries) in entriesByDirection {
            drawEntries(
                context: context,
                type: row.vehicleType,
                entries: Array(entries.prefix(2)),
                targetX: targetX,
                centerY: centerY,
                direction: direction,
                left: left,
                right: right,
                color: color
            )
        }

        drawTarget(context: context, type: row.vehicleType, targetX: targetX, centerY: centerY, color: color)
    }

    private func drawSubwayTrack(
        context: CGContext,
        entriesByDirection: [Int: [TransferTimelineEntry]],
        targetX: CGFloat,
        centerY: CGFloat,
        left: CGFloat,
        right: CGFloat,
        color: UIColor
    ) {
        let targetClearance = targetHalfWidth() + targetTrackGap
        let availableLength = min(targetX - left, right - targetX)
        let step = trackStep(availableLength: availableLength, clearance: targetClearance, stopCount: sideStations)
        for direction in [-1, 1] {
            let directionEntries = entriesByDirection[direction] ?? []
            let allFar = !directionEntries.isEmpty && directionEntries.allSatisfy { ($0.stops ?? sideStations + 1) > sideStations }
            let edgeX = trackX(
                targetX: targetX,
                direction: direction,
                index: sideStations,
                clearance: targetClearance,
                step: step,
                left: left,
                right: right
            )
            if allFar {
                let solidEndX = trackX(
                    targetX: targetX,
                    direction: direction,
                    index: sideStations - 1,
                    clearance: targetClearance,
                    step: step,
                    left: left,
                    right: right
                )
                drawLine(context: context, from: targetX, to: solidEndX, y: centerY)
                drawLine(context: context, from: solidEndX, to: edgeX, y: centerY, dashed: true)
            } else {
                drawLine(context: context, from: targetX, to: edgeX, y: centerY)
            }
            drawDots(
                context: context,
                targetX: targetX,
                step: step,
                count: sideStations,
                direction: direction,
                centerY: centerY,
                color: color,
                left: left,
                right: right,
                clearance: targetClearance
            )
        }
    }

    private func drawEntries(
        context: CGContext,
        type: TransferVehicleType,
        entries: [TransferTimelineEntry],
        targetX: CGFloat,
        centerY: CGFloat,
        direction: Int,
        left: CGFloat,
        right: CGFloat,
        color: UIColor
    ) {
        let targetClearance = targetHalfWidth() + targetTrackGap
        let availableLength = type == .subway ? min(targetX - left, right - targetX) : targetX - left
        let stopCount = type == .subway ? sideStations : visibleBusStops
        let step = trackStep(availableLength: availableLength, clearance: targetClearance, stopCount: stopCount)

        if type == .bus {
            let allFar = entries.count > 1 && entries.allSatisfy { ($0.stops ?? visibleBusStops) >= 6 }
            let edgeX = trackX(
                targetX: targetX,
                direction: direction,
                index: visibleBusStops,
                clearance: targetClearance,
                step: step,
                left: left,
                right: right
            )
            if allFar {
                let solidEndX = trackX(
                    targetX: targetX,
                    direction: direction,
                    index: compressedNearBusStop,
                    clearance: targetClearance,
                    step: step,
                    left: left,
                    right: right
                )
                drawLine(context: context, from: targetX, to: solidEndX, y: centerY)
                drawLine(context: context, from: solidEndX, to: edgeX, y: centerY, dashed: true)
            } else {
                drawLine(context: context, from: targetX, to: edgeX, y: centerY)
            }
            drawDots(
                context: context,
                targetX: targetX,
                step: step,
                count: visibleBusStops,
                direction: direction,
                centerY: centerY,
                color: color,
                left: left,
                right: right,
                clearance: targetClearance
            )
        }

        for (index, entry) in entries.enumerated() {
            let stops = max(entry.stops ?? 1, 1)
            let vehicleX: CGFloat
            if type == .subway {
                let allFar = entries.count > 1 && entries.allSatisfy { ($0.stops ?? sideStations + 1) > sideStations }
                let visibleStops = allFar ? index + 2 : min(stops, sideStations)
                vehicleX = trackX(
                    targetX: targetX,
                    direction: direction,
                    index: visibleStops,
                    clearance: targetClearance,
                    step: step,
                    left: left,
                    right: right
                )
            } else {
                let allFar = entries.count > 1 && entries.allSatisfy { ($0.stops ?? visibleBusStops) >= 6 }
                let visibleStops = allFar ? (index == 0 ? compressedNearBusStop : visibleBusStops) : min(stops, visibleBusStops)
                vehicleX = trackX(
                    targetX: targetX,
                    direction: direction,
                    index: visibleStops,
                    clearance: targetClearance,
                    step: step,
                    left: left,
                    right: right
                )
            }
            let clampedX = clamp(vehicleX, left, right)
            drawVehicle(context: context, type: type, x: clampedX, y: centerY, color: color)
            drawBubble(entry: entry, type: type, x: clampedX, y: centerY, index: index, total: entries.count)
        }
    }

    private func drawLine(context: CGContext, from: CGFloat, to: CGFloat, y: CGFloat, dashed: Bool = false) {
        context.saveGState()
        context.setLineDash(phase: 0, lengths: dashed ? [4, 4] : [])
        context.move(to: CGPoint(x: from, y: y))
        context.addLine(to: CGPoint(x: to, y: y))
        context.strokePath()
        context.restoreGState()
    }

    private func drawDots(
        context: CGContext,
        targetX: CGFloat,
        step: CGFloat,
        count: Int,
        direction: Int,
        centerY: CGFloat,
        color: UIColor,
        left: CGFloat,
        right: CGFloat,
        clearance: CGFloat
    ) {
        for index in 1 ... count {
            let x = trackX(targetX: targetX, direction: direction, index: index, clearance: clearance, step: step, left: left, right: right)
            guard x >= left, x <= right else { continue }
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: x - 4, y: centerY - 4, width: 8, height: 8))
            context.setFillColor(UIColor.systemBackground.cgColor)
            context.fillEllipse(in: CGRect(x: x - 2, y: centerY - 2, width: 4, height: 4))
        }
    }

    private func drawVehicle(context: CGContext, type: TransferVehicleType, x: CGFloat, y: CGFloat, color: UIColor) {
        let rect = CGRect(x: x - 10, y: y - 10, width: 20, height: 20)
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: rect)
        let text = type == .subway ? "M" : "B"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.godo(size: 10, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
    }

    private func drawBubble(entry: TransferTimelineEntry, type: TransferVehicleType, x: CGFloat, y: CGFloat, index: Int, total: Int) {
        let primary: String
        if type == .bus {
            let minuteText = entry.scheduledArrivalText
                ?? entry.minutes.map { localizedTransferMinuteText($0) }
                ?? entry.destination
            let stopsText = entry.stops
                .map { String(format: String(localized: "transfer.bus.stops.suffix"), $0).trimmingCharacters(in: .whitespaces) }
            primary = [minuteText, stopsText].compactMap { $0 }.joined(separator: " ")
        } else {
            primary = String(format: String(localized: "subway.terminal.%@"), entry.destination)
        }
        let secondary: String? = {
            guard type != .bus else { return nil }
            if let scheduledArrivalText = entry.scheduledArrivalText {
                return scheduledArrivalText
            }
            if let minutes = entry.minutes, let stops = entry.stops {
                return localizedTransferMinuteText(minutes) +
                    String(format: String(localized: "transfer.bus.stops.suffix"), stops)
            }
            if let minutes = entry.minutes {
                return localizedTransferMinuteText(minutes)
            }
            if let stops = entry.stops {
                return String(format: String(localized: "transfer.bus.stops.suffix"), stops)
            }
            return nil
        }()

        let lines = [primary, secondary].compactMap { $0 }.prefix(2)
        guard !lines.isEmpty else { return }

        let width = bubbleWidth(for: Array(lines), type: type)
        let height: CGFloat = lines.count == 1 ? 20 : bubbleHeight
        let above: Bool = if type == .subway {
            entry.direction < 0
        } else {
            total == 1 || index == 0
        }
        let bubbleTrackGap: CGFloat = 16
        let top = above ? y - bubbleTrackGap - height : y + bubbleTrackGap
        let left = clamp(x - width / 2, bounds.minX + 4, bounds.maxX - width - 4)
        let rect = CGRect(x: left, y: top, width: width, height: height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        UIColor.systemBackground.setFill()
        path.fill()
        UIColor.separator.setStroke()
        path.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        for (lineIndex, line) in lines.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.godo(size: lineIndex == 0 ? 10 : 8, weight: lineIndex == 0 ? .semibold : .regular),
                .foregroundColor: lineIndex == 0 ? UIColor.label : UIColor.secondaryLabel,
                .paragraphStyle: paragraph
            ]
            let lineRect = CGRect(x: rect.minX + 4, y: rect.minY + 3 + CGFloat(lineIndex * 12), width: rect.width - 8, height: 12)
            String(line.prefix(16)).draw(in: lineRect, withAttributes: attributes)
        }
    }

    private func bubbleWidth(for lines: [String], type: TransferVehicleType) -> CGFloat {
        let maxTextWidth = lines.enumerated().map { index, line in
            let font = UIFont.godo(size: index == 0 ? 10 : 8, weight: index == 0 ? .semibold : .regular)
            return String(line.prefix(16)).size(withAttributes: [.font: font]).width
        }.max() ?? 0
        let minimumWidth: CGFloat = type == .bus ? 84 : 64
        let maximumWidth = max(min(bounds.width * 0.36, 96), minimumWidth)
        return clamp(max(minimumWidth, ceil(maxTextWidth + 16)), minimumWidth, maximumWidth)
    }

    private func drawTarget(context: CGContext, type: TransferVehicleType, targetX: CGFloat, centerY: CGFloat, color: UIColor) {
        guard let targetName = row?.targetName, !targetName.isEmpty else {
            context.setFillColor(UIColor.systemBackground.cgColor)
            context.fillEllipse(in: CGRect(x: targetX - 7, y: centerY - 7, width: 14, height: 14))
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(3)
            context.strokeEllipse(in: CGRect(x: targetX - 7, y: centerY - 7, width: 14, height: 14))
            return
        }

        let font = UIFont.godo(size: 10, weight: .bold)
        let text = String(targetName.prefix(8))
        let width = targetWidth(text: text, font: font)
        let left = clamp(targetX - width / 2, bounds.minX + 4, bounds.maxX - width - 4)
        let rect = CGRect(x: left, y: centerY - 12, width: width, height: 24)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 12)
        UIColor.systemBackground.setFill()
        path.fill()
        color.setStroke()
        path.lineWidth = 3
        path.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        text.draw(
            in: rect.insetBy(dx: 4, dy: 5),
            withAttributes: [
                .font: font,
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraph
            ]
        )
    }

    private func clamp(_ value: CGFloat, _ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
        min(max(value, minValue), maxValue)
    }

    private func targetHalfWidth() -> CGFloat {
        guard let targetName = row?.targetName, !targetName.isEmpty else { return 7 }
        let font = UIFont.godo(size: 10, weight: .bold)
        return targetWidth(text: String(targetName.prefix(8)), font: font) / 2
    }

    private func targetWidth(text: String, font: UIFont) -> CGFloat {
        let textSize = text.size(withAttributes: [.font: font])
        return min(max(44, ceil(textSize.width + 16)), 84)
    }

    private func trackStep(availableLength: CGFloat, clearance: CGFloat, stopCount: Int) -> CGFloat {
        guard stopCount > 1 else { return max(availableLength, 1) }
        return max((availableLength - clearance) / CGFloat(stopCount - 1), 1)
    }

    private func trackX(
        targetX: CGFloat,
        direction: Int,
        index: Int,
        clearance: CGFloat,
        step: CGFloat,
        left: CGFloat,
        right: CGFloat
    ) -> CGFloat {
        let distance = clearance + CGFloat(max(index - 1, 0)) * step
        return clamp(targetX + CGFloat(direction) * distance, left, right)
    }
}

private final class TransferRowView: UIView {
    private let nameLabel = UILabel().then {
        $0.font = .godo(size: 12, weight: .bold)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.7
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let timelineView = TransferTimelineView()

    init(row: TransferRow) {
        super.init(frame: .zero)
        nameLabel.text = row.name
        nameLabel.backgroundColor = row.color
        timelineView.setup(row: row)
        addSubview(nameLabel)
        addSubview(timelineView)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(104)
            make.height.equalTo(28)
        }
        timelineView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// swiftlint:disable:next type_body_length
final class ShuttleTransferInfoView: UIView {
    var onHeightChange: (() -> Void)?

    private let emptyRowsGraceInterval: TimeInterval = 60
    private let stopID: ShuttleStopEnum
    private let destination: ShuttleTransferDestination
    private let presentation: ShuttleTransferPresentation
    private var rows: [TransferRow] = []
    private var emptyRowsSince: Foundation.Date?
    private var latestData: ShuttleRealtimePageQuery.Data?
    private var selectedShuttle: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?
    private var inlineConnectorViews: [TransferConnectorView] = []

    private let titleLabel = UILabel().then {
        $0.text = String(localized: "shuttle.transfer.section.title")
    }

    private let rowStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
        $0.backgroundColor = .systemBackground
    }

    var preferredHeight: CGFloat {
        guard !rows.isEmpty else { return 0 }
        if presentation == .inline {
            return CGFloat(rows.count) * ShuttleRealtimeCellView.informationRowHeight
        }
        return titleHeight + rows.reduce(CGFloat(0)) { $0 + $1.preferredHeight } + 4
    }

    var inlineConnectorTitle: String? {
        guard presentation == .inline, !rows.isEmpty else { return nil }
        let location = switch destination {
        case .station:
            String(localized: "home.transfer.subway.connector")
        case .terminal:
            String(localized: "home.transfer.bus50.connector")
        case .jungangStation:
            String(localized: "shuttle.stop.jungang.station")
        case .all:
            rows[0].targetName
        }
        return String(
            format: String(localized: "shuttle.connection.transfer.%@"),
            locale: Locale.current,
            location
        )
    }

    var inlineConnectorTintColor: UIColor? {
        guard presentation == .inline else { return nil }
        return rows.first?.color
    }

    var inlineConnectorTravelMinutes: Int? {
        switch destination {
        case .station:
            5
        case .terminal, .jungangStation, .all:
            nil
        }
    }

    private var titleHeight: CGFloat {
        presentation == .summary ? 40 : 34
    }

    init(
        stopID: ShuttleStopEnum,
        destination: ShuttleTransferDestination = .all,
        presentation: ShuttleTransferPresentation = .summary
    ) {
        self.stopID = stopID
        self.destination = destination
        self.presentation = presentation
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        if presentation == .summary {
            titleLabel.textColor = .white
            titleLabel.textAlignment = .center
            titleLabel.font = .godo(size: 16, weight: .bold)
            titleLabel.backgroundColor = .hanyangBlue
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(titleHeight)
            }
        }
        addSubview(rowStackView)
        rowStackView.snp.makeConstraints { make in
            if presentation == .summary {
                make.top.equalTo(titleLabel.snp.bottom).offset(2)
            } else {
                make.top.equalToSuperview()
            }
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(presentation == .summary ? 2 : 0)
        }
    }

    func setup(data: ShuttleRealtimePageQuery.Data?) {
        latestData = data
        guard let data else {
            handleEmptyRows()
            return
        }
        guard stopID == .dormiotryOut || stopID == .shuttlecockOut else {
            render(rows: [])
            return
        }
        let stationRows = ShuttleTransferDisplaySettings.showsSubwayTransfer
            ? buildStationSubwayRows(data: data.subway)
            : []
        let terminalRows = ShuttleTransferDisplaySettings.showsBusTransfer
            ? buildBusRows(
                data: data.transferBus,
                stopSeq: 216_000_759
            )
            : []
        let jungangStationRows = ShuttleTransferDisplaySettings.showsSubwayTransfer
            ? buildSubwayRows(
                data: data.subway,
                lines: [TransferLine(stationID: "K450", name: String(localized: "subway.line4"), color: .line4Color)],
                targetName: String(localized: "shuttle.stop.jungang.station")
            )
            : []
        let rows: [TransferRow] = switch destination {
        case .all:
            stationRows + terminalRows + jungangStationRows
        case .station:
            stationRows
        case .terminal:
            terminalRows
        case .jungangStation:
            jungangStationRows
        }

        guard !rows.isEmpty else {
            handleEmptyRows()
            return
        }

        emptyRowsSince = nil
        render(rows: rows)
    }

    func selectShuttle(_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Destination.Entry?) {
        guard selectedShuttle?.seq != item?.seq else { return }
        selectedShuttle = item
        emptyRowsSince = nil
        render(rows: [])
        setup(data: latestData)
    }

    func reloadDisplaySettings() {
        setup(data: latestData)
    }

    private func handleEmptyRows(now: Foundation.Date = Foundation.Date()) {
        guard !rows.isEmpty else {
            emptyRowsSince = nil
            render(rows: [])
            return
        }

        if let emptyRowsSince {
            guard now.timeIntervalSince(emptyRowsSince) >= emptyRowsGraceInterval else { return }
            self.emptyRowsSince = nil
            render(rows: [])
        } else {
            emptyRowsSince = now
        }
    }

    private func render(rows: [TransferRow]) {
        guard rows != self.rows else { return }
        self.rows = rows
        for arrangedSubview in rowStackView.arrangedSubviews {
            rowStackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
        inlineConnectorViews.forEach { $0.removeFromSuperview() }
        inlineConnectorViews = []
        for row in rows {
            let rowView: UIView
            let rowHeight: CGFloat
            if presentation == .inline {
                rowView = ShuttleCompactTransferRowView(row: row)
                rowHeight = ShuttleRealtimeCellView.informationRowHeight
            } else {
                rowView = TransferRowView(row: row)
                rowHeight = row.preferredHeight
            }
            rowStackView.addArrangedSubview(rowView)
            rowView.snp.makeConstraints { make in
                make.height.equalTo(rowHeight)
            }
            if presentation == .inline, let connectorTitle = row.connectorTitle {
                let connectorView = TransferConnectorView(
                    title: connectorTitle,
                    travelMinutes: row.connectorTravelMinutes,
                    tintColor: row.color
                )
                connectorView.alpha = 0
                connectorView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                addSubview(connectorView)
                connectorView.snp.makeConstraints { make in
                    make.height.equalTo(24)
                    make.centerX.equalToSuperview()
                    make.centerY.equalTo(rowView.snp.top)
                }
                inlineConnectorViews.append(connectorView)
            }
        }
        isHidden = rows.isEmpty
        onHeightChange?()
    }

    func showInlineConnectors(animated: Bool) {
        guard !inlineConnectorViews.isEmpty else { return }
        let changes = {
            for inlineConnectorView in self.inlineConnectorViews {
                inlineConnectorView.alpha = 1
                inlineConnectorView.transform = .identity
            }
        }
        guard animated else {
            changes()
            return
        }
        UIView.animate(
            withDuration: 0.18,
            delay: 0,
            options: [.curveEaseOut, .beginFromCurrentState],
            animations: changes
        )
    }

    func hideInlineConnectors(animated: Bool) {
        guard !inlineConnectorViews.isEmpty else { return }
        let changes = {
            for inlineConnectorView in self.inlineConnectorViews {
                inlineConnectorView.alpha = 0
                inlineConnectorView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }
        }
        guard animated else {
            changes()
            return
        }
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.curveEaseIn, .beginFromCurrentState],
            animations: changes
        )
    }

    private func buildStationSubwayRows(data: [ShuttleRealtimePageQuery.Data.Subway]) -> [TransferRow] {
        let targetName = String(localized: "shuttle.transfer.target.station")
        let line4 = TransferLine(stationID: "K449", name: String(localized: "subway.line4"), color: .line4Color)
        let suinBadge = String(localized: "home.transfer.subway.suin_bundang.badge")
        let suin = TransferLine(stationID: "K251", name: suinBadge, color: .suinColor)
        let oidoSuin = TransferLine(stationID: "K258", name: suinBadge, color: .suinColor)
        let seohaeBadge = String(localized: "home.transfer.subway.seohae.badge")
        let chojiSeohae = TransferLine(stationID: "S26", name: seohaeBadge, color: .seohaeColor)
        let transferStartDate = selectedTransferStartDate

        switch ShuttleTransferDisplaySettings.subwayDestination {
        case .seoul:
            return earliestRows(
                candidates: subwayArrivalCandidates(data: data, line: line4, direction: "up"),
                after: transferStartDate,
                minimumTransferMinutes: inlineConnectorTravelMinutes ?? 0,
                targetName: targetName
            )
        case .suwonYongin:
            return earliestRows(
                candidates: subwayArrivalCandidates(data: data, line: suin, direction: "up"),
                after: transferStartDate,
                minimumTransferMinutes: inlineConnectorTravelMinutes ?? 0,
                targetName: targetName
            )
        case .oido:
            let candidates = oidoFirstLegCandidates(data: data, line4: line4, suin: suin)
            return earliestRows(
                candidates: candidates,
                after: transferStartDate,
                minimumTransferMinutes: inlineConnectorTravelMinutes ?? 0,
                targetName: targetName
            )
        case .sosa:
            return sosaTransferRows(
                data: data,
                line4: line4,
                suin: suin,
                seohae: chojiSeohae,
                after: transferStartDate,
                targetName: targetName
            )
        case .incheon:
            return incheonTransferRows(
                data: data,
                line4: line4,
                suin: suin,
                oidoSuin: oidoSuin,
                after: transferStartDate,
                targetName: targetName
            )
        }
    }

    private func sosaTransferRows(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        line4: TransferLine,
        suin: TransferLine,
        seohae: TransferLine,
        after transferStartDate: Foundation.Date?,
        targetName: String
    ) -> [TransferRow] {
        let firstLegs = eligibleCandidates(
            chojiFirstLegCandidates(data: data, line4: line4, suin: suin),
            after: transferStartDate,
            minimumTransferMinutes: inlineConnectorTravelMinutes ?? 0
        )
        let secondLegs = subwayTimetableCandidates(
            data: data,
            line: seohae,
            direction: "up"
        ) {
            $0.terminal.stationID <= "S16" && $0.terminal.stationID.hasPrefix("S")
        }
        let paths = firstLegs.compactMap { firstLeg -> [SubwayTransferCandidate]? in
            guard let secondLeg = eligibleCandidates(
                secondLegs,
                after: firstLeg.arrivalDate,
                minimumTransferMinutes: 8
            ).min(by: { $0.arrivalDate < $1.arrivalDate }) else { return nil }
            return [firstLeg, secondLeg]
        }
        guard let path = paths.min(by: {
            ($0.last?.arrivalDate ?? .distantFuture) < ($1.last?.arrivalDate ?? .distantFuture)
        }) else { return [] }
        return [
            subwayRow(
                candidate: path[0],
                targetName: targetName,
                after: transferStartDate,
                travelMinutes: inlineConnectorTravelMinutes
            ),
            subwayRow(
                candidate: path[1],
                targetName: targetName,
                after: path[0].arrivalDate,
                travelMinutes: 8,
                connectorTitle: String(localized: "home.transfer.subway.choji.connector"),
                connectorTravelMinutes: 8
            )
        ]
    }

    private func incheonTransferRows(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        line4: TransferLine,
        suin: TransferLine,
        oidoSuin: TransferLine,
        after transferStartDate: Foundation.Date?,
        targetName: String
    ) -> [TransferRow] {
        let directPaths = eligibleCandidates(
            subwayArrivalCandidates(data: data, line: suin, direction: "down") {
                $0.terminal.stationID > "K258" && $0.terminal.stationID.hasPrefix("K2")
            },
            after: transferStartDate,
            minimumTransferMinutes: inlineConnectorTravelMinutes ?? 0
        ).map { [$0] }

        let firstLegs = eligibleCandidates(
            oidoFirstLegCandidates(data: data, line4: line4, suin: suin),
            after: transferStartDate,
            minimumTransferMinutes: inlineConnectorTravelMinutes ?? 0
        )
        let secondLegs = subwayArrivalCandidates(data: data, line: oidoSuin, direction: "down") {
            $0.terminal.stationID > "K258" && $0.terminal.stationID.hasPrefix("K2")
        }
        let transferPaths = firstLegs.compactMap { firstLeg -> [SubwayTransferCandidate]? in
            guard let secondLeg = eligibleCandidates(
                secondLegs,
                after: firstLeg.arrivalDate,
                minimumTransferMinutes: 5
            ).min(by: { $0.arrivalDate < $1.arrivalDate }) else { return nil }
            return [firstLeg, secondLeg]
        }
        guard let path = (directPaths + transferPaths).min(by: {
            ($0.last?.arrivalDate ?? .distantFuture) < ($1.last?.arrivalDate ?? .distantFuture)
        }) else { return [] }
        return path.enumerated().map { index, candidate in
            subwayRow(
                candidate: candidate,
                targetName: targetName,
                after: index == 0 ? transferStartDate : path[index - 1].arrivalDate,
                travelMinutes: index == 0 ? inlineConnectorTravelMinutes : nil,
                connectorTitle: index == 0 ? nil : String(localized: "home.transfer.subway.oido.connector"),
                connectorTravelMinutes: nil
            )
        }
    }

    private func earliestRows(
        candidates: [SubwayTransferCandidate],
        after transferStartDate: Foundation.Date?,
        minimumTransferMinutes: Int,
        targetName: String
    ) -> [TransferRow] {
        guard let candidate = eligibleCandidates(
            candidates,
            after: transferStartDate,
            minimumTransferMinutes: minimumTransferMinutes
        ).min(by: { $0.arrivalDate < $1.arrivalDate }) else { return [] }
        return [
            subwayRow(
                candidate: candidate,
                targetName: targetName,
                after: transferStartDate,
                travelMinutes: inlineConnectorTravelMinutes
            )
        ]
    }

    private func chojiFirstLegCandidates(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        line4: TransferLine,
        suin: TransferLine
    ) -> [SubwayTransferCandidate] {
        let line4Down = subwayArrivalCandidates(data: data, line: line4, direction: "down") {
            $0.terminal.stationID >= "K452" && $0.terminal.stationID.hasPrefix("K4")
        }
        let suinDown = subwayArrivalCandidates(data: data, line: suin, direction: "down") {
            $0.terminal.stationID >= "K254" && $0.terminal.stationID.hasPrefix("K2")
        }
        return line4Down + suinDown
    }

    private func oidoFirstLegCandidates(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        line4: TransferLine,
        suin: TransferLine
    ) -> [SubwayTransferCandidate] {
        let line4Down = subwayArrivalCandidates(data: data, line: line4, direction: "down") {
            $0.terminal.stationID == "K456"
        }
        let suinDown = subwayArrivalCandidates(data: data, line: suin, direction: "down") {
            $0.terminal.stationID >= "K258" && $0.terminal.stationID.hasPrefix("K2")
        }
        return line4Down + suinDown
    }

    private func subwayArrivalCandidates(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        line: TransferLine,
        direction: String,
        isEligible: (ShuttleRealtimePageQuery.Data.Subway.Arrival.Entry) -> Bool = { _ in true }
    ) -> [SubwayTransferCandidate] {
        guard let station = data.first(where: { $0.stationID == line.stationID }),
              let arrival = station.arrival.first(where: { $0.direction == direction })
        else { return [] }
        let now = Foundation.Date.now
        return arrival.entries
            .filter(isEligible)
            .map {
                SubwayTransferCandidate(
                    line: line,
                    terminalStationID: $0.terminal.stationID,
                    terminalName: $0.terminal.name,
                    arrivalDate: now.addingTimeInterval(TimeInterval($0.minutes * 60)),
                    minutes: $0.minutes,
                    stops: $0.stops,
                    direction: subwayDirection(direction),
                    source: $0.isRealtime ? .realtime : .timetable
                )
            }
    }

    private func subwayTimetableCandidates(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        line: TransferLine,
        direction: String,
        isEligible: (ShuttleRealtimePageQuery.Data.Subway.Timetable) -> Bool
    ) -> [SubwayTransferCandidate] {
        guard let station = data.first(where: { $0.stationID == line.stationID }) else { return [] }
        let now = Foundation.Date.now
        return station.timetable
            .filter { $0.direction == direction }
            .filter(isEligible)
            .compactMap {
                guard let arrivalDate = $0.time.toLocalTimeOrNil() else { return nil }
                return SubwayTransferCandidate(
                    line: line,
                    terminalStationID: $0.terminal.stationID,
                    terminalName: $0.terminal.name,
                    arrivalDate: arrivalDate,
                    minutes: max(0, Int(ceil(arrivalDate.timeIntervalSince(now) / 60))),
                    stops: nil,
                    direction: subwayDirection(direction),
                    source: .timetable
                )
            }
    }

    private func eligibleCandidates(
        _ candidates: [SubwayTransferCandidate],
        after transferStartDate: Foundation.Date?,
        minimumTransferMinutes: Int
    ) -> [SubwayTransferCandidate] {
        guard let transferStartDate else { return candidates }
        return candidates.filter {
            $0.arrivalDate.timeIntervalSince(transferStartDate) >= TimeInterval(minimumTransferMinutes * 60)
        }
    }

    private func subwayRow(
        candidate: SubwayTransferCandidate,
        targetName: String,
        after transferStartDate: Foundation.Date?,
        travelMinutes: Int?,
        connectorTitle: String? = nil,
        connectorTravelMinutes: Int? = nil
    ) -> TransferRow {
        let terminal = localizedStationName(
            stationID: candidate.terminalStationID,
            fallback: candidate.terminalName
        )
        let entry = TransferTimelineEntry(
            destination: terminal,
            minutes: candidate.minutes,
            stops: candidate.stops,
            locationLabel: nil,
            direction: candidate.direction,
            source: candidate.source,
            clockTime: candidate.source == .realtime ? nil : candidate.arrivalDate,
            waitingMinutes: transferWaitingMinutes(
                until: candidate.arrivalDate,
                after: transferStartDate,
                travelMinutes: travelMinutes
            )
        )
        return TransferRow(
            name: candidate.line.name,
            targetName: targetName,
            color: candidate.line.color,
            vehicleType: .subway,
            timeline: [entry],
            connectorTitle: connectorTitle,
            connectorTravelMinutes: connectorTravelMinutes
        )
    }

    private func buildSubwayRows(
        data: [ShuttleRealtimePageQuery.Data.Subway],
        lines: [TransferLine],
        targetName: String
    ) -> [TransferRow] {
        let earliestArrival = selectedTransferArrivalDate
        return lines.compactMap { info in
            guard let station = data.first(where: { $0.stationID == info.stationID }) else { return nil }
            let timeline: [TransferTimelineEntry] = station.arrival.flatMap { group -> [TransferTimelineEntry] in
                let direction = subwayDirection(group.direction)
                guard ShuttleTransferDisplaySettings.subwayDestination.includes(
                    stationID: info.stationID,
                    direction: direction
                ) else { return [] }
                return group.entries
                    .filter {
                        guard let earliestArrival else { return true }
                        return Foundation.Date.now.addingTimeInterval(TimeInterval($0.minutes * 60)) >= earliestArrival
                    }
                    .sorted { $0.minutes < $1.minutes }
                    .prefix(1)
                    .map {
                        let arrivalDate = Foundation.Date.now.addingTimeInterval(TimeInterval($0.minutes * 60))
                        return TransferTimelineEntry(
                            destination: localizedStationName(stationID: $0.terminal.stationID, fallback: $0.terminal.name),
                            minutes: $0.minutes,
                            stops: $0.stops,
                            locationLabel: nil,
                            direction: direction,
                            source: $0.isRealtime ? .realtime : .timetable,
                            clockTime: $0.isRealtime ? nil : arrivalDate,
                            waitingMinutes: transferWaitingMinutes(until: arrivalDate)
                        )
                    }
            }
            guard !timeline.isEmpty else { return nil }
            return TransferRow(
                name: info.name,
                targetName: targetName,
                color: info.color,
                vehicleType: .subway,
                timeline: timeline
            )
        }
    }

    private func buildBusRows(data: [ShuttleRealtimePageQuery.Data.TransferBus], stopSeq: Int) -> [TransferRow] {
        let displayLabel = String(localized: "home.transfer.bus50.badge")
        let earliestArrival = selectedTransferArrivalDate
        let matchingBuses = data.filter { $0.stop.seq == stopSeq }
        let realtimeTimeline = matchingBuses
            .flatMap(\.arrival)
            .filter(\.isRealtime)
            .compactMap { arrival -> TransferTimelineEntry? in
                guard let minutes = arrival.minutes else { return nil }
                let arrivalDate = Foundation.Date.now.addingTimeInterval(TimeInterval(minutes * 60))
                guard earliestArrival.map({ arrivalDate >= $0 }) ?? true else { return nil }
                return TransferTimelineEntry(
                    destination: displayLabel,
                    minutes: minutes,
                    stops: arrival.stops,
                    locationLabel: arrival.stops
                        .map { String(format: String(localized: "transfer.bus.stops.suffix"), $0).trimmingCharacters(in: .whitespaces) },
                    direction: -1,
                    source: .realtime,
                    clockTime: nil,
                    waitingMinutes: transferWaitingMinutes(until: arrivalDate)
                )
            }
            .sorted { ($0.minutes ?? .max) < ($1.minutes ?? .max) }
            .prefix(2)
        let logTimes = Set(matchingBuses
            .flatMap(\.log)
            .compactMap { $0.time.toLocalTimeOrNil() })
        let logTimeline = logTimes
            .filter { logDate in
                earliestArrival.map { logDate >= $0 } ?? true
            }
            .sorted()
            .prefix(2)
            .map {
                TransferTimelineEntry(
                    destination: displayLabel,
                    minutes: nil,
                    stops: nil,
                    locationLabel: nil,
                    direction: -1,
                    source: .arrivalLog,
                    clockTime: $0,
                    waitingMinutes: transferWaitingMinutes(until: $0)
                )
            }
        let timeline = realtimeTimeline.isEmpty ? Array(logTimeline) : Array(realtimeTimeline)
        guard !timeline.isEmpty else { return [] }
        return [
            TransferRow(
                name: displayLabel,
                targetName: String(localized: "shuttle.transfer.target.terminal"),
                color: .transferBusColor,
                vehicleType: .bus,
                timeline: timeline
            )
        ]
    }

    private func localizedStationName(stationID: String, fallback: String) -> String {
        fallback
    }

    private func subwayDirection(_ direction: String) -> Int {
        switch direction {
        case "down", "1":
            1
        default:
            -1
        }
    }
}

extension ShuttleTransferInfoView {
    private var selectedTransferStartDate: Foundation.Date? {
        guard let selectedShuttle else { return nil }
        let stopName: String
        switch destination {
        case .station:
            stopName = "station"
        case .terminal:
            stopName = "terminal"
        case .jungangStation:
            stopName = "jungang_stn"
        case .all:
            return nil
        }
        return selectedShuttle.stops
            .first(where: { $0.stop == stopName })?
            .time
            .toLocalTimeOrNil()
    }

    private var selectedTransferArrivalDate: Foundation.Date? {
        selectedTransferStartDate?.addingTimeInterval(
            TimeInterval((inlineConnectorTravelMinutes ?? 0) * 60)
        )
    }

    private func transferWaitingMinutes(until arrivalDate: Foundation.Date) -> Int? {
        transferWaitingMinutes(
            until: arrivalDate,
            after: selectedTransferStartDate,
            travelMinutes: inlineConnectorTravelMinutes
        )
    }

    private func transferWaitingMinutes(
        until arrivalDate: Foundation.Date,
        after transferStartDate: Foundation.Date?,
        travelMinutes: Int?
    ) -> Int? {
        guard let transferStartDate else { return nil }
        let bufferMinutes = max(
            0,
            Int(floor(arrivalDate.timeIntervalSince(transferStartDate) / 60))
        )
        return max(0, bufferMinutes - (travelMinutes ?? 0))
    }
}
