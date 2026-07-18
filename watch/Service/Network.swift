import Apollo
import Foundation

final class Network: @unchecked Sendable {
    static let shared = Network()
    private(set) lazy var client = ApolloClient(url: URL(string: "https://backend.hyuabot.app/graphql")!)
}
