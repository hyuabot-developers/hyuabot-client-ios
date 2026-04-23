import Foundation
import Api
import RealmSwift

final class Contact: RealmSwift.Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var campusID: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var phoneNumber: String = ""
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

extension Contact {
    static func transform(from category: ContactPageQuery.Data.Phonebook.Category) -> [Contact] {
        category.entries.map { entry in
            Contact().then {
                $0.id = entry.seq
                $0.campusID = entry.campus
                $0.name = entry.name
                $0.phoneNumber = entry.phone
            }
        }
    }
        
    
    static func replaceAll(with contacts: [Contact]) {
        let realm = Database.shared.database
        try! realm.write {
            realm.delete(realm.objects(Contact.self))
            realm.add(contacts)
        }
    }
    
    static func fetchAll() -> Results<Contact> {
        let realm = Database.shared.database
        return realm.objects(Contact.self)
    }
}
