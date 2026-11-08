//
//  CommuterDebugFixture.swift
//  hyuabot
//

import Foundation

#if DEBUG
enum CommuterDebugFixture {
    enum Mode: String, CaseIterable {
        case standard
        case five
        case from
        case loading
        case noLocation
        case vacation
        case weekend
    }

    struct Scenario {
        let routes: [CommuterRoute]
        let context: CommuterServiceContext
        let isLoading: Bool
    }

    static var activeMode: Mode? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-commuterFixture"),
              arguments.indices.contains(arguments.index(after: index)) else { return nil }
        return Mode(rawValue: arguments[arguments.index(after: index)])
    }

    static let routes: [CommuterRoute] = CommuterDesignRoutes.all

    static func scenario(_ mode: Mode) -> Scenario {
        let endDay = CommuterBusLogic.day(year: 2026, month: 12, day: 21)
        let standard = context(day: CommuterBusLogic.day(year: 2026, month: 11, day: 9),
                               nowMinutes: 398, periodEndDay: endDay,
                               userLocation: ShuttleGeoCoordinate(latitude: 37.5162, longitude: 127.0998))

        switch mode {
        case .standard:
            return Scenario(routes: routes, context: standard, isLoading: false)
        case .five:
            return Scenario(
                routes: routes,
                context: context(day: CommuterBusLogic.day(year: 2026, month: 11, day: 9),
                                 nowMinutes: 439, periodEndDay: endDay,
                                 userLocation: ShuttleGeoCoordinate(latitude: 37.3270, longitude: 127.1092)),
                isLoading: false
            )
        case .from:
            return Scenario(
                routes: routes,
                context: context(day: CommuterBusLogic.day(year: 2026, month: 11, day: 9),
                                 nowMinutes: 1045, periodEndDay: endDay,
                                 userLocation: ShuttleGeoCoordinate(latitude: 37.2993, longitude: 126.8342)),
                isLoading: false
            )
        case .loading:
            return Scenario(routes: routes, context: standard, isLoading: true)
        case .noLocation:
            return Scenario(
                routes: routes,
                context: context(day: CommuterBusLogic.day(year: 2026, month: 11, day: 9),
                                 nowMinutes: 420, periodEndDay: endDay, userLocation: nil),
                isLoading: false
            )
        case .vacation:
            return Scenario(
                routes: routes,
                context: context(day: CommuterBusLogic.day(year: 2026, month: 12, day: 28), nowMinutes: 420,
                                 periodType: "vacation_session",
                                 periodEndDay: CommuterBusLogic.day(year: 2027, month: 1, day: 15),
                                 nextRunDay: CommuterBusLogic.day(year: 2027, month: 3, day: 2),
                                 userLocation: ShuttleGeoCoordinate(latitude: 37.5162, longitude: 127.0998)),
                isLoading: false
            )
        case .weekend:
            return Scenario(
                routes: routes,
                context: context(day: CommuterBusLogic.day(year: 2026, month: 11, day: 7),
                                 nowMinutes: 620, periodEndDay: endDay,
                                 userLocation: ShuttleGeoCoordinate(latitude: 37.5162, longitude: 127.0998)),
                isLoading: false
            )
        }
    }

    private static func context(
        day: Date,
        nowMinutes: Int,
        periodType: String = "semester",
        periodEndDay: Date,
        nextRunDay: Date? = nil,
        userLocation: ShuttleGeoCoordinate?
    ) -> CommuterServiceContext {
        CommuterServiceContext(
            date: day,
            nowMinutes: nowMinutes,
            periodType: periodType,
            periodEndDay: periodEndDay,
            holidayType: nil,
            nextRunDay: nextRunDay,
            userLocation: userLocation
        )
    }
}
#endif
