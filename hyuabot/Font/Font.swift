import UIKit

extension UIFont {
    static func godo(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            return UIFont(name: "GodoB", size: size)!
        case .light, .medium, .regular, .thin, .ultraLight:
            return UIFont(name: "GodoM", size: size)!
        default:
            return UIFont(name: "GodoM", size: size)!
        }
    }
}
