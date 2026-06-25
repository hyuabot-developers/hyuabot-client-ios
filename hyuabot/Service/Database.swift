import RealmSwift
import UIKit

final class Database {
    static let shared = Database()
    let database: Realm
    private init() {
        database = try! Realm()
    }
}
