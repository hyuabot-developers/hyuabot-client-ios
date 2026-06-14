import UIKit
import SnapKit
import Then

class BusRoute50MapView: UIView {
    private static let stopNames = ["안산방면", "한양대\nERICA", "한대앞역", "광명역"]
    private static let stopFractions: [CGFloat] = [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
    private static let hMargin: CGFloat = 28

    private let routeLine = UIView().then {
        $0.backgroundColor = .systemGray4
    }
    private let stopDots: [UIView] = (0..<4).map { _ in
        UIView().then {
            $0.backgroundColor = .systemBlue
            $0.layer.cornerRadius = 5
        }
    }
    private let stopLabelViews: [UILabel] = stopNames.map { name in
        UILabel().then {
            $0.text = name
            $0.font = .systemFont(ofSize: 9)
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.textColor = .secondaryLabel
        }
    }
    private var busDotViews: [UIView] = []

    private var ansanBoundStops: [Int] = []
    private var gwangmyeongBoundStops: [Int] = []

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 86)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        backgroundColor = .systemBackground
        addSubview(routeLine)
        stopDots.forEach { addSubview($0) }
        stopLabelViews.forEach { addSubview($0) }
        routeLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Self.hMargin)
            make.trailing.equalToSuperview().inset(Self.hMargin)
            make.height.equalTo(2)
            make.top.equalToSuperview().inset(30)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let startX = Self.hMargin
        let width = bounds.width - 2 * Self.hMargin
        let lineY: CGFloat = 31

        for (i, fraction) in Self.stopFractions.enumerated() {
            let x = startX + fraction * width
            stopDots[i].frame = CGRect(x: x - 5, y: lineY - 5, width: 10, height: 10)
            stopDots[i].layer.cornerRadius = 5
            let labelSize = stopLabelViews[i].sizeThatFits(CGSize(width: 50, height: 30))
            stopLabelViews[i].frame = CGRect(x: x - 25, y: lineY + 9, width: 50, height: labelSize.height)
        }

        busDotViews.forEach { $0.removeFromSuperview() }
        busDotViews.removeAll()

        for stops in ansanBoundStops.prefix(2) {
            let fraction = min(1.0 / 3.0 + CGFloat(stops) * (1.0 / 6.0), 1.0)
            let x = startX + fraction * width
            let dot = UIView().then {
                $0.backgroundColor = .systemBlue
                $0.layer.cornerRadius = 6
                $0.frame = CGRect(x: x - 6, y: lineY - 18, width: 12, height: 12)
            }
            let arrow = UILabel().then {
                $0.text = "←"
                $0.font = .systemFont(ofSize: 8, weight: .bold)
                $0.textColor = .systemBlue
                $0.sizeToFit()
                $0.center = CGPoint(x: x, y: lineY - 27)
            }
            addSubview(dot)
            addSubview(arrow)
            busDotViews.append(contentsOf: [dot, arrow])
        }

        for stops in gwangmyeongBoundStops.prefix(2) {
            let fraction = max(1.0 - CGFloat(stops) * (1.0 / 6.0), 0.0)
            let x = startX + fraction * width
            let dot = UIView().then {
                $0.backgroundColor = .hanyangOrange
                $0.layer.cornerRadius = 6
                $0.frame = CGRect(x: x - 6, y: lineY + 6, width: 12, height: 12)
            }
            let arrow = UILabel().then {
                $0.text = "→"
                $0.font = .systemFont(ofSize: 8, weight: .bold)
                $0.textColor = .hanyangOrange
                $0.sizeToFit()
                $0.center = CGPoint(x: x, y: lineY + 21)
            }
            addSubview(dot)
            addSubview(arrow)
            busDotViews.append(contentsOf: [dot, arrow])
        }
    }

    func updateBuses(ansanBound: [BusArrivalItem], gwangmyeong: [BusArrivalItem]) {
        ansanBoundStops = ansanBound.prefix(2).compactMap { $0.item.stops }
        gwangmyeongBoundStops = gwangmyeong.prefix(2).compactMap { $0.item.stops }
        UIView.animate(withDuration: 0.4) { self.setNeedsLayout(); self.layoutIfNeeded() }
    }
}
