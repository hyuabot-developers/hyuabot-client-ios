//
//  HYUWidgetColor.swift
//  hyuabot
//

import SwiftUI
import UIKit

enum HYUWidgetColor {
    /// wbg; matches HYUColor.background
    static let background = dynamic(light: 0xFFFFFF, dark: 0x1C1C1E)
    /// wfg; matches HYUColor.foreground
    static let foreground = dynamic(light: 0x1D1D20, dark: 0xF5F5F7)
    /// wink2; matches HYUColor.ink2
    static let ink2 = dynamic(light: 0x3C3C42, dark: 0xD1D1D6)
    /// wmut; matches HYUColor.muted
    static let muted = dynamic(light: 0x6E6E76, dark: 0x98989F)
    /// wsep
    static let separator = dynamic(light: 0xECECEF, dark: 0x2F2F32)
    /// whero
    static let hero = dynamic(light: 0xF3F5F9, dark: 0x2A2A2D)
    /// wph
    static let placeholder = dynamic(light: 0xECEEF2, dark: 0x2C2C2F)
    /// wbrand; matches HYUColor.hanyangBlue
    static let brand = dynamic(light: 0x0E4A84, dark: 0xFFFFFF)
    /// wbrandFill
    static let brandFill = fixed(0x0E4A84)
    /// wimm; matches HYUColor.statusImminentFg
    static let imminent = dynamic(light: 0xC2410C, dark: 0xFF9F0A)
    /// wprice
    static let price = dynamic(light: 0x0E4A84, dark: 0x7FB2E5)
    /// wwarning
    static let warning = fixed(0xB42318)
    /// wopen
    static let open = fixed(0x7DB928)

    enum Route {
        /// wroute-dh; matches HYUColor.busRed
        static let shuttleDH = fixed(0xE60012)
        /// wroute-dy; matches HYUColor.hanyangOrange
        static let shuttleDY = fixed(0xF08100)
        /// wroute-dj; matches HYUColor.hanyangGreen
        static let shuttleDJ = fixed(0x7DB928)
        /// wroute-campus; matches HYUColor.busBlue
        static let shuttleC = dynamic(light: 0x0068B7, dark: 0x2F8EE6)
        /// wroute-line4; matches HYUColor.subwaySkyblue
        static let subwayLine4 = fixed(0x00A4E3)
        /// wroute-suin; matches HYUColor.subwayYellow
        static let subwaySuin = fixed(0xFABE00)
        /// wroute-bus; matches HYUColor.busGreen
        static let busGreen = fixed(0x33CC99)
    }

    static func destination(forKey key: String) -> Color {
        switch key {
        case "STATION": Route.shuttleDH
        case "TERMINAL": Route.shuttleDY
        case "JUNGANG": Route.shuttleDJ
        case "CAMPUS": Route.shuttleC
        default: muted
        }
    }

    static func route(forColorKey key: String) -> Color {
        switch key {
        case "line4": Route.subwayLine4
        case "suin": Route.subwaySuin
        default: Route.busGreen
        }
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? rgb(dark) : rgb(light)
        })
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat(Double((hex >> 16) & 0xFF) / 255),
            green: CGFloat(Double((hex >> 8) & 0xFF) / 255),
            blue: CGFloat(Double(hex & 0xFF) / 255),
            alpha: 1
        )
    }

    private static func fixed(_ hex: UInt32) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum HYUWidgetMetrics {
    static let contentPadding: CGFloat = 14
    static let heroRadius: CGFloat = 14
    static let heroPaddingHorizontal: CGFloat = 12
    static let heroPaddingVertical: CGFloat = 10
    static let dotSize: CGFloat = 8
    static let badgeHeight: CGFloat = 18
    static let badgeWidth: CGFloat = 34
    static let headerMinHeight: CGFloat = 18
    static let imminentMinutes = 5
}
