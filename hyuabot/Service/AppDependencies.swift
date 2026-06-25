//
//  AppDependencies.swift
//  hyuabot
//

import Apollo
import ApolloAPI
import Foundation
import RealmSwift

protocol GraphQLFetching {
    func fetchGraphQL<Query: GraphQLQuery>(_ query: Query) async throws -> GraphQLResponse<Query>
        where Query.ResponseFormat == SingleResponseFormat
}

extension ApolloClient: GraphQLFetching {
    func fetchGraphQL<Query: GraphQLQuery>(
        _ query: Query
    ) async throws -> GraphQLResponse<Query> where Query.ResponseFormat == SingleResponseFormat {
        try await fetch(query: query)
    }
}

protocol UserDefaultsStoring {
    func integer(forKey defaultName: String) -> Int
    func bool(forKey defaultName: String) -> Bool
    func stringArray(forKey defaultName: String) -> [String]?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: UserDefaultsStoring {}

protocol Clock {
    var now: Date { get }
}

struct SystemClock: Clock {
    var now: Date {
        Date()
    }
}

protocol RealmProviding {
    var realm: Realm { get }
}

extension Database: RealmProviding {
    var realm: Realm {
        database
    }
}
