//
//  ShuttleRouteItemView.swift
//  hyuabot
//

import UIKit

class ShuttleRouteItemView: UIView {
    struct Route {
        let color: UIColor
        let stops: [String]
        let currentStopIndex: Int
        let labels: [String: Int]
    }

    private let allStops: [String] = [
        "shuttle.stop.dormitory.out",
        "shuttle.stop.shuttlecock.out",
        "shuttle.stop.station",
        "shuttle.stop.terminal",
        "shuttle.stop.jungang.station",
        "shuttle.stop.shuttlecock.in",
        "shuttle.stop.dormitory.in"
    ]
    private let lineLayer = CAShapeLayer()
    private let circleContainer = UIView()
    private let passedColor = UIColor.lightGray
    private var routeData: Route?
    private var colWidth: CGFloat = 0
    private var centerY: CGFloat = 26
    private var paddingWidth: CGFloat = 0
    private var stopPositions: [CGFloat] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(lineLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(data: Route) {
        backgroundColor = .clear
        routeData = data
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let data = routeData else { return }
        layer.sublayers?.filter { $0 !== lineLayer }.forEach { $0.removeFromSuperlayer() }
        subviews.forEach { $0.removeFromSuperview() }

        let columnWidth = bounds.width / CGFloat(allStops.count)
        let paddingWidth = columnWidth / 2
        let centerY: CGFloat = 26
        let stopPositions = data.stops.map { stop in
            let index = allStops.firstIndex(of: stop) ?? 0
            return paddingWidth + CGFloat(index) * columnWidth
        }
        drawRouteLines(data: data, stopPositions: stopPositions, centerY: centerY)
        drawStops(data: data, stopPositions: stopPositions, centerY: centerY)
    }

    private func drawRouteLines(data: Route, stopPositions: [CGFloat], centerY: CGFloat) {
        guard data.stops.count > 1 else { return }
        for index in 0 ..< (data.stops.count - 1) {
            let path = UIBezierPath().then {
                $0.move(to: CGPoint(x: stopPositions[index], y: centerY))
                $0.addLine(to: CGPoint(x: stopPositions[index + 1], y: centerY))
            }
            CAShapeLayer().do {
                $0.path = path.cgPath
                $0.strokeColor = (index < data.currentStopIndex ? UIColor.lightGray : data.color).cgColor
                $0.lineWidth = 3
                layer.addSublayer($0)
            }
        }
    }

    private func drawStops(data: Route, stopPositions: [CGFloat], centerY: CGFloat) {
        let font: UIFont = .godo(size: 11, weight: .bold)
        for index in 0 ..< data.stops.count {
            let x = stopPositions[index]
            let isPassed = index < data.currentStopIndex
            let isCurrent = index == data.currentStopIndex
            let color: UIColor = isPassed ? .lightGray : data.color
            drawStopRingIfCurrent(isCurrent, x: x, centerY: centerY, color: data.color)
            drawStopCircle(x: x, centerY: centerY, color: color, isCurrent: isCurrent)
            drawStopLabelIfPresent(data: data, index: index, x: x, centerY: centerY, font: font, isPassed: isPassed)
        }
    }

    private func drawStopRingIfCurrent(_ isCurrent: Bool, x: CGFloat, centerY: CGFloat, color: UIColor) {
        guard isCurrent else { return }
        CAShapeLayer().do {
            $0.path = UIBezierPath(
                arcCenter: CGPoint(x: x, y: centerY),
                radius: 11,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            ).cgPath
            $0.strokeColor = color.cgColor
            $0.fillColor = UIColor.clear.cgColor
            $0.lineWidth = 3
            layer.addSublayer($0)
        }
    }

    private func drawStopCircle(x: CGFloat, centerY: CGFloat, color: UIColor, isCurrent: Bool) {
        CAShapeLayer().do {
            $0.path = UIBezierPath(
                arcCenter: CGPoint(x: x, y: centerY),
                radius: isCurrent ? 9 : 6,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            ).cgPath
            $0.fillColor = color.cgColor
            layer.addSublayer($0)
        }
    }

    private func drawStopLabelIfPresent(
        data: Route,
        index: Int,
        x: CGFloat,
        centerY: CGFloat,
        font: UIFont,
        isPassed: Bool
    ) {
        guard let label = data.labels[data.stops[index]], label > 0 else { return }
        let text = String(format: String(localized: "shuttle.realtime.duration.format.%lld"), label)
        CATextLayer().do {
            $0.string = text
            $0.font = font
            $0.fontSize = 11
            $0.foregroundColor = (isPassed ? UIColor.gray : UIColor.white).cgColor
            $0.alignmentMode = .center
            $0.contentsScale = UIScreen.main.scale
            let textSize = (text as NSString).size(withAttributes: [.font: font])
            $0.frame = CGRect(x: x - textSize.width / 2, y: centerY + 14, width: textSize.width, height: textSize.height)
            layer.addSublayer($0)
        }
    }
}
