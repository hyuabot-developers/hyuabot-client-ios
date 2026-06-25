import SwiftUI

extension Font {
    static func godo(size: CGFloat, weight: UIFont.Weight) -> Font {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            .custom("GodoB", size: size)
        case .light, .medium, .regular, .thin, .ultraLight:
            .custom("GodoM", size: size)
        default:
            .custom("GodoM", size: size)
        }
    }
}
