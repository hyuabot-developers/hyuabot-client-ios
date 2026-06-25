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
        fatalError()
    }

    func bind(data: Route) {
        backgroundColor = .clear
        routeData = data
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let data = routeData else { return }
        // Remove previous layer
        layer.sublayers?.filter { $0 !== lineLayer }.forEach { $0.removeFromSuperlayer() }
        subviews.forEach { $0.removeFromSuperview() }
        // Get values to draw
        let colWidth = bounds.width / CGFloat(allStops.count)
        let paddingWidth = colWidth / 2
        let centerY: CGFloat = 26
        let stopPositions: [CGFloat] = data.stops.map { stop in
            let index = allStops.firstIndex(of: stop) ?? 0
            return paddingWidth + CGFloat(index) * colWidth
        }
        // Draw Line
        for i in 0 ..< (data.stops.count - 1) {
            let path = UIBezierPath().then {
                $0.move(to: CGPoint(x: stopPositions[i], y: centerY))
                $0.addLine(to: CGPoint(x: stopPositions[i + 1], y: centerY))
            }
            CAShapeLayer().do {
                $0.path = path.cgPath
                $0.strokeColor = (i < data.currentStopIndex ? UIColor.lightGray : data.color).cgColor
                $0.lineWidth = 3
                layer.addSublayer($0)
            }
        }
        // Draw circle and label
        let font: UIFont = .godo(size: 11, weight: .bold)
        for i in 0 ..< data.stops.count {
            let x = stopPositions[i]
            let isPassed = i < data.currentStopIndex
            let isCurrent = i == data.currentStopIndex
            let color: UIColor = isPassed ? .lightGray : data.color
            // External Ring
            if isCurrent {
                CAShapeLayer().do {
                    $0.path = UIBezierPath(
                        arcCenter: CGPoint(x: x, y: centerY),
                        radius: 11,
                        startAngle: 0,
                        endAngle: .pi * 2,
                        clockwise: true
                    ).cgPath
                    $0.strokeColor = data.color.cgColor
                    $0.fillColor = UIColor.clear.cgColor
                    $0.lineWidth = 3
                    layer.addSublayer($0)
                }
            }
            // Draw Circle
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

            // Label
            if let label = data.labels[data.stops[i]], label > 0 {
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
    }
}
