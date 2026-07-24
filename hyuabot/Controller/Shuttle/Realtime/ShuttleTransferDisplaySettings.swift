//
//  ShuttleTransferDisplaySettings.swift
//  hyuabot
//

import Foundation

enum ShuttleSubwayTransferDestination: String, CaseIterable {
    case seoul
    case suwonYongin
    case incheon
    case oido
    case sosa

    var title: String {
        switch self {
        case .seoul:
            String(localized: "home.quick_settings.subway_destination.seoul")
        case .suwonYongin:
            String(localized: "home.quick_settings.subway_destination.suwon_yongin")
        case .incheon:
            String(localized: "home.quick_settings.subway_destination.incheon")
        case .oido:
            String(localized: "home.quick_settings.subway_destination.oido")
        case .sosa:
            String(localized: "home.quick_settings.subway_destination.sosa")
        }
    }

    func includes(stationID: String, direction: Int) -> Bool {
        switch self {
        case .seoul:
            stationID == "K449" || stationID == "K450" ? direction < 0 : false
        case .suwonYongin:
            stationID == "K251" && direction < 0
        case .incheon:
            stationID == "K251" && direction > 0
        case .oido, .sosa:
            stationID == "K449" || stationID == "K450" ? direction > 0 : false
        }
    }
}

enum ShuttleAlternativeDisplayMode: Int, CaseIterable {
    case automatic
    case always
    case hidden

    var title: String {
        switch self {
        case .automatic:
            String(localized: "shuttle.quick_settings.alternative.mode.automatic")
        case .always:
            String(localized: "shuttle.quick_settings.alternative.mode.always")
        case .hidden:
            String(localized: "shuttle.quick_settings.alternative.mode.hidden")
        }
    }
}

enum ShuttleTransferDisplaySettings {
    private static let showBusTransferKey = "home.showBus50Transfer"
    private static let showSubwayTransferKey = "home.showSubwayTransfer"
    private static let subwayDestinationKey = "home.subwayTransferDestination"
    private static let alternativeDisplayModeKey = "shuttle.alternativeDisplayMode"

    static var showsBusTransfer: Bool {
        get {
            guard UserDefaults.standard.object(forKey: showBusTransferKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: showBusTransferKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showBusTransferKey)
        }
    }

    static var showsSubwayTransfer: Bool {
        get {
            guard UserDefaults.standard.object(forKey: showSubwayTransferKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: showSubwayTransferKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showSubwayTransferKey)
        }
    }

    static var subwayDestination: ShuttleSubwayTransferDestination {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: subwayDestinationKey),
                  let destination = ShuttleSubwayTransferDestination(rawValue: rawValue)
            else { return .seoul }
            return destination
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: subwayDestinationKey)
        }
    }

    static var alternativeDisplayMode: ShuttleAlternativeDisplayMode {
        get {
            guard let mode = ShuttleAlternativeDisplayMode(
                rawValue: UserDefaults.standard.integer(forKey: alternativeDisplayModeKey)
            ) else { return .automatic }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: alternativeDisplayModeKey)
        }
    }
}
