//
//  Network.swift
//  hyuabot
//
//  Created by 이정인 on 12/3/24.
//
import Apollo
import Foundation


class Network {
    static let shared = Network()
    private(set) lazy var apollo: ApolloClient = ApolloClient(url: URL(string: "https://api.hyuabot.app/query")!)
}
