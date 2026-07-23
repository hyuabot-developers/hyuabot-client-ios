//
//  AppDomainLogic.swift
//  hyuabot
//

import Foundation
import UIKit

enum HomeWeatherPrecipitationKind: String, Equatable {
    case rain = "RAIN"
    case sleet = "SLEET"
    case snow = "SNOW"
}

enum HomeWeatherTitleStyle: Equatable {
    case clear
    case cloudy
    case hot
    case cold
    case precipitationNow(HomeWeatherPrecipitationKind)
    case precipitationLater(HomeWeatherPrecipitationKind)
    case precipitationToday(HomeWeatherPrecipitationKind)

    var localizationKey: String.LocalizationValue {
        switch self {
        case .clear: "home.weather.clear.title"
        case .cloudy: "home.weather.cloudy.title"
        case .hot: "home.weather.hot.title"
        case .cold: "home.weather.cold.title"
        case let .precipitationNow(kind):
            switch kind {
            case .rain: "home.weather.rain.now.title"
            case .sleet: "home.weather.sleet.now.title"
            case .snow: "home.weather.snow.now.title"
            }
        case let .precipitationLater(kind):
            switch kind {
            case .rain: "home.weather.rain.start.title"
            case .sleet: "home.weather.sleet.start.title"
            case .snow: "home.weather.snow.start.title"
            }
        case let .precipitationToday(kind):
            switch kind {
            case .rain: "home.weather.rain.title"
            case .sleet: "home.weather.sleet.title"
            case .snow: "home.weather.snow.title"
            }
        }
    }
}

enum HomeWeatherDisplayLogic {
    static func titleStyle(
        condition: String,
        currentTemperature: Double?,
        maximumTemperature: Double?,
        precipitationType: String,
        precipitationStartAt: Date?,
        now: Date = .now
    ) -> HomeWeatherTitleStyle {
        if let kind = HomeWeatherPrecipitationKind(rawValue: precipitationType) {
            guard let precipitationStartAt else { return .precipitationToday(kind) }
            return precipitationStartAt <= now ? .precipitationNow(kind) : .precipitationLater(kind)
        }
        if let maximumTemperature, maximumTemperature >= 32 {
            return .hot
        }
        if let currentTemperature, currentTemperature <= -5 {
            return .cold
        }
        return condition == "CLEAR" ? .clear : .cloudy
    }
}

enum CafeteriaStatus: Equatable {
    case noMenu
    case soon
    case open
    case closed

    var localizationKey: String.LocalizationValue {
        switch self {
        case .noMenu: "cafeteria.status.no.menu"
        case .soon: "cafeteria.status.soon"
        case .open: "cafeteria.status.open"
        case .closed: "cafeteria.status.closed"
        }
    }
}

enum CafeteriaStatusResolver {
    static func status(runningTime: String, hasMenu: Bool, now: Date = Date(), calendar: Calendar = .current) -> CafeteriaStatus? {
        if !hasMenu { return .noMenu }
        let minutes = runningTime.matches(of: /\d{1,2}:\d{2}/)
            .prefix(2)
            .compactMap { minutesSinceStartOfDay(String($0.output)) }
        guard minutes.count == 2 else { return nil }
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        if nowMinutes < minutes[0] { return .soon }
        if nowMinutes > minutes[1] { return .closed }
        return .open
    }

    private static func minutesSinceStartOfDay(_ value: String) -> Int? {
        let parts = value.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0 ... 23).contains(hour),
              (0 ... 59).contains(minute) else { return nil }
        return hour * 60 + minute
    }
}

enum ReadingRoomDisplayLogic {
    static func occupancyRatio(occupied: Int, active: Int) -> Float {
        guard active > 0 else { return 0 }
        return Float(occupied) / Float(active)
    }

    static func occupancyColor(progress: Float) -> UIColor {
        if progress >= 0.9 { return .systemRed }
        if progress >= 0.7 { return .systemOrange }
        return .systemGreen
    }

    static func localizationKey(for id: Int) -> String.LocalizationValue {
        switch id {
        case 1: "reading_room_1"
        case 53: "reading_room_53"
        case 54: "reading_room_54"
        case 55: "reading_room_55"
        case 56: "reading_room_56"
        case 61: "reading_room_61"
        case 63: "reading_room_63"
        case 131: "reading_room_131"
        case 132: "reading_room_132"
        default: "Unknown"
        }
    }
}

enum SettingsLogic {
    static func campusID(for key: String.LocalizationValue) -> Int {
        key == "campus.seoul" ? 1 : 2
    }

    static func campusKey(for id: Int) -> String.LocalizationValue {
        id == 1 ? "campus.seoul" : "campus.erica"
    }

    static func themeID(for key: String.LocalizationValue) -> Int {
        switch key {
        case "theme.system": 0
        case "theme.light": 1
        default: 2
        }
    }

    static func themeKey(for id: Int) -> String.LocalizationValue {
        switch id {
        case 0: "theme.system"
        case 1: "theme.light"
        default: "theme.dark"
        }
    }
}

enum MapSearchLogic {
    static func isSearchResultVisible(keyword: String) -> Bool {
        !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func rowCount(for items: [some Any]) -> Int {
        max(1, items.count)
    }
}
