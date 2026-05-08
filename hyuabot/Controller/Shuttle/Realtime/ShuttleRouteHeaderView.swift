import UIKit

class ShuttleRouteHeaderView: UIView {
    private let allStops: [String.LocalizationValue] = [
        "shuttle.stop.dormitory.out",
        "shuttle.stop.shuttlecock.out",
        "shuttle.stop.station",
        "shuttle.stop.terminal",
        "shuttle.stop.jungang.station",
        "shuttle.stop.shuttlecock.in",
        "shuttle.stop.dormitory.in",
    ]
    
    override func draw(_ rect: CGRect) {
        let colWidth = rect.width / CGFloat(allStops.count)
        let paddingWidth = colWidth / 2
        
        let paragraphStyle = NSMutableParagraphStyle().then {
            $0.alignment = .center
            $0.lineBreakMode = .byWordWrapping
        }
        let font = UIFont.godo(size: 12, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        
        allStops.enumerated().forEach { index, stop in
            let text = String(localized: stop).replacingOccurrences(of: " ", with: "\n")
            let x = paddingWidth + CGFloat(index) * colWidth
            let textSize = (text as NSString).boundingRect(with: CGSize(width: colWidth, height: rect.height), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil).size
            let textRect = CGRect(x: x - colWidth / 2, y: rect.height - textSize.height, width: colWidth, height: textSize.height)
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
}
