//
//  ShuttleQAFixtures.swift
//  hyuabot
//

import Foundation

#if DEBUG
    enum ShuttleQAFixtures {
        private static let ref = ShuttleSampleData.referenceDate

        static func shuttleEntry(named name: String) -> ShuttleEntry? {
            switch name {
            case "shuttle-station":
                shuttle(stop: "한대앞", id: "station", groups: [
                    group("기숙사", "CAMPUS", ["14:03", "14:20", "14:40", "15:00"]),
                    group("예술인", "TERMINAL", ["14:12", "14:35"]),
                    group("중앙역", "JUNGANG", ["14:25", "14:55"])
                ])
            case "shuttle-shuttlecock":
                shuttle(stop: "셔틀콕", id: "shuttlecock_o", groups: [
                    group("한대앞", "STATION", ["14:02", "14:10"]),
                    group("예술인", "TERMINAL", ["14:07", "14:30"]),
                    group("중앙역", "JUNGANG", ["14:15"]),
                    group("기숙사", "CAMPUS", ["14:05", "14:25"])
                ])
            case "shuttle-overlap":
                shuttle(stop: "셔틀콕", id: "shuttlecock_o", groups: [
                    group("한대앞", "STATION", ["14:02", "14:10", "14:25", "14:40"]),
                    group("중앙역", "JUNGANG", ["14:10", "14:25", "14:50"]),
                    group("기숙사", "CAMPUS", ["14:05", "14:05", "14:30"])
                ])
            case "shuttle-expired":
                shuttle(stop: "한대앞", id: "station", groups: [
                    group("기숙사", "CAMPUS", ["13:40", "13:55"])
                ])
            case "shuttle-error":
                shuttle(stop: "", id: "", groups: [], error: .error)
            case "shuttle-location":
                shuttle(stop: "", id: "", groups: [], error: .noLocation)
            default:
                nil
            }
        }

        static func transferEntry(named name: String) -> TransferEntry? {
            switch name {
            case "transfer-dormitory":
                transfer(stop: "기숙사", id: "dormitory_o", groups: activeGroups, transit: fullTransit)
            case "transfer-terminal":
                transfer(stop: "예술인", id: "terminal", groups: activeGroups, transit: [bus])
            case "transfer-station":
                transfer(stop: "한대앞", id: "station", groups: activeGroups, transit: [])
            case "transfer-shuttles-exhausted":
                transfer(stop: "기숙사", id: "dormitory_o", groups: expiredGroups, transit: subway)
            case "transfer-expired":
                transfer(stop: "기숙사", id: "dormitory_o", groups: expiredGroups, transit: [])
            case "transfer-error":
                transfer(stop: "", id: "", groups: [], transit: [], error: .error)
            case "transfer-location":
                transfer(stop: "", id: "", groups: [], transit: [], error: .noLocation)
            default:
                nil
            }
        }

        private static let activeGroups = [
            group("한대앞", "STATION", ["14:04", "14:24"]),
            group("예술인", "TERMINAL", ["14:15", "14:45"]),
            group("중앙역", "JUNGANG", ["14:30"])
        ]

        private static let expiredGroups = [group("한대앞", "STATION", ["13:40", "13:55"])]

        private static func group(_ destination: String, _ key: String, _ times: [String]) -> ShuttleDestinationGroup {
            ShuttleDestinationGroup(destination: destination, times: times, destinationKey: key, serviceDate: ref)
        }

        private static func shuttle(
            stop: String,
            id: String,
            groups: [ShuttleDestinationGroup],
            error: ShuttleErrorState = .none
        ) -> ShuttleEntry {
            ShuttleEntry(date: ref, stopDisplayName: stop, stopID: id, groups: groups, errorState: error)
        }

        private static func transfer(
            stop: String,
            id: String,
            groups: [ShuttleDestinationGroup],
            transit: [TransitArrival],
            error: ShuttleErrorState = .none
        ) -> TransferEntry {
            TransferEntry(date: ref, stopDisplayName: stop, stopID: id, shuttleGroups: groups, transitArrivals: transit, errorState: error)
        }

        private static let subway = [
            TransitArrival(
                name: "4호선",
                colorKey: "line4",
                upEntries: [TransitEntry(terminal: "당고개", minutes: 3)],
                downEntries: [TransitEntry(terminal: "오이도", minutes: 12)]
            ),
            TransitArrival(
                name: "수인선",
                colorKey: "suin",
                upEntries: [TransitEntry(terminal: "수원", minutes: 7)],
                downEntries: [TransitEntry(terminal: "인천", minutes: 22)]
            )
        ]

        private static let bus = TransitArrival(
            name: "50번",
            colorKey: "bus",
            upEntries: [TransitEntry(terminal: "", minutes: 8), TransitEntry(terminal: "", minutes: 31)],
            downEntries: []
        )

        private static let fullTransit = subway + [bus]
    }
#endif
