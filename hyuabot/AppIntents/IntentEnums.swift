//
//  IntentEnums.swift
//  hyuabot
//

import AppIntents
import Foundation

struct BusIntentRouteStop: Equatable, Sendable {
    let route: Int32
    let stop: Int32
}

enum ShuttleStopOption: String, AppEnum, CaseIterable {
    case dormitory = "dormitory_o"
    case shuttlecock = "shuttlecock_o"
    case station
    case terminal
    case jungangStation = "jungang_stn"
    case shuttlecockIn = "shuttlecock_i"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.shuttle.stop.type")
    static let caseDisplayRepresentations: [ShuttleStopOption: DisplayRepresentation] = [
        .dormitory: DisplayRepresentation(title: "shuttle.stop.dormitory.out"),
        .shuttlecock: DisplayRepresentation(title: "shuttle.stop.shuttlecock.out"),
        .station: DisplayRepresentation(title: "shuttle.stop.station"),
        .terminal: DisplayRepresentation(title: "shuttle.stop.terminal"),
        .jungangStation: DisplayRepresentation(title: "shuttle.stop.jungang.station"),
        .shuttlecockIn: DisplayRepresentation(title: "shuttle.stop.shuttlecock.in"),
    ]

    var title: String {
        switch self {
        case .dormitory: String(localized: "shuttle.stop.dormitory.out")
        case .shuttlecock: String(localized: "shuttle.stop.shuttlecock.out")
        case .station: String(localized: "shuttle.stop.station")
        case .terminal: String(localized: "shuttle.stop.terminal")
        case .jungangStation: String(localized: "shuttle.stop.jungang.station")
        case .shuttlecockIn: String(localized: "shuttle.stop.shuttlecock.in")
        }
    }

    var coordinate: ShuttleGeoCoordinate {
        switch self {
        case .dormitory: ShuttleGeoCoordinate(latitude: 37.29339607529377, longitude: 126.83630604103446)
        case .shuttlecock: ShuttleGeoCoordinate(latitude: 37.29875417910844, longitude: 126.83784054072336)
        case .station: ShuttleGeoCoordinate(latitude: 37.309700971618255, longitude: 126.85207173389148)
        case .terminal: ShuttleGeoCoordinate(latitude: 37.319338173415936, longitude: 126.8455263115596)
        case .jungangStation: ShuttleGeoCoordinate(latitude: 37.31487247528457, longitude: 126.83963540399434)
        case .shuttlecockIn: ShuttleGeoCoordinate(latitude: 37.29869328231496, longitude: 126.8377767466817)
        }
    }
}

enum ShuttleDirectionOption: String, AppEnum, CaseIterable {
    case toCampus = "to_campus"
    case fromCampus = "from_campus"
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.shuttle.direction.type")
    static let caseDisplayRepresentations: [ShuttleDirectionOption: DisplayRepresentation] = [
        .toCampus: DisplayRepresentation(title: "intent.shuttle.direction.to.campus"),
        .fromCampus: DisplayRepresentation(title: "intent.shuttle.direction.from.campus"),
    ]
    var title: String {
        switch self {
        case .toCampus: String(localized: "intent.shuttle.direction.to.campus")
        case .fromCampus: String(localized: "intent.shuttle.direction.from.campus")
        }
    }
    func matches(destination: String) -> Bool {
        switch self {
        case .toCampus: destination == "CAMPUS"
        case .fromCampus: destination != "CAMPUS"
        }
    }
}

enum CafeteriaMealOption: String, AppEnum, CaseIterable {
    case breakfast
    case lunch
    case dinner
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.cafeteria.meal.type")
    static let caseDisplayRepresentations: [CafeteriaMealOption: DisplayRepresentation] = [
        .breakfast: DisplayRepresentation(title: "cafeteria.breakfast"),
        .lunch: DisplayRepresentation(title: "cafeteria.lunch"),
        .dinner: DisplayRepresentation(title: "cafeteria.dinner"),
    ]
    var title: String {
        switch self {
        case .breakfast: String(localized: "cafeteria.breakfast")
        case .lunch: String(localized: "cafeteria.lunch")
        case .dinner: String(localized: "cafeteria.dinner")
        }
    }
    var menuMarker: String {
        switch self {
        case .breakfast: "조식"
        case .lunch: "중식"
        case .dinner: "석식"
        }
    }
    static func current(at date: Date, calendar: Calendar) -> CafeteriaMealOption {
        let hour = calendar.component(.hour, from: date)
        if hour < 10 { return .breakfast }
        if hour < 15 { return .lunch }
        return .dinner
    }
}

enum CafeteriaDayOption: String, AppEnum, CaseIterable {
    case today
    case tomorrow
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.cafeteria.day.type")
    static let caseDisplayRepresentations: [CafeteriaDayOption: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "intent.cafeteria.day.today"),
        .tomorrow: DisplayRepresentation(title: "intent.cafeteria.day.tomorrow"),
    ]
    var title: String {
        switch self {
        case .today: String(localized: "intent.cafeteria.day.today")
        case .tomorrow: String(localized: "intent.cafeteria.day.tomorrow")
        }
    }
    var dayOffset: Int {
        switch self {
        case .today: 0
        case .tomorrow: 1
        }
    }
}

enum CafeteriaRestaurantOption: String, AppEnum, CaseIterable {
    case studentUnion = "1"
    case lifeScience = "2"
    case materialsScience = "4"
    case residenceHall1 = "6"
    case residenceHall2 = "7"
    case haengwonPark = "8"
    case staff = "11"
    case student = "12"
    case changui = "13"
    case foodCourt = "14"
    case startupCenter = "15"
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.cafeteria.restaurant.type")
    static let caseDisplayRepresentations: [CafeteriaRestaurantOption: DisplayRepresentation] = [
        .studentUnion: DisplayRepresentation(title: "cafeteria.title.1"),
        .lifeScience: DisplayRepresentation(title: "cafeteria.title.2"),
        .materialsScience: DisplayRepresentation(title: "cafeteria.title.4"),
        .residenceHall1: DisplayRepresentation(title: "cafeteria.title.6"),
        .residenceHall2: DisplayRepresentation(title: "cafeteria.title.7"),
        .haengwonPark: DisplayRepresentation(title: "cafeteria.title.8"),
        .staff: DisplayRepresentation(title: "cafeteria.title.11"),
        .student: DisplayRepresentation(title: "cafeteria.title.12"),
        .changui: DisplayRepresentation(title: "cafeteria.title.13"),
        .foodCourt: DisplayRepresentation(title: "cafeteria.title.14"),
        .startupCenter: DisplayRepresentation(title: "cafeteria.title.15"),
    ]
    var seq: Int { Int(rawValue) ?? 0 }
    var campusID: Int { seq < 10 ? 1 : 2 }
    var title: String {
        switch self {
        case .studentUnion: String(localized: "cafeteria.title.1")
        case .lifeScience: String(localized: "cafeteria.title.2")
        case .materialsScience: String(localized: "cafeteria.title.4")
        case .residenceHall1: String(localized: "cafeteria.title.6")
        case .residenceHall2: String(localized: "cafeteria.title.7")
        case .haengwonPark: String(localized: "cafeteria.title.8")
        case .staff: String(localized: "cafeteria.title.11")
        case .student: String(localized: "cafeteria.title.12")
        case .changui: String(localized: "cafeteria.title.13")
        case .foodCourt: String(localized: "cafeteria.title.14")
        case .startupCenter: String(localized: "cafeteria.title.15")
        }
    }
}

enum SubwayLineOption: String, AppEnum, CaseIterable {
    case line4 = "K449"
    case suinBundang = "K251"
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.subway.line.type")
    static let caseDisplayRepresentations: [SubwayLineOption: DisplayRepresentation] = [
        .line4: DisplayRepresentation(title: "intent.subway.line.line4"),
        .suinBundang: DisplayRepresentation(title: "intent.subway.line.suin"),
    ]
    var title: String {
        switch self {
        case .line4: String(localized: "intent.subway.line.line4")
        case .suinBundang: String(localized: "intent.subway.line.suin")
        }
    }
    var stationID: String { rawValue }
}

enum SubwayDirectionOption: String, AppEnum, CaseIterable {
    case up
    case down
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.subway.direction.type")
    static let caseDisplayRepresentations: [SubwayDirectionOption: DisplayRepresentation] = [
        .up: DisplayRepresentation(title: "intent.subway.direction.up"),
        .down: DisplayRepresentation(title: "intent.subway.direction.down"),
    ]
    var title: String {
        switch self {
        case .up: String(localized: "intent.subway.direction.up")
        case .down: String(localized: "intent.subway.direction.down")
        }
    }
}

enum BusRouteOption: String, AppEnum, CaseIterable {
    case route10Dash1 = "10-1"
    case route3102 = "3102"
    case route3100 = "3100"
    case route3101 = "3101"
    case route3100N = "3100N"
    case route7070 = "7070"
    case route9090 = "9090"
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "intent.bus.route.type")
    static let spokenSynonyms: [BusRouteOption: [String]] = [
        .route10Dash1: ["10-1", "10-1번", "십의 일", "십다시일"],
        .route3102: ["3102", "3102번", "삼천백이", "삼천백이번", "삼일공이"],
        .route3100: ["3100", "3100번", "삼천백", "삼천백번", "삼일공공"],
        .route3101: ["3101", "3101번", "삼천백일", "삼천백일번", "삼일공일"],
        .route3100N: ["3100N", "3100 N", "3100 엔", "3100N번", "삼천백 엔"],
        .route7070: ["7070", "7070번", "칠공칠공", "칠천칠십", "칠천칠십번"],
        .route9090: ["9090", "9090번", "구공구공", "구천구십", "구천구십번"],
    ]
    private static func localizedSynonyms(for route: BusRouteOption) -> [LocalizedStringResource] {
        spokenSynonyms[route, default: []].map { LocalizedStringResource(stringLiteral: $0) }
    }
    static let caseDisplayRepresentations: [BusRouteOption: DisplayRepresentation] = [
        .route10Dash1: DisplayRepresentation(title: "intent.bus.route.10-1", synonyms: localizedSynonyms(for: .route10Dash1)),
        .route3102: DisplayRepresentation(title: "intent.bus.route.3102", synonyms: localizedSynonyms(for: .route3102)),
        .route3100: DisplayRepresentation(title: "intent.bus.route.3100", synonyms: localizedSynonyms(for: .route3100)),
        .route3101: DisplayRepresentation(title: "intent.bus.route.3101", synonyms: localizedSynonyms(for: .route3101)),
        .route3100N: DisplayRepresentation(title: "intent.bus.route.3100N", synonyms: localizedSynonyms(for: .route3100N)),
        .route7070: DisplayRepresentation(title: "intent.bus.route.7070", synonyms: localizedSynonyms(for: .route7070)),
        .route9090: DisplayRepresentation(title: "intent.bus.route.9090", synonyms: localizedSynonyms(for: .route9090)),
    ]
    var title: String {
        switch self {
        case .route10Dash1: String(localized: "intent.bus.route.10-1")
        case .route3102: String(localized: "intent.bus.route.3102")
        case .route3100: String(localized: "intent.bus.route.3100")
        case .route3101: String(localized: "intent.bus.route.3101")
        case .route3100N: String(localized: "intent.bus.route.3100N")
        case .route7070: String(localized: "intent.bus.route.7070")
        case .route9090: String(localized: "intent.bus.route.9090")
        }
    }
    var routeName: String { rawValue }
    var routeStops: [BusIntentRouteStop] {
        switch self {
        case .route10Dash1: [BusIntentRouteStop(route: 216_000_068, stop: 216_000_379)]
        case .route3102: [BusIntentRouteStop(route: 216_000_061, stop: 216_000_379)]
        case .route3100, .route3101, .route3100N: [
            BusIntentRouteStop(route: 216_000_043, stop: 216_000_719),
            BusIntentRouteStop(route: 216_000_026, stop: 216_000_719),
            BusIntentRouteStop(route: 216_000_096, stop: 216_000_719)
        ]
        case .route7070, .route9090: [
            BusIntentRouteStop(route: 216_000_104, stop: 216_000_070),
            BusIntentRouteStop(route: 200_000_015, stop: 216_000_070)
        ]
        }
    }
    static var defaultRouteStops: [BusIntentRouteStop] {
        var stops: [BusIntentRouteStop] = []
        for stop in allCases.flatMap(\.routeStops) where !stops.contains(stop) { stops.append(stop) }
        return stops
    }
}
