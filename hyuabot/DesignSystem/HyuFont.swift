import UIKit

enum HyuTextStyle {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case subheadlineBold
    case footnote
    case caption1
    case caption1Bold
    case caption2
    case tabBarTitle

    fileprivate var fontName: String {
        switch self {
        case .largeTitle, .title1, .title2, .title3, .headline, .subheadlineBold, .caption1Bold, .tabBarTitle:
            return "GodoB"
        case .body, .callout, .subheadline, .footnote, .caption1, .caption2:
            return "GodoM"
        }
    }

    fileprivate var size: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title1: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline, .body: return 17
        case .callout, .tabBarTitle: return 16
        case .subheadline, .subheadlineBold: return 15
        case .footnote: return 13
        case .caption1, .caption1Bold: return 12
        case .caption2: return 11
        }
    }

    fileprivate var textStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title1: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout, .tabBarTitle: return .callout
        case .subheadline, .subheadlineBold: return .subheadline
        case .footnote: return .footnote
        case .caption1, .caption1Bold: return .caption1
        case .caption2: return .caption2
        }
    }

    fileprivate var maximumPointSize: CGFloat? {
        switch self {
        case .caption1, .caption1Bold: return 22
        case .caption2: return 20
        case .tabBarTitle: return 22
        default: return nil
        }
    }
}

enum HyuFont {
    static func font(_ style: HyuTextStyle, compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        let baseFont = UIFont(name: style.fontName, size: style.size)!
        let metrics = UIFontMetrics(forTextStyle: style.textStyle)
        if let maximumPointSize = style.maximumPointSize {
            return metrics.scaledFont(for: baseFont, maximumPointSize: maximumPointSize, compatibleWith: traits)
        }
        return metrics.scaledFont(for: baseFont, compatibleWith: traits)
    }
}

extension UILabel {
    func apply(_ style: HyuTextStyle) {
        font = HyuFont.font(style)
        adjustsFontForContentSizeCategory = true
    }
}
