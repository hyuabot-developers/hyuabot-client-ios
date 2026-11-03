//
//  WatchPalette.swift
//  hyuabot
//

import SwiftUI

enum WatchPalette {
    static let routeCircular = hex(0x2F8EE6)
    static let routeStation = hex(0xFF3B3B)
    static let routeTerminal = hex(0xF08100)
    static let routeJungang = hex(0x7DB928)
    static let imminent = hex(0xFF9F0A)
    static let warning = hex(0xFFB340)
    static let primaryButton = hex(0x0E4A84)
    static let secondaryButton = hex(0x2A2A2E)
    static let rowBackground = hex(0x1F1F22)
    static let accentBlue = hex(0x5FA3FF)
    static let secondaryText = hex(0x9A9AA1)
    static let messageText = hex(0xC9C9CE)
    static let chevron = hex(0x6E6E74)

    static func route(tag: String) -> Color {
        switch tag {
        case "C": routeCircular
        case "DH": routeStation
        case "DY": routeTerminal
        case "DJ": routeJungang
        default: secondaryText
        }
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
