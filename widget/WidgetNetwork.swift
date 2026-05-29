import Foundation

private let graphqlURL = URL(string: "https://backend.hyuabot.app/graphql")!

func widgetGraphQL<T: Decodable>(query: String, variables: [String: Any]) async throws -> T {
    var request = URLRequest(url: graphqlURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "variables": variables])
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
    guard let result = response.data else {
        throw URLError(.cannotParseResponse)
    }
    return result
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
}
