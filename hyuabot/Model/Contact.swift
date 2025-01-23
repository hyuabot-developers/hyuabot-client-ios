import Foundation
import QueryAPI
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
    static func transform(from contact: ContactPageQuery.Data.Contact.Datum) -> Contact {
        let newContact = Contact()
        newContact.id = contact.id
        newContact.campusID = contact.campusID
        newContact.name = contact.name
        newContact.phoneNumber = contact.phone
        return newContact
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
