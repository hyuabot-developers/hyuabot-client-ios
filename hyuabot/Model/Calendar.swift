import Foundation
import Api
import RealmSwift

final class Event: RealmSwift.Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var descriptionText: String = ""
    @objc dynamic var startDate: String = ""
    @objc dynamic var endDate: String = ""
    @objc dynamic var categoryID: Int = 0
    @objc dynamic var categoryName: String = ""

    override class func primaryKey() -> String? {
        return "id"
    }
}

extension Event {
    static let dateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }
        
    static func transform(from category: CalendarPageQuery.Data.Calendar.Category) -> [Event] {
        return category.events.map { event in
            Event().then {
                $0.id = event.seq
                $0.title = event.title
                $0.descriptionText = event.description
                $0.startDate = event.start
                $0.endDate = event.end
                $0.categoryID = category.seq
                $0.categoryName = category.name
            }
        }
    }
        
    
    static func replaceAll(with contacts: [Event]) {
        let realm = Database.shared.database
        try! realm.write {
            realm.delete(realm.objects(Event.self))
            realm.add(contacts)
        }
    }
    
    static func fetchAll() -> Results<Event> {
        let realm = Database.shared.database
        return realm.objects(Event.self)
    }
}
