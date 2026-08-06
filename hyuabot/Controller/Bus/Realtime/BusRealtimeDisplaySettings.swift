//
//  BusRealtimeDisplaySettings.swift
//  hyuabot
//

import Foundation

enum BusSeoulTargetStop: String, CaseIterable {
    case seocho
    case gyodae
    case gangnam
    case yangjae
    case yangjaeForest

    var title: String {
        switch self {
        case .seocho:
            String(localized: "bus.stop.seocho")
        case .gyodae:
            String(localized: "bus.stop.gyodae")
        case .gangnam:
            String(localized: "bus.stop.gangnam")
        case .yangjae:
            String(localized: "bus.stop.yangjae")
        case .yangjaeForest:
            String(localized: "bus.stop.yangjae_forest")
        }
    }

    var stopID: Int32 {
        switch self {
        case .seocho: 121_000_060
        case .gyodae: 121_000_929
        case .gangnam: 121_000_974
        case .yangjae: 121_000_970
        case .yangjaeForest: 121_000_220
        }
    }
}

enum BusRealtimeDisplaySettings {
    private static let showSecondaryEtaKey = "bus.showSecondaryEta"
    private static let seoulTargetStopKey = "bus.seoulTargetStop"

    static var showsSecondaryEta: Bool {
        get {
            guard UserDefaults.standard.object(forKey: showSecondaryEtaKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: showSecondaryEtaKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: showSecondaryEtaKey)
        }
    }

    static var seoulTargetStop: BusSeoulTargetStop {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: seoulTargetStopKey),
                  let target = BusSeoulTargetStop(rawValue: rawValue)
            else { return .gangnam }
            return target
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: seoulTargetStopKey)
        }
    }
}
