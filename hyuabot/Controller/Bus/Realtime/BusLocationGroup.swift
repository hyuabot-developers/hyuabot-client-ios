//
//  BusLocationGroup.swift
//  hyuabot
//

import CoreLocation
import Foundation

enum BusLocationGroup: String, CaseIterable, Sendable {
    case seocho
    case yangjae
    case gyodae
    case gangnam
    case yangjaeForest
    case suwonStation
    case uiwangTollgate
    case artist
    case jungang
    case campus
    case sangnoksuHandae
    case kitech
    case dormitory
    case gwangmyeong

    struct Anchor: Equatable, Sendable {
        let latitude: Double
        let longitude: Double
    }

    static let matchRadiusMeters: Double = 2_500

    var anchors: [Anchor] {
        switch self {
        case .seocho:
            [Anchor(latitude: 37.4919667, longitude: 127.0086833)] // bus 121000060 서초역1번출구
        case .yangjae:
            [Anchor(latitude: 37.4827, longitude: 127.0355333)] // bus 121000970 양재역9번출구
        case .gyodae:
            [Anchor(latitude: 37.4940833, longitude: 127.01565)] // bus 121000929 교대역
        case .gangnam:
            [Anchor(latitude: 37.49575, longitude: 127.02835)] // bus 121000974 강남역우리은행
        case .yangjaeForest:
            [Anchor(latitude: 37.4708, longitude: 127.0383833)] // bus 121000220 매헌시민의숲.양재꽃시장
        case .suwonStation:
            [Anchor(latitude: 37.2673667, longitude: 127.0008833)] // bus 202000106 수원역7번출구.AK플라자
        case .uiwangTollgate:
            [Anchor(latitude: 37.3485167, longitude: 126.9845)] // bus 226000038 의왕톨게이트
        case .artist:
            [Anchor(latitude: 37.31945164682341, longitude: 126.8455453372041)] // shuttle stop terminal (예술인)
        case .jungang:
            [Anchor(latitude: 37.3147818, longitude: 126.8397399)] // shuttle stop jungang_stn
        case .campus:
            [
                Anchor(latitude: 37.29875417910844, longitude: 126.83784054072336), // shuttle shuttlecock_o
                Anchor(latitude: 37.2995897, longitude: 126.8372216), // shuttle shuttlecock_i
                Anchor(latitude: 37.3007667, longitude: 126.8372333), // bus 216000719 한양대정문
                Anchor(latitude: 37.3033333, longitude: 126.8442833) // bus 216000070 한양대입구
            ]
        case .sangnoksuHandae:
            [
                Anchor(latitude: 37.3023167, longitude: 126.8652667), // bus 216000138 상록수역3번출구건너편
                Anchor(latitude: 37.308494476826155, longitude: 126.85310236423418) // shuttle station (한대앞역)
            ]
        case .kitech:
            [Anchor(latitude: 37.2952667, longitude: 126.8384667)] // bus 216000381 한국생산기술연구원
        case .dormitory:
            [
                Anchor(latitude: 37.2939833, longitude: 126.83535), // bus 216000383 한양대기숙사앞
                Anchor(latitude: 37.29339607529377, longitude: 126.83630604103446) // shuttle dormitory_o
            ]
        case .gwangmyeong:
            [Anchor(latitude: 37.41755, longitude: 126.8843167)] // bus 213000487 KTX광명역1번출구
        }
    }

    static func resolve(latitude: Double, longitude: Double) -> BusLocationGroup? {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        var nearestGroup: BusLocationGroup?
        var nearestDistance = Double.infinity

        for group in allCases {
            for anchor in group.anchors {
                let distance = here.distance(from: CLLocation(latitude: anchor.latitude, longitude: anchor.longitude))
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearestGroup = group
                }
            }
        }

        return nearestDistance <= matchRadiusMeters ? nearestGroup : nil
    }
}
