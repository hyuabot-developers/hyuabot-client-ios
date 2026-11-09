//
//  Font.swift
//  hyuabot
//

import UIKit

extension UIFont {
    static func godo(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            UIFont(name: "GodoB", size: size) ?? .systemFont(ofSize: size, weight: weight)
        case .light, .medium, .regular, .thin, .ultraLight:
            UIFont(name: "GodoM", size: size) ?? .systemFont(ofSize: size, weight: weight)
        default:
            UIFont(name: "GodoM", size: size) ?? .systemFont(ofSize: size, weight: weight)
        }
    }
}
