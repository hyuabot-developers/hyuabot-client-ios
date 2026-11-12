//
//  AppStartScreen.swift
//  hyuabot
//

import Foundation

enum AppStartScreen: Int, CaseIterable {
    case shuttle = 0
    case bus = 1
    case cafeteria = 3
    case subway = 2

    static let defaultsKey = "startScreen"

    static func current(defaults: UserDefaults = .standard) -> AppStartScreen {
        guard defaults.object(forKey: defaultsKey) != nil else { return .shuttle }
        return AppStartScreen(rawValue: defaults.integer(forKey: defaultsKey)) ?? .shuttle
    }

    static func save(_ screen: AppStartScreen, defaults: UserDefaults = .standard) {
        defaults.set(screen.rawValue, forKey: defaultsKey)
    }

    // Raw values match RootVC's tab order [shuttle, bus, subway, cafeteria, campus].
    var tabIndex: Int { rawValue }

    var title: String {
        switch self {
        case .shuttle: return String(localized: "tabbar.shuttle")
        case .bus: return String(localized: "tabbar.bus")
        case .cafeteria: return String(localized: "tabbar.cafeteria")
        case .subway: return String(localized: "tabbar.subway")
        }
    }
}
