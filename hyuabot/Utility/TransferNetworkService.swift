import Foundation

private let graphqlURL = URL(string: "https://backend.hyuabot.app/graphql")!

private struct GQLResponse<T: Decodable>: Decodable { let data: T? }

func fetchTransferData<T: Decodable>(query: String, variables: [String: Any] = [:]) async throws -> T {
    var request = URLRequest(url: graphqlURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    var body: [String: Any] = ["query": query]
    if !variables.isEmpty { body["variables"] = variables }
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(GQLResponse<T>.self, from: data)
    guard let result = decoded.data else { throw URLError(.cannotParseResponse) }
    return result
}

func currentWeekdayString() -> String {
    var cal = Calendar.current
    cal.timeZone = TimeZone(identifier: "Asia/Seoul") ?? cal.timeZone
    switch cal.component(.weekday, from: Date()) {
    case 1: return "sunday"
    case 7: return "saturday"
    default: return "weekday"
    }
}
