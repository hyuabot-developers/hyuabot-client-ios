//
//  UIColor.swift
//  hyuabot
//
//  Created by 이정인 on 12/10/24.
//
import SwiftUI

extension UIColor {
    convenience init (hexCode: String, alpha: CGFloat = 1.0) {
        let hexFormatted = hexCode.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        assert(hexFormatted.count == 6, "Invalid hex code")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}
