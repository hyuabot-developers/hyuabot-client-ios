import UIKit
import SnapKit
import Api

private extension UIColor {
    static let line4Color = UIColor(red: 0, green: 160 / 255, blue: 233 / 255, alpha: 1)
    static let suinColor = UIColor(red: 250 / 255, green: 190 / 255, blue: 0, alpha: 1)
    static let transferBusColor = UIColor(named: "busGreen") ?? .systemGreen
}

private enum TransferVehicleType {
    case subway
    case bus
}

private func localizedTransferMinuteText(_ minutes: Int) -> String {
    let language = Locale.current.language.languageCode?.identifier ?? "ko"
    guard !language.hasPrefix("ko") else {
        return String(format: String(localized: "transfer.bus.time.format"), minutes)
    }
    return "\(minutes)m"
}

private struct TransferTimelineEntry: Equatable {
    let destination: String
    let minutes: Int?
    let stops: Int?
    let locationLabel: String?
    let direction: Int
}

private struct TransferRow: Equatable {
    let name: String
    let targetName: String
    let color: UIColor
    let vehicleType: TransferVehicleType
    let timeline: [TransferTimelineEntry]

    var preferredHeight: CGFloat {
        switch vehicleType {
        case .subway:
            return 100
        case .bus:
            return 84
        }
    }

    static func == (lhs: TransferRow, rhs: TransferRow) -> Bool {
        lhs.name == rhs.name &&
            lhs.targetName == rhs.targetName &&
            lhs.vehicleType == rhs.vehicleType &&
            lhs.timeline == rhs.timeline
    }
}

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
            drawSubwayTrack(context: context, entriesByDirection: entriesByDirection, targetX: targetX, centerY: centerY, left: left, right: right, color: color)
        }

        for (direction, entries) in entriesByDirection {
            drawEntries(context: context, type: row.vehicleType, entries: Array(entries.prefix(2)), targetX: targetX, centerY: centerY, direction: direction, left: left, right: right, color: color)
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
            let edgeX = trackX(targetX: targetX, direction: direction, index: sideStations, clearance: targetClearance, step: step, left: left, right: right)
            if allFar {
                let solidEndX = trackX(targetX: targetX, direction: direction, index: sideStations - 1, clearance: targetClearance, step: step, left: left, right: right)
                drawLine(context: context, from: targetX, to: solidEndX, y: centerY)
                drawLine(context: context, from: solidEndX, to: edgeX, y: centerY, dashed: true)
            } else {
                drawLine(context: context, from: targetX, to: edgeX, y: centerY)
            }
            drawDots(context: context, targetX: targetX, step: step, count: sideStations, direction: direction, centerY: centerY, color: color, left: left, right: right, clearance: targetClearance)
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
            let edgeX = trackX(targetX: targetX, direction: direction, index: visibleBusStops, clearance: targetClearance, step: step, left: left, right: right)
            if allFar {
                let solidEndX = trackX(targetX: targetX, direction: direction, index: compressedNearBusStop, clearance: targetClearance, step: step, left: left, right: right)
                drawLine(context: context, from: targetX, to: solidEndX, y: centerY)
                drawLine(context: context, from: solidEndX, to: edgeX, y: centerY, dashed: true)
            } else {
                drawLine(context: context, from: targetX, to: edgeX, y: centerY)
            }
            drawDots(context: context, targetX: targetX, step: step, count: visibleBusStops, direction: direction, centerY: centerY, color: color, left: left, right: right, clearance: targetClearance)
        }

        for (index, entry) in entries.enumerated() {
            let stops = max(entry.stops ?? 1, 1)
            let vehicleX: CGFloat
            if type == .subway {
                let allFar = entries.count > 1 && entries.allSatisfy { ($0.stops ?? sideStations + 1) > sideStations }
                let visibleStops = allFar ? index + 2 : min(stops, sideStations)
                vehicleX = trackX(targetX: targetX, direction: direction, index: visibleStops, clearance: targetClearance, step: step, left: left, right: right)
            } else {
                let allFar = entries.count > 1 && entries.allSatisfy { ($0.stops ?? visibleBusStops) >= 6 }
                let visibleStops = allFar ? (index == 0 ? compressedNearBusStop : visibleBusStops) : min(stops, visibleBusStops)
                vehicleX = trackX(targetX: targetX, direction: direction, index: visibleStops, clearance: targetClearance, step: step, left: left, right: right)
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

    private func drawDots(context: CGContext, targetX: CGFloat, step: CGFloat, count: Int, direction: Int, centerY: CGFloat, color: UIColor, left: CGFloat, right: CGFloat, clearance: CGFloat) {
        for index in 1...count {
            let x = trackX(targetX: targetX, direction: direction, index: index, clearance: clearance, step: step, left: left, right: right)
            guard x >= left && x <= right else { continue }
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
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2), withAttributes: attributes)
    }

    private func drawBubble(entry: TransferTimelineEntry, type: TransferVehicleType, x: CGFloat, y: CGFloat, index: Int, total: Int) {
        let primary: String
        if type == .bus {
            let minuteText = entry.minutes.map { localizedTransferMinuteText($0) } ?? entry.destination
            let stopsText = entry.stops.map { String(format: String(localized: "transfer.bus.stops.suffix"), $0).trimmingCharacters(in: .whitespaces) }
            primary = [minuteText, stopsText].compactMap { $0 }.joined(separator: " ")
        } else {
            primary = String(format: String(localized: "subway.terminal.%@"), entry.destination)
        }
        let secondary: String? = {
            guard type != .bus else { return nil }
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
        let above: Bool
        if type == .subway {
            above = entry.direction < 0
        } else {
            above = total == 1 || index == 0
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
                .font: UIFont.systemFont(ofSize: lineIndex == 0 ? 10 : 8, weight: lineIndex == 0 ? .semibold : .regular),
                .foregroundColor: lineIndex == 0 ? UIColor.label : UIColor.secondaryLabel,
                .paragraphStyle: paragraph
            ]
            let lineRect = CGRect(x: rect.minX + 4, y: rect.minY + 3 + CGFloat(lineIndex * 12), width: rect.width - 8, height: 12)
            String(line.prefix(16)).draw(in: lineRect, withAttributes: attributes)
        }
    }

    private func bubbleWidth(for lines: [String], type: TransferVehicleType) -> CGFloat {
        let maxTextWidth = lines.enumerated().map { index, line in
            let font = UIFont.systemFont(ofSize: index == 0 ? 10 : 8, weight: index == 0 ? .semibold : .regular)
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

        let font = UIFont.systemFont(ofSize: 10, weight: .bold)
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
        let font = UIFont.systemFont(ofSize: 10, weight: .bold)
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

    private func trackX(targetX: CGFloat, direction: Int, index: Int, clearance: CGFloat, step: CGFloat, left: CGFloat, right: CGFloat) -> CGFloat {
        let distance = clearance + CGFloat(max(index - 1, 0)) * step
        return clamp(targetX + CGFloat(direction) * distance, left, right)
    }
}

private final class TransferRowView: UIView {
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .bold)
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ShuttleTransferInfoView: UIView {
    var onHeightChange: (() -> Void)?

    private let stopID: ShuttleStopEnum
    private var rows: [TransferRow] = []

    private let titleLabel = UILabel().then {
        $0.text = String(localized: "shuttle.transfer.section.title")
        $0.textColor = .white
        $0.textAlignment = .center
        $0.font = .godo(size: 16, weight: .bold)
        $0.backgroundColor = .hanyangBlue
    }
    private let rowStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
        $0.alignment = .fill
        $0.backgroundColor = .systemBackground
    }

    var preferredHeight: CGFloat {
        guard !rows.isEmpty else { return 0 }
        return 40 + rows.reduce(CGFloat(0)) { $0 + $1.preferredHeight } + 4
    }

    init(stopID: ShuttleStopEnum) {
        self.stopID = stopID
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(titleLabel)
        addSubview(rowStackView)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(40)
        }
        rowStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(2)
        }
    }

    func setup(data: ShuttleRealtimePageQuery.Data?) {
        guard let data else {
            guard rows.isEmpty else { return }
            render(rows: [])
            return
        }
        let rows: [TransferRow]
        switch stopID {
        case .dormiotryOut, .shuttlecockOut:
            rows = buildSubwayRows(data: data.subway) + buildBusRows(
                data: data.transferBus,
                stopSeq: 216000759,
                label: String(localized: "shuttle.transfer.bus50.to.kwangmyeong")
            )
        case .terminal:
            rows = buildBusRows(
                data: data.transferBus,
                stopSeq: 216000117,
                label: String(localized: "shuttle.transfer.bus50.to.ansan")
            )
        default:
            rows = []
        }
        guard !rows.isEmpty || self.rows.isEmpty else { return }
        render(rows: rows)
    }

    private func render(rows: [TransferRow]) {
        guard rows != self.rows else { return }
        self.rows = rows
        rowStackView.arrangedSubviews.forEach {
            rowStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rows.forEach { row in
            let rowView = TransferRowView(row: row)
            rowStackView.addArrangedSubview(rowView)
            rowView.snp.makeConstraints { make in
                make.height.equalTo(row.preferredHeight)
            }
        }
        isHidden = rows.isEmpty
        onHeightChange?()
    }

    private func buildSubwayRows(data: [ShuttleRealtimePageQuery.Data.Subway]) -> [TransferRow] {
        let lineInfo: [(stationID: String, name: String, color: UIColor)] = [
            ("K449", String(localized: "subway.line4"), .line4Color),
            ("K251", String(localized: "subway.suin"), .suinColor)
        ]
        return lineInfo.compactMap { info in
            guard let station = data.first(where: { $0.stationID == info.stationID }) else { return nil }
            let timeline = station.arrival.flatMap { group in
                group.entries
                    .filter { $0.isRealtime }
                    .prefix(1)
                    .map {
                        TransferTimelineEntry(
                            destination: localizedStationName(stationID: $0.terminal.stationID, fallback: $0.terminal.name),
                            minutes: $0.minutes,
                            stops: $0.stops,
                            locationLabel: nil,
                            direction: subwayDirection(group.direction)
                        )
                    }
            }
            guard !timeline.isEmpty else { return nil }
            return TransferRow(
                name: info.name,
                targetName: String(localized: "shuttle.transfer.target.station"),
                color: info.color,
                vehicleType: .subway,
                timeline: timeline
            )
        }
    }

    private func buildBusRows(data: [ShuttleRealtimePageQuery.Data.TransferBus], stopSeq: Int, label: String) -> [TransferRow] {
        let displayLabel = transferBusDisplayLabel(koreanLabel: label)
        let timeline = data
            .filter { $0.stop.seq == stopSeq }
            .flatMap { $0.arrival }
            .filter { $0.minutes != nil }
            .prefix(2)
            .map {
                TransferTimelineEntry(
                    destination: displayLabel,
                    minutes: $0.minutes,
                    stops: $0.stops,
                    locationLabel: $0.stops.map { String(format: String(localized: "transfer.bus.stops.suffix"), $0).trimmingCharacters(in: .whitespaces) },
                    direction: -1
                )
            }
        guard !timeline.isEmpty else { return [] }
        return [
            TransferRow(
                name: displayLabel,
                targetName: String(localized: "shuttle.transfer.target.terminal"),
                color: .transferBusColor,
                vehicleType: .bus,
                timeline: Array(timeline)
            )
        ]
    }

    private func transferBusDisplayLabel(koreanLabel: String) -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "ko"
        return language.hasPrefix("ko") ? koreanLabel : "50"
    }

    private func localizedStationName(stationID: String, fallback: String) -> String {
        let nameKey = "subway.station.\(stationID.lowercased())"
        let localized = String(localized: String.LocalizationValue(stringLiteral: nameKey))
        return localized == nameKey ? fallback : localized
    }

    private func subwayDirection(_ direction: String) -> Int {
        switch direction {
        case "down", "1":
            return 1
        default:
            return -1
        }
    }
}
