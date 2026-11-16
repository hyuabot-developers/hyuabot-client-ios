//
//  BusRealtimeLayout.swift
//  hyuabot
//

import Foundation

struct BusRealtimeLayout: Equatable {
    let defaultTab: BusRealtimeType
    let city: [BusRealtimeSectionSpec]
    let seoul: [BusRealtimeSectionSpec]
    let suwon: [BusRealtimeSectionSpec]

    func sections(for tab: BusRealtimeType) -> [BusRealtimeSectionSpec] {
        switch tab {
        case .city: city
        case .seoul: seoul
        case .suwon: suwon
        }
    }

    var allSections: [BusRealtimeSectionSpec] { city + seoul + suwon }

}

enum BusLocationGroupEvent: Equatable {
    case located(BusLocationGroup?)
    case authorizationUnavailable
    case locationFailed(isTransient: Bool)

    func nextGroup(current: BusLocationGroup?) -> BusLocationGroup? {
        switch self {
        case .located(let group): group
        case .authorizationUnavailable: nil
        case .locationFailed(isTransient: true): current
        case .locationFailed(isTransient: false): nil
        }
    }

}

extension BusRealtimeLayout {
    private static let route10dash1: Int32 = 216_000_068
    private static let route3102: Int32 = 216_000_061
    private static let route3100: Int32 = 216_000_026
    private static let route3101: Int32 = 216_000_043
    private static let route3100N: Int32 = 216_000_096
    private static let route7070: Int32 = 216_000_104
    private static let route9090: Int32 = 200_000_015
    private static let route50: Int32 = 216_000_075
    private static let route62: Int32 = 216_000_016
    private static let route80A: Int32 = 216_000_081
    private static let route80B: Int32 = 216_000_082
    private static let route4dash1: Int32 = 216_000_049

    private static func section(_ stop: Int32, _ routes: [(Int32, String)], destination: Int32? = nil) -> BusRealtimeSectionSpec {
        BusRealtimeSectionSpec(
            stopID: stop,
            routes: routes.map(\.0),
            routeNames: routes.map(\.1),
            stopName: BusStopName.title(for: stop),
            destinationStopID: destination
        )
    }

    private static func seoul3100Family(at stop: Int32, destination: Int32) -> BusRealtimeSectionSpec {
        section(stop, [(route3100, "3100"), (route3101, "3101"), (route3100N, "3100N")], destination: destination)
    }

    private static func uiwang3100Family() -> BusRealtimeSectionSpec {
        section(226_000_038, [(route3100, "3100"), (route3100N, "3100N")], destination: 216_000_048)
    }

    static func layout(for group: BusLocationGroup?, seoulTarget: BusSeoulTargetStop) -> BusRealtimeLayout {
        switch group {
        case .seocho?: return seoulStationLayout(stop: 121_000_060)
        case .yangjae?: return seoulStationLayout(stop: 121_000_970)
        case .gyodae?: return seoulStationLayout(stop: 121_000_929)
        case .gangnam?: return seoulStationLayout(stop: 121_000_974)
        case .yangjaeForest?: return seoulStationLayout(stop: 121_000_220)
        case .suwonStation?: return suwonStationLayout()
        case .uiwangTollgate?: return uiwangLayout()
        case .artist?: return cityOnlyLayout(artistCity(), target: seoulTarget.stopID)
        case .jungang?: return cityOnlyLayout(jungangCity(), target: seoulTarget.stopID)
        case .campus?: return cityOnlyLayout(campusCity(), target: seoulTarget.stopID)
        case .sangnoksuHandae?: return cityOnlyLayout(sangnoksuCity(), target: seoulTarget.stopID)
        case .kitech?: return kitechLayout(target: seoulTarget.stopID)
        case .dormitory?: return dormitoryLayout(target: seoulTarget.stopID)
        case .gwangmyeong?: return cityOnlyLayout(gwangmyeongCity(), target: seoulTarget.stopID)
        case nil: return defaultLayout(target: seoulTarget.stopID)
        }
    }

    private static func defaultLayout(target: Int32) -> BusRealtimeLayout {
        let targetStopID = target
        let defaultCity = [
            section(216_000_379, [(route10dash1, "10-1")], destination: 216_000_138),
            section(216_000_138, [(route10dash1, "10-1")], destination: 216_000_378)
        ]
        let defaultSeoul = [
            section(216_000_379, [(route3102, "3102")], destination: targetStopID),
            seoul3100Family(at: 216_000_719, destination: targetStopID)
        ]
        let defaultSuwon = [section(216_000_070, [(route7070, "7070"), (route9090, "9090")], destination: 202_000_208)]
        return BusRealtimeLayout(defaultTab: .city, city: defaultCity, seoul: defaultSeoul, suwon: defaultSuwon)
    }

    private static func cityOnlyLayout(_ city: [BusRealtimeSectionSpec], target: Int32) -> BusRealtimeLayout {
        let base = defaultLayout(target: target)
        return BusRealtimeLayout(defaultTab: .city, city: city, seoul: base.seoul, suwon: base.suwon)
    }

    private static func artistCity() -> [BusRealtimeSectionSpec] {
        [
                section(216_000_759, [(route50, "50")], destination: 213_000_487),
                section(216_000_074, [(route62, "62")]),
                section(216_000_077, [(route80B, "80B")])
        ]
    }

    private static func jungangCity() -> [BusRealtimeSectionSpec] {
        [section(217_000_264, [(route62, "62")]), section(217_000_140, [(route80B, "80B")])]
    }

    private static func campusCity() -> [BusRealtimeSectionSpec] {
        [
                section(216_000_379, [(route10dash1, "10-1")], destination: 216_000_138),
                section(216_000_152, [(route62, "62")])
        ]
    }

    private static func sangnoksuCity() -> [BusRealtimeSectionSpec] {
        [
                section(216_000_138, [(route10dash1, "10-1")], destination: 216_000_378),
                section(216_000_722, [(route4dash1, "4-1")], destination: 216_000_691)
        ]
    }

    private static func kitechLayout(target: Int32) -> BusRealtimeLayout {
        let base = defaultLayout(target: target)
        let city = [
                section(216_000_381, [(route10dash1, "10-1")], destination: 216_000_138),
                section(216_000_691, [(route4dash1, "4-1")])
        ]
        return BusRealtimeLayout(
            defaultTab: .city,
            city: city,
            seoul: seoulCampusSections(at: 216_000_381, target: target),
            suwon: base.suwon
        )
    }

    private static func dormitoryLayout(target: Int32) -> BusRealtimeLayout {
        let base = defaultLayout(target: target)
        let city = [
                section(216_000_383, [(route10dash1, "10-1")], destination: 216_000_138),
                section(216_000_028, [(route80A, "80A")])
        ]
        return BusRealtimeLayout(
            defaultTab: .city,
            city: city,
            seoul: seoulCampusSections(at: 216_000_383, target: target),
            suwon: base.suwon
        )
    }

    private static func seoulStationLayout(stop: Int32) -> BusRealtimeLayout {
        let base = defaultLayout(target: BusSeoulTargetStop.gangnam.stopID)
        return BusRealtimeLayout(defaultTab: .seoul, city: base.city, seoul: seoulGroupSections(at: stop), suwon: base.suwon)
    }

    private static func suwonStationLayout() -> BusRealtimeLayout {
        let base = defaultLayout(target: BusSeoulTargetStop.gangnam.stopID)
        let suwon = [section(202_000_106, [(route7070, "7070"), (route9090, "9090")], destination: 216_000_141)]
        return BusRealtimeLayout(defaultTab: .suwon, city: base.city, seoul: base.seoul, suwon: suwon)
    }

    private static func uiwangLayout() -> BusRealtimeLayout {
        let base = defaultLayout(target: BusSeoulTargetStop.gangnam.stopID)
        let seoul = [section(226_000_038, [(route3102, "3102")], destination: 216_000_378), uiwang3100Family()]
        return BusRealtimeLayout(defaultTab: .seoul, city: base.city, seoul: seoul, suwon: base.suwon)
    }

    private static func gwangmyeongCity() -> [BusRealtimeSectionSpec] {
        [section(213_000_487, [(route50, "50")], destination: 216_000_117)]
    }

    private static func seoulGroupSections(at stop: Int32) -> [BusRealtimeSectionSpec] {
        [
            section(stop, [(route3102, "3102")], destination: 216_000_378),
            seoul3100Family(at: stop, destination: 216_000_048)
        ]
    }

    private static func seoulCampusSections(at stop: Int32, target: Int32) -> [BusRealtimeSectionSpec] {
        [
            section(stop, [(route3102, "3102")], destination: target),
            seoul3100Family(at: 216_000_719, destination: target)
        ]
    }
}
