import RealmSwift
import UIKit

final class Database: @unchecked Sendable {
    static let shared = Database()
    let database: Realm
    private init() {
        database = try! Realm()
    }
}
