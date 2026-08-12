import Api
import Foundation
import RealmSwift

final class Contact: RealmSwift.Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var campusID: Int = 0
    @objc dynamic var name: String = ""
    @objc dynamic var phoneNumber: String = ""

    override class func primaryKey() -> String? {
        "id"
    }
}

extension Contact {
    struct Record {
        let id: Int
        let campusID: Int
        let name: String
        let phoneNumber: String
    }

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

    @MainActor
    static func transformTranslated(from categories: [ContactPageQuery.Data.Phonebook.Category]) async -> [Record] {
        let entries = categories.flatMap(\.entries)
        let translations = await KoreanTextTranslator.shared.translateMany(entries.map(\.name))
        return entries.map { entry in
            Record(
                id: entry.seq,
                campusID: entry.campus,
                name: translations[entry.name] ?? entry.name,
                phoneNumber: entry.phone
            )
        }
    }

    static func replaceAll(with records: [Record]) async {
        await Task.detached {
            guard let realm = try? Realm() else { return }
            do {
                try realm.write {
                    realm.delete(realm.objects(Contact.self))
                    realm.add(records.map { record in
                        Contact().then {
                            $0.id = record.id
                            $0.campusID = record.campusID
                            $0.name = record.name
                            $0.phoneNumber = record.phoneNumber
                        }
                    })
                }
            } catch {
                assertionFailure("Failed to replace contacts: \(error)")
            }
        }.value
    }

    static func fetchAll() -> Results<Contact> {
        let realm = Database.shared.database
        return realm.objects(Contact.self)
    }

    static func deleteAll() {
        let realm = Database.shared.database
        do {
            try realm.write {
                realm.delete(realm.objects(Contact.self))
            }
        } catch {
            assertionFailure("Failed to delete contacts: \(error)")
        }
    }
}
