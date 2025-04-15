import SwiftUI

extension Font {
    static func godo(size: CGFloat, weight: UIFont.Weight) -> Font {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            return .custom("GodoB", size: size)
        case .light, .medium, .regular, .thin, .ultraLight:
            return .custom("GodoM", size: size)
        default:
            return .custom("GodoM", size: size)
        }
    }
}
