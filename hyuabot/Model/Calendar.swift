import Foundation
import QueryAPI
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
        
    static func transform(from event: CalendarPageQuery.Data.Calendar.Datum) -> Event {
        let newEvent = Event()
        newEvent.id = event.id
        newEvent.title = event.title
        newEvent.descriptionText = event.description
        newEvent.startDate = event.start
        newEvent.endDate = event.end
        newEvent.categoryID = event.category.id
        newEvent.categoryName = event.category.name
        return newEvent
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
