//
//  Database.swift
//  hyuabot
//

import RealmSwift
import UIKit

final class Database: @unchecked Sendable {
    static let shared = Database()
    let database: Realm

    static func makeRealm(configuration: Realm.Configuration) -> Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            do {
                try Realm.deleteFiles(for: configuration)
            } catch {
                // Retry opening even when the file could not be removed.
            }
            do {
                return try Realm(configuration: configuration)
            } catch {
                var inMemoryConfiguration = configuration
                inMemoryConfiguration.inMemoryIdentifier = UUID().uuidString
                // Background writers open the default configuration, so point it at the same store.
                Realm.Configuration.defaultConfiguration = inMemoryConfiguration
                do {
                    return try Realm(configuration: inMemoryConfiguration)
                } catch {
                    fatalError("Unable to open an in-memory Realm: \(error)")
                }
            }
        }
    }

    private init() {
        var configuration = Realm.Configuration.defaultConfiguration
        configuration.schemaVersion = 2
        configuration.deleteRealmIfMigrationNeeded = true
        Realm.Configuration.defaultConfiguration = configuration
        database = Self.makeRealm(configuration: configuration)
    }
}
