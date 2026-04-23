import Apollo
import Foundation

class Network {
    static let shared = Network()
    private(set) lazy var client = ApolloClient(url: URL(string: "https://backend.hyuabot.app/graphql")!)
}
