import Apollo
import ApolloAPI
import Foundation

final class WidgetNetwork: @unchecked Sendable {
    static let shared = WidgetNetwork()
    private(set) lazy var client = ApolloClient(url: URL(string: "https://backend.hyuabot.app/graphql")!)

    private init() {}

    func fetch<Query: GraphQLQuery>(query: Query) async throws -> GraphQLResponse<Query>
        where Query.ResponseFormat == SingleResponseFormat
    {
        try await client.fetch(query: query, cachePolicy: .networkOnly)
    }
}

func widgetWeekday() -> String {
    var cal = Calendar.current
    cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? cal.timeZone
    switch cal.component(.weekday, from: Foundation.Date.now) {
    case 1: return "sunday"
    case 7: return "saturday"
    default: return "weekday"
    }
}
