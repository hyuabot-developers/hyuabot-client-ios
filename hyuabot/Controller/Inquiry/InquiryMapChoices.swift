//
//  InquiryMapChoices.swift
//  hyuabot
//

import CoreLocation
import MapKit
import UIKit

@MainActor
enum InquiryMapChoices {
    private struct Candidate {
        let name: String
        let symbol: String
        let color: UIColor
        let url: URL?
    }

    static func choices(name: String, coordinate: CLLocationCoordinate2D) -> [CommuterMapChoice] {
        let appleItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        appleItem.name = name
        var choices = [CommuterMapChoice(
            name: String(localized: "commuter.map.apple"), symbol: "map.fill",
            brandColor: SettingsStyle.Color.link
        ) {
            guard !appleItem.openInMaps() else { return }
            var components = URLComponents(string: "http://maps.apple.com/")
            components?.queryItems = [
                URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
                URLQueryItem(name: "q", value: name),
            ]
            if let url = components?.url { UIApplication.shared.open(url) }
        }]

        var naver = URLComponents(string: "nmap://route/public")
        naver?.queryItems = [
            URLQueryItem(name: "dlat", value: String(coordinate.latitude)),
            URLQueryItem(name: "dlng", value: String(coordinate.longitude)),
            URLQueryItem(name: "dname", value: name),
            URLQueryItem(name: "appname", value: "net.jaram.hyuabot"),
        ]
        let coordinateString = "\(coordinate.latitude),\(coordinate.longitude)"
        let candidates = [
            Candidate(
                name: String(localized: "commuter.map.naver"), symbol: "N",
                color: UIColor(red: 3 / 255, green: 199 / 255, blue: 90 / 255, alpha: 1), url: naver?.url
            ),
            Candidate(
                name: String(localized: "commuter.map.kakao"), symbol: "K",
                color: UIColor(red: 254 / 255, green: 229 / 255, blue: 0, alpha: 1),
                url: URL(string: "kakaomap://route?ep=\(coordinateString)&by=PUBLICTRANSIT")
            ),
            Candidate(
                name: String(localized: "commuter.map.google"), symbol: "G",
                color: UIColor(red: 66 / 255, green: 133 / 255, blue: 244 / 255, alpha: 1),
                url: URL(string: "comgooglemaps://?daddr=\(coordinateString)&directionsmode=transit")
            )
        ]
        choices += candidates.compactMap { candidate in
            guard let url = candidate.url, UIApplication.shared.canOpenURL(url) else { return nil }
            return CommuterMapChoice(name: candidate.name, symbol: candidate.symbol, brandColor: candidate.color) {
                UIApplication.shared.open(url) { success in
                    if !success {
                        guard !appleItem.openInMaps() else { return }
                        var components = URLComponents(string: "http://maps.apple.com/")
                        components?.queryItems = [
                            URLQueryItem(name: "ll", value: coordinateString),
                            URLQueryItem(name: "q", value: name),
                        ]
                        if let fallbackURL = components?.url { UIApplication.shared.open(fallbackURL) }
                    }
                }
            }
        }
        return choices
    }
}
