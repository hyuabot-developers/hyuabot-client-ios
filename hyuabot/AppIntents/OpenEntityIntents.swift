//
//  OpenEntityIntents.swift
//  hyuabot
//

import AppIntents
import Foundation
import UIKit

enum OpenEntityLogic {
    static func url(for entity: ShuttleArrivalEntity) -> URL {
        HyuabotSearchLogic.url(for: .shuttle(stop: ShuttleStopOption(rawValue: entity.id)))
    }

    static func url(for entity: SubwayArrivalEntity) -> URL {
        HyuabotSearchLogic.url(for: .subway(line: SubwayLineOption.allCases.first { $0.stationID == entity.id }))
    }

    static func url(for entity: BusArrivalEntity) -> URL {
        HyuabotSearchLogic.url(for: .bus(route: BusRouteOption(rawValue: entity.id)))
    }

    static func url(for entity: CafeteriaMenuEntity, now: Foundation.Date = .now) -> URL {
        let calendar = IntentClock.seoulCalendar
        let tomorrow = HyuabotSearchLogic.tomorrowDate(from: now)
        let day: CafeteriaDayOption? = entity.date == IntentClock.dateString(from: tomorrow, calendar: calendar) ? .tomorrow : .today
        return HyuabotSearchLogic.url(for: .cafeteria(day: day, meal: entity.meal, restaurant: nil))
    }
}

struct OpenShuttleArrivalIntent: OpenIntent {
    static let title: LocalizedStringResource = "intent.open.shuttle.title"
    static let openAppWhenRun = true

    @Parameter(title: "intent.open.shuttle.title")
    var target: ShuttleArrivalEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(OpenEntityLogic.url(for: target))
        return .result()
    }
}

struct OpenSubwayArrivalIntent: OpenIntent {
    static let title: LocalizedStringResource = "intent.open.subway.title"
    static let openAppWhenRun = true

    @Parameter(title: "intent.open.subway.title")
    var target: SubwayArrivalEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(OpenEntityLogic.url(for: target))
        return .result()
    }
}

struct OpenBusArrivalIntent: OpenIntent {
    static let title: LocalizedStringResource = "intent.open.bus.title"
    static let openAppWhenRun = true

    @Parameter(title: "intent.open.bus.title")
    var target: BusArrivalEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(OpenEntityLogic.url(for: target))
        return .result()
    }
}

struct OpenCafeteriaMenuIntent: OpenIntent {
    static let title: LocalizedStringResource = "intent.open.cafeteria.title"
    static let openAppWhenRun = true

    @Parameter(title: "intent.open.cafeteria.title")
    var target: CafeteriaMenuEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(OpenEntityLogic.url(for: target))
        return .result()
    }
}
