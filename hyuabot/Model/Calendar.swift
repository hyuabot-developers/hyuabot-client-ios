import Api
import Foundation
import RealmSwift
import UIKit

final class Event: RealmSwift.Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var title: String = ""
    @objc dynamic var descriptionText: String = ""
    @objc dynamic var startDate: String = ""
    @objc dynamic var endDate: String = ""
    @objc dynamic var categoryID: Int = 0
    @objc dynamic var categoryName: String = ""

    override class func primaryKey() -> String? {
        "id"
    }
}

extension Event {
    static let dateFormatter = DateFormatter().then {
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
        $0.timeZone = TimeZone(identifier: "Asia/Seoul")
    }

    static func transform(from category: CalendarPageQuery.Data.Calendar.Category) -> [Event] {
        category.events.map { event in
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

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        return f
    }()

    private var startDateOnly: String {
        String(startDate.prefix(10))
    }

    private var endDateOnly: String {
        String(endDate.prefix(10))
    }

    var isSingleDay: Bool {
        startDateOnly == endDateOnly
    }

    var isOngoing: Bool {
        let today = Self.dateOnlyFormatter.string(from: Date())
        return startDateOnly <= today && endDateOnly >= today
    }

    var isPast: Bool {
        let today = Self.dateOnlyFormatter.string(from: Date())
        return endDateOnly < today
    }

    var daysUntilStart: Int? {
        let today = Self.dateOnlyFormatter.string(from: Date())
        guard startDateOnly > today else { return nil }
        guard let start = Self.dateOnlyFormatter.date(from: startDateOnly) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: start).day
    }

    private static let categoryPalette: [UIColor] = [
        .systemBlue, .systemOrange, .systemGreen, .systemPurple,
        .systemRed, .systemTeal, .systemIndigo, .systemBrown
    ]

    var categoryColor: UIColor {
        Self.categoryPalette[abs(categoryID) % Self.categoryPalette.count]
    }
}
