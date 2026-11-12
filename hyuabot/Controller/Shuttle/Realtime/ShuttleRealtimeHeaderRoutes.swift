//
//  ShuttleRealtimeHeaderRoutes.swift
//  hyuabot
//

import UIKit

enum ShuttleRealtimeHeaderRoutes {
    private static func route(_ color: UIColor, current: Int = 0, _ stops: KeyValuePairs<String, Int>) -> ShuttleRoutePath {
        ShuttleRoutePath(
            color: color,
            stops: stops.map(\.key),
            currentStopIndex: current,
            labels: Dictionary(uniqueKeysWithValues: stops.map { ($0.key, $0.value) })
        )
    }

    static func adapter(stop: ShuttleStopEnum, section: Int) -> ShuttleRouteAdapter {
        let base: ShuttleRouteAdapter = switch stop {
        case .dormiotryOut: dormiotryOut(section: section)
        case .shuttlecockOut: shuttlecockOut(section: section)
        case .station: station(section: section)
        case .terminal: terminal(section: section)
        case .jungangStation: jungangStation(section: section)
        case .shuttlecockIn: shuttlecockIn(section: section)
        }
        return base.withDestination(destinationKey(stop: stop, section: section))
    }

    /// Stop key the section's route map ends at; nil means the end of each route.
    private static func destinationKey(stop: ShuttleStopEnum, section: Int) -> String? {
        switch (stop, section) {
        case (.dormiotryOut, 0), (.shuttlecockOut, 0): "shuttle.stop.station"
        case (.dormiotryOut, 1), (.shuttlecockOut, 1), (.station, 1): "shuttle.stop.terminal"
        case (.dormiotryOut, 2), (.shuttlecockOut, 2), (.station, 2): "shuttle.stop.jungang.station"
        default: nil
        }
    }
}

extension ShuttleRealtimeHeaderRoutes {
    private static func dormiotryOut(section: Int) -> ShuttleRouteAdapter {
        switch section {
        case 0: dormiotryOutSection0()
        case 1: dormiotryOutSection1()
        case 2: dormiotryOutSection2()
        default: ShuttleRouteAdapter(routes: [], labels: [])
        }
    }

    private static func dormiotryOutSection0() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .busRed,
                    current: 0,
                    [
                        "shuttle.stop.dormitory.out": 0,
                        "shuttle.stop.shuttlecock.out": 5,
                        "shuttle.stop.station": 15,
                        "shuttle.stop.shuttlecock.in": 25,
                        "shuttle.stop.dormitory.in": 30
                    ]
                ),
                route(
                    .white,
                    current: 0,
                    [
                        "shuttle.stop.dormitory.out": 0,
                        "shuttle.stop.shuttlecock.out": 5,
                        "shuttle.stop.station": 15,
                        "shuttle.stop.terminal": 20,
                        "shuttle.stop.shuttlecock.in": 30,
                        "shuttle.stop.dormitory.in": 35
                    ]
                ),
                route(
                    .hanyangGreen,
                    current: 0,
                    [
                        "shuttle.stop.dormitory.out": 0,
                        "shuttle.stop.shuttlecock.out": 5,
                        "shuttle.stop.station": 15,
                        "shuttle.stop.jungang.station": 18,
                        "shuttle.stop.shuttlecock.in": 28,
                        "shuttle.stop.dormitory.in": 33
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.direct"),
                String.LocalizationValue("shuttle.type.circular"),
                String.LocalizationValue("shuttle.type.jungang_station")
            ]
        )
    }

    private static func dormiotryOutSection1() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .busRed,
                    current: 0,
                    [
                        "shuttle.stop.dormitory.out": 0,
                        "shuttle.stop.shuttlecock.out": 5,
                        "shuttle.stop.terminal": 15,
                        "shuttle.stop.shuttlecock.in": 25,
                        "shuttle.stop.dormitory.in": 30
                    ]
                ),
                route(
                    .white,
                    current: 0,
                    [
                        "shuttle.stop.dormitory.out": 0,
                        "shuttle.stop.shuttlecock.out": 5,
                        "shuttle.stop.station": 15,
                        "shuttle.stop.terminal": 20,
                        "shuttle.stop.shuttlecock.in": 30,
                        "shuttle.stop.dormitory.in": 35
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.direct"),
                String.LocalizationValue("shuttle.type.circular")
            ]
        )
    }

    private static func dormiotryOutSection2() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .hanyangGreen,
                    current: 0,
                    [
                        "shuttle.stop.dormitory.out": 0,
                        "shuttle.stop.shuttlecock.out": 5,
                        "shuttle.stop.station": 15,
                        "shuttle.stop.jungang.station": 18,
                        "shuttle.stop.shuttlecock.in": 28,
                        "shuttle.stop.dormitory.in": 33
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.jungang_station")
            ]
        )
    }
}

extension ShuttleRealtimeHeaderRoutes {
    private static func shuttlecockOut(section: Int) -> ShuttleRouteAdapter {
        switch section {
        case 0: shuttlecockOutSection0()
        case 1: shuttlecockOutSection1()
        case 2: shuttlecockOutSection2()
        default: ShuttleRouteAdapter(routes: [], labels: [])
        }
    }

    private static func shuttlecockOutSection0() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .busRed,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -5,
                        "shuttle.stop.shuttlecock.out": 0,
                        "shuttle.stop.station": 10,
                        "shuttle.stop.shuttlecock.in": 20,
                        "shuttle.stop.dormitory.in": 25
                    ]
                ),
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -5,
                        "shuttle.stop.shuttlecock.out": 0,
                        "shuttle.stop.station": 10,
                        "shuttle.stop.terminal": 15,
                        "shuttle.stop.shuttlecock.in": 25,
                        "shuttle.stop.dormitory.in": 30
                    ]
                ),
                route(
                    .hanyangGreen,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -5,
                        "shuttle.stop.shuttlecock.out": 0,
                        "shuttle.stop.station": 10,
                        "shuttle.stop.jungang.station": 13,
                        "shuttle.stop.shuttlecock.in": 23,
                        "shuttle.stop.dormitory.in": 28
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.direct"),
                String.LocalizationValue("shuttle.type.circular"),
                String.LocalizationValue("shuttle.type.jungang_station")
            ]
        )
    }

    private static func shuttlecockOutSection1() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .busRed,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -5,
                        "shuttle.stop.shuttlecock.out": 0,
                        "shuttle.stop.terminal": 10,
                        "shuttle.stop.shuttlecock.in": 20,
                        "shuttle.stop.dormitory.in": 25
                    ]
                ),
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -5,
                        "shuttle.stop.shuttlecock.out": 0,
                        "shuttle.stop.station": 10,
                        "shuttle.stop.terminal": 15,
                        "shuttle.stop.shuttlecock.in": 25,
                        "shuttle.stop.dormitory.in": 30
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.direct"),
                String.LocalizationValue("shuttle.type.circular")
            ]
        )
    }

    private static func shuttlecockOutSection2() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .hanyangGreen,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -5,
                        "shuttle.stop.shuttlecock.out": 0,
                        "shuttle.stop.station": 10,
                        "shuttle.stop.jungang.station": 13,
                        "shuttle.stop.shuttlecock.in": 23,
                        "shuttle.stop.dormitory.in": 28
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.jungang_station")
            ]
        )
    }
}

extension ShuttleRealtimeHeaderRoutes {
    private static func station(section: Int) -> ShuttleRouteAdapter {
        switch section {
        case 0: stationSection0()
        case 1: stationSection1()
        case 2: stationSection2()
        default: ShuttleRouteAdapter(routes: [], labels: [])
        }
    }

    private static func stationSection0() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .busRed,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.station": 0,
                        "shuttle.stop.shuttlecock.in": 10,
                        "shuttle.stop.dormitory.in": 15
                    ]
                ),
                route(
                    .busRed,
                    current: 1,
                    ["shuttle.stop.dormitory.out": -15, "shuttle.stop.station": 0, "shuttle.stop.shuttlecock.in": 10]
                ),
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.station": 0,
                        "shuttle.stop.terminal": 5,
                        "shuttle.stop.shuttlecock.in": 15,
                        "shuttle.stop.dormitory.in": 20
                    ]
                ),
                stationCircularShuttlecockRoute(),
                route(
                    .hanyangGreen,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.station": 0,
                        "shuttle.stop.jungang.station": 3,
                        "shuttle.stop.shuttlecock.in": 13,
                        "shuttle.stop.dormitory.in": 18
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.direct.dormitory"),
                String.LocalizationValue("shuttle.type.direct.shuttlecock"),
                String.LocalizationValue("shuttle.type.circular.dormitory"),
                String.LocalizationValue("shuttle.type.circular.shuttlecock"),
                String.LocalizationValue("shuttle.type.jungang_station")
            ]
        )
    }

    private static func stationCircularShuttlecockRoute() -> ShuttleRoutePath {
        ShuttleRoutePath(
            color: .white,
            stops: [
                "shuttle.stop.dormitory.out",
                "shuttle.stop.station",
                "shuttle.stop.terminal",
                "shuttle.stop.shuttlecock.in"
            ],
            currentStopIndex: 1,
            labels: [
                "shuttle.stop.dormitory.out": -15,
                "shuttle.stop.station": 0,
                "shuttle.stop.terminal": 5,
                "shuttle.stop.shuttlecock.in": 15
            ]
        )
    }

    private static func stationSection1() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.station": 0,
                        "shuttle.stop.terminal": 5,
                        "shuttle.stop.shuttlecock.in": 15,
                        "shuttle.stop.dormitory.in": 20
                    ]
                ),
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.station": 0,
                        "shuttle.stop.terminal": 5,
                        "shuttle.stop.shuttlecock.in": 15
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.circular.dormitory"),
                String.LocalizationValue("shuttle.type.circular.shuttlecock")
            ]
        )
    }

    private static func stationSection2() -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .hanyangGreen,
                    current: 2,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.shuttlecock.out": -10,
                        "shuttle.stop.station": 0,
                        "shuttle.stop.jungang.station": 3,
                        "shuttle.stop.shuttlecock.in": 13,
                        "shuttle.stop.dormitory.in": 18
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.jungang_station")
            ]
        )
    }
}

extension ShuttleRealtimeHeaderRoutes {
    private static func terminal(section: Int) -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.terminal": 0,
                        "shuttle.stop.shuttlecock.in": 10,
                        "shuttle.stop.dormitory.in": 15
                    ]
                ),
                route(
                    .white,
                    current: 1,
                    ["shuttle.stop.dormitory.out": -15, "shuttle.stop.terminal": 0, "shuttle.stop.shuttlecock.in": 10]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.dormitory"),
                String.LocalizationValue("shuttle.type.shuttlecock")
            ],
            mergesByType: false
        )
    }
}

extension ShuttleRealtimeHeaderRoutes {
    private static func jungangStation(section: Int) -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .white,
                    current: 1,
                    [
                        "shuttle.stop.dormitory.out": -15,
                        "shuttle.stop.jungang.station": 0,
                        "shuttle.stop.shuttlecock.in": 10,
                        "shuttle.stop.dormitory.in": 15
                    ]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.dormitory")
            ],
            mergesByType: false
        )
    }
}

extension ShuttleRealtimeHeaderRoutes {
    private static func shuttlecockIn(section: Int) -> ShuttleRouteAdapter {
        ShuttleRouteAdapter(
            routes: [
                route(
                    .white,
                    current: 1,
                    ["shuttle.stop.dormitory.out": -25, "shuttle.stop.shuttlecock.in": 0, "shuttle.stop.dormitory.in": 5]
                )
            ],
            labels: [
                String.LocalizationValue("shuttle.type.dormitory")
            ],
            mergesByType: false
        )
    }
}
