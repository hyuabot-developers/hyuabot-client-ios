//
//  ShuttleRouteAdapter.swift
//  hyuabot
//

import SnapKit
import UIKit

struct ShuttleRoutePath {
    let color: UIColor
    let stops: [String]
    let currentStopIndex: Int
    let labels: [String: Int]
}

/// Horizontal route map: every route from the boarding stop to the destination is drawn on a single
/// line, and only the stretches where routes diverge branch onto their own lane.
final class ShuttleRouteAdapter: UIView {
    private struct Segment {
        let chipText: String
        let chipKind: ShuttleDisplayLogic.RouteChipKind
        let path: [(id: String, minutes: Int)]

        var total: Int {
            (path.last?.minutes ?? 0) - (path.first?.minutes ?? 0)
        }
    }

    private let routes: [ShuttleRoutePath]
    private let labels: [String.LocalizationValue]
    private let mergesByType: Bool
    private let legendStack = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.alignment = .center
        $0.spacing = 8
    }

    private let canvas = ShuttleRouteDiagramCanvas()

    init(routes: [ShuttleRoutePath], labels: [String.LocalizationValue], mergesByType: Bool = true, destination: String? = nil) {
        self.routes = routes
        self.labels = labels
        self.mergesByType = mergesByType
        super.init(frame: .zero)
        backgroundColor = .clear
        build(destination: destination)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func withDestination(_ destination: String?) -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(routes: routes, labels: labels, mergesByType: mergesByType, destination: destination)
    }

    private func segments(destination: String?) -> [Segment] {
        var result: [Segment] = []
        var seen = Set<String>()
        for (index, route) in routes.enumerated() {
            let text = chipText(route: route, index: index)
            guard seen.insert(text).inserted else { continue }
            let full = route.stops.compactMap { stop in route.labels[stop].map { (id: stop, minutes: $0) } }
            guard let boardingIndex = full.firstIndex(where: { $0.id == route.stops[route.currentStopIndex] }) else { continue }
            let destinationIndex = destination.flatMap { key in
                full.indices.first { $0 > boardingIndex && full[$0].id == key }
            } ?? full.count - 1
            guard destinationIndex > boardingIndex else { continue }
            result.append(Segment(
                chipText: text,
                chipKind: chipKind(route: route),
                path: Array(full[boardingIndex ... destinationIndex])
            ))
        }
        return result
    }

    private func chipKind(route: ShuttleRoutePath) -> ShuttleDisplayLogic.RouteChipKind {
        if route.color == .busRed {
            return .direct
        }
        if route.color == .hanyangGreen {
            return .jungang
        }
        return .circular
    }

    private func chipText(route: ShuttleRoutePath, index: Int) -> String {
        guard mergesByType else {
            return index < labels.count ? String(localized: labels[index]) : ""
        }
        if route.color == .busRed {
            return String(localized: "shuttle.type.direct")
        }
        if route.color == .hanyangGreen {
            return String(localized: "shuttle.type.jungang_station")
        }
        return String(localized: "shuttle.type.circular")
    }

    private func build(destination: String?) {
        let segments = segments(destination: destination)
        guard !segments.isEmpty else { return }
        for segment in segments {
            legendStack.addArrangedSubview(legendItem(segment))
        }
        addSubview(legendStack)
        addSubview(canvas)
        canvas.configure(model: diagramModel(segments: segments))
        legendStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        canvas.snp.makeConstraints { make in
            make.top.equalTo(legendStack.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(canvas.preferredHeight)
        }
    }

    private func legendItem(_ segment: Segment) -> UIView {
        let badge = BusRouteBadgeView(size: .shuttle)
        badge.configure(text: segment.chipText, fill: BusRouteBadgeView.shuttleFill(for: segment.chipKind))
        let minutes = UILabel().then {
            $0.font = SettingsStyle.monospacedDigitFont(13, bold: true)
            $0.textColor = SettingsStyle.Color.text
            $0.text = String(format: String(localized: "shuttle.route.total.%lld"), locale: Locale.current, segment.total)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        let row = UIStackView(arrangedSubviews: [badge, minutes])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center
        let container = UIView()
        container.addSubview(row)
        row.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        container.isAccessibilityElement = true
        container.accessibilityLabel = "\(segment.chipText) \(minutes.text ?? "")"
        return container
    }

    private struct EdgeUsage {
        let source: String
        let target: String
        var segments: [Segment]
    }

    private static func minuteText(isBoarding: Bool, offsets: [Int]) -> String {
        if isBoarding {
            return String(localized: "shuttle.route.boarding")
        }
        if let low = offsets.min(), let high = offsets.max(), low != high {
            return String(localized: "shuttle.route.plusRange.\(low).\(high)")
        }
        if let value = offsets.first {
            return String(format: String(localized: "shuttle.route.plus.%lld"), locale: Locale.current, value)
        }
        return ""
    }

    private func diagramModel(segments: [Segment]) -> ShuttleRouteDiagramCanvas.Model {
        let trunkColor = SettingsStyle.Color.link
        var order = segments[0].path.map(\.id)
        for segment in segments.dropFirst() {
            let ids = segment.path.map(\.id)
            for (position, id) in ids.enumerated() where !order.contains(id) {
                let successor = ids.dropFirst(position + 1).compactMap { order.firstIndex(of: $0) }.first
                order.insert(id, at: successor ?? order.count)
            }
        }
        let trunk = Set(segments[0].path.map(\.id))
        var lanes: [String: Int] = [:]
        var nextLane = 1
        for id in order {
            lanes[id] = trunk.contains(id) ? 0 : { defer { nextLane += 1 }; return nextLane }()
        }
        let branched = segments.count > 1
        var edgeUsers: [String: EdgeUsage] = [:]
        var edgeOrder: [String] = []
        for segment in segments {
            for index in 1 ..< segment.path.count {
                let source = segment.path[index - 1].id
                let target = segment.path[index].id
                let key = "\(source)>\(target)"
                if edgeUsers[key] == nil {
                    edgeUsers[key] = EdgeUsage(source: source, target: target, segments: [])
                    edgeOrder.append(key)
                }
                edgeUsers[key]?.segments.append(segment)
            }
        }
        let edges = edgeOrder.compactMap { key -> ShuttleRouteDiagramCanvas.Edge? in
            guard let edge = edgeUsers[key],
                  let from = order.firstIndex(of: edge.source), let to = order.firstIndex(of: edge.target) else { return nil }
            let color = edge.segments.count == 1 && branched
                ? BusRouteBadgeView.shuttleFill(for: edge.segments[0].chipKind)
                : trunkColor
            return .init(from: from, fromLane: lanes[edge.source] ?? 0, to: to, toLane: lanes[edge.target] ?? 0, color: color)
        }
        let boardingID = segments[0].path[0].id
        let nodes = order.enumerated().map { column, id -> ShuttleRouteDiagramCanvas.Node in
            let hits = segments.compactMap { segment -> (Segment, Int)? in
                segment.path.firstIndex { $0.id == id }.map { (segment, $0) }
            }
            let isBoarding = id == boardingID
            let isDestination = !isBoarding && hits.contains { $0.1 == $0.0.path.count - 1 }
            let color = hits.count == 1 && branched ? BusRouteBadgeView.shuttleFill(for: hits[0].0.chipKind) : trunkColor
            let offsets = hits.map { $0.0.path[$0.1].minutes - $0.0.path[0].minutes }
            let minuteText = Self.minuteText(isBoarding: isBoarding, offsets: offsets)
            return .init(
                column: column,
                lane: lanes[id] ?? 0,
                color: color,
                role: isBoarding ? .boarding : isDestination ? .destination : .stop,
                name: String(localized: String.LocalizationValue(id)),
                minutes: minuteText
            )
        }
        return .init(columns: order.count, maxLane: max(nextLane - 1, 0), nodes: nodes, edges: edges)
    }
}

final class ShuttleRouteDiagramCanvas: UIView {
    enum Role { case boarding, destination, stop }

    struct Node {
        let column: Int
        let lane: Int
        let color: UIColor
        let role: Role
        let name: String
        let minutes: String
    }

    struct Edge {
        let from: Int
        let fromLane: Int
        let to: Int
        let toLane: Int
        let color: UIColor
    }

    struct Model {
        let columns: Int
        let maxLane: Int
        let nodes: [Node]
        let edges: [Edge]
    }

    private static let laneTop: CGFloat = 6
    private static let laneHeight: CGFloat = 16
    private var model: Model?
    private var drawnWidth: CGFloat = 0

    var preferredHeight: CGFloat {
        guard let model else { return 0 }
        return Self.laneTop + CGFloat(model.maxLane) * Self.laneHeight + 14 + 30
    }

    func configure(model: Model) {
        self.model = model
        backgroundColor = .clear
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let model, bounds.width > 0, drawnWidth != bounds.width || layer.sublayers?.isEmpty != false else { return }
        drawnWidth = bounds.width
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        subviews.forEach { $0.removeFromSuperview() }
        let column = bounds.width / CGFloat(max(model.columns, 1))
        let xPosition = { (index: Int) in CGFloat(index) * column + column / 2 }
        let yPosition = { (lane: Int) in Self.laneTop + CGFloat(lane) * Self.laneHeight }
        for edge in model.edges {
            let layer = CAShapeLayer()
            layer.path = edgePath(edge, column: column, x: xPosition, y: yPosition).cgPath
            layer.strokeColor = edge.color.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 3
            layer.lineCap = .round
            self.layer.addSublayer(layer)
        }
        for node in model.nodes {
            addDot(node, center: CGPoint(x: xPosition(node.column), y: yPosition(node.lane)))
            addLabels(node, column: column, model: model)
        }
    }

    private func edgePath(_ edge: Edge, column: CGFloat, x: (Int) -> CGFloat, y: (Int) -> CGFloat) -> UIBezierPath {
        let x1 = x(edge.from), y1 = y(edge.fromLane), x2 = x(edge.to), y2 = y(edge.toLane)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x1, y: y1))
        if y1 == y2 {
            path.addLine(to: CGPoint(x: x2, y: y2))
        } else if y2 > y1 {
            let xm = x1 + column
            path.addCurve(
                to: CGPoint(x: xm, y: y2),
                controlPoint1: CGPoint(x: x1 + column / 2, y: y1),
                controlPoint2: CGPoint(x: x1 + column / 2, y: y2)
            )
            if xm < x2 {
                path.addLine(to: CGPoint(x: x2, y: y2))
            }
        } else {
            let x0 = x2 - column
            if x0 > x1 {
                path.addLine(to: CGPoint(x: x0, y: y1))
            }
            path.addCurve(
                to: CGPoint(x: x2, y: y2),
                controlPoint1: CGPoint(x: x0 + column / 2, y: y1),
                controlPoint2: CGPoint(x: x0 + column / 2, y: y2)
            )
        }
        return path
    }

    private func addDot(_ node: Node, center: CGPoint) {
        let radius: CGFloat = switch node.role {
        case .boarding: 5.5
        case .destination: 4.25
        case .stop: 3
        }
        let lineWidth: CGFloat = switch node.role {
        case .boarding: 0
        case .destination: 2.5
        case .stop: 2
        }
        let dot = CAShapeLayer()
        dot.path = UIBezierPath(
            arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true
        ).cgPath
        dot.fillColor = (node.role == .boarding ? node.color : SettingsStyle.Color.inset).cgColor
        dot.strokeColor = node.color.cgColor
        dot.lineWidth = lineWidth
        layer.addSublayer(dot)
    }

    private func addLabels(_ node: Node, column: CGFloat, model: Model) {
        let emphasized = node.role != .stop
        let name = UILabel().then {
            $0.font = SettingsStyle.font(12, bold: emphasized)
            $0.textColor = SettingsStyle.Color.text
            $0.textAlignment = .center
            $0.text = node.name
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.7
            $0.lineBreakMode = .byTruncatingTail
        }
        let minutes = UILabel().then {
            $0.font = SettingsStyle.monospacedDigitFont(11, bold: emphasized)
            $0.textColor = node.role == .boarding ? SettingsStyle.Color.link : SettingsStyle.Color.secondaryText
            $0.textAlignment = .center
            $0.text = node.minutes
        }
        let top = Self.laneTop + CGFloat(model.maxLane) * Self.laneHeight + 14
        let frameX = CGFloat(node.column) * column
        name.frame = CGRect(x: frameX, y: top, width: column, height: 16)
        minutes.frame = CGRect(x: frameX, y: top + 16, width: column, height: 14)
        name.isAccessibilityElement = false
        addSubview(name)
        addSubview(minutes)
    }
}
