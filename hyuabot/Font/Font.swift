import UIKit

extension UIFont {
    static func godo(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            UIFont(name: "GodoB", size: size)!
        case .light, .medium, .regular, .thin, .ultraLight:
            UIFont(name: "GodoM", size: size)!
        default:
            UIFont(name: "GodoM", size: size)!
        }
    }
}
