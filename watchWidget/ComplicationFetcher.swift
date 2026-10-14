import Api
import Apollo
import Foundation

enum ComplicationFetchError: Error {
    case noData
}

/// Loads the day's timetable for a stop using the same query shape as the watch app, with an explicit `order` cap.
enum ComplicationFetcher {
    static func schedule(for stop: ComplicationStop, now: Foundation.Date) async throws -> KnownSchedule {
        let client = ApolloClient(url: URL(string: "https://backend.hyuabot.app/graphql")!)
        let response = try await client.fetch(query: ShuttleRealtimePageWatchQuery(
            stops: stop.queryStops.map {
                ShuttleStopInput(
                    name: $0,
                    limit: ShuttleLimitInput(order: GraphQLNullable.some(Int32(ComplicationCoverage.fetchLimit)))
                )
            },
            after: GraphQLNullable.some(ShuttleClock.queryTime(now))
        ))
        guard let data = response.data else {
            throw ComplicationFetchError.noData
        }

        let results = stop.queryStops.map { name -> StopTimetableResult in
            let rows = data.shuttle.stops
                .filter { $0.name == name }
                .flatMap { $0.timetable.order }
                .map { TimetableRow(localTime: $0.time, routeTag: $0.route.tag, routeName: $0.route.name) }
            return StopTimetableResult(stopName: name, rows: rows)
        }
        return ComplicationCoverage.assemble(results: results, day: now)
    }
}
