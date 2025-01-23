import UIKit
import RealmSwift

final class Database {
    static let shared = Database()
    let database: Realm
    private init() { self.database = try! Realm() }
}
