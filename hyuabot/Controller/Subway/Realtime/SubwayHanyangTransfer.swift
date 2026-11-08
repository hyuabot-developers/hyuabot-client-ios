//
//  SubwayHanyangTransfer.swift
//  hyuabot
//

import Foundation

enum SubwayHanyangTransfer {
    static let oidoStationID = "K258"
    static let hanyangStationID = "K251"
    static let transferBufferMinutes = 2

    struct Route<Entry> {
        let take: Entry
        let transfer: Entry?
        let waitMinutes: Int?
    }

    static func routes<Entry>(
        arrivingAtOido: [Entry],
        line4Departures: [Entry],
        minutes: (Entry) -> Int,
        terminalID: (Entry) -> String,
        isRealtime: (Entry) -> Bool
    ) -> [Route<Entry>] {
        let candidates = arrivingAtOido.enumerated()
            .filter { isRealtime($0.element) }
            .sorted { lhs, rhs in
                let lhsMinutes = minutes(lhs.element)
                let rhsMinutes = minutes(rhs.element)
                return lhsMinutes == rhsMinutes ? lhs.offset < rhs.offset : lhsMinutes < rhsMinutes
            }
            .map(\.element)
        let departures = line4Departures.enumerated()
            .sorted { lhs, rhs in
                let lhsMinutes = minutes(lhs.element)
                let rhsMinutes = minutes(rhs.element)
                return lhsMinutes == rhsMinutes ? lhs.offset < rhs.offset : lhsMinutes < rhsMinutes
            }
            .map(\.element)

        return candidates.compactMap { candidate in
            let terminal = terminalID(candidate)
            if terminal == oidoStationID {
                guard let departure = departures.first(where: {
                    minutes($0) >= minutes(candidate) + transferBufferMinutes
                }) else {
                    return nil
                }
                return Route(
                    take: candidate,
                    transfer: departure,
                    waitMinutes: minutes(departure) - minutes(candidate)
                )
            }
            if terminal.hasPrefix("K2"), terminal <= hanyangStationID {
                return Route(take: candidate, transfer: nil, waitMinutes: nil)
            }
            return nil
        }
    }
}
