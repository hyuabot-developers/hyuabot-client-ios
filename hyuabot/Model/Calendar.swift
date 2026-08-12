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
    struct Record: Sendable {
        let id: Int
        let title: String
        let descriptionText: String
        let startDate: String
        let endDate: String
        let categoryID: Int
        let categoryName: String
    }

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

    @MainActor
    static func transformTranslated(from categories: [CalendarPageQuery.Data.Calendar.Category]) async -> [Record] {
        let events = categories.flatMap { category in
            category.events.map { (category, $0) }
        }
        let translations = await KoreanTextTranslator.shared.translateMany(
            events.flatMap { category, event in
                [category.name, event.title, event.description]
            }
        )
        return events.map { category, event in
            Record(
                id: event.seq,
                title: translations[event.title] ?? event.title,
                descriptionText: translations[event.description] ?? event.description,
                startDate: event.start,
                endDate: event.end,
                categoryID: category.seq,
                categoryName: translations[category.name] ?? category.name
            )
        }
    }

    static func replaceAll(with records: [Record]) async {
        await Task.detached {
            guard let realm = try? Realm() else { return }
            do {
                try realm.write {
                    realm.delete(realm.objects(Event.self))
                    realm.add(records.map { record in
                        Event().then {
                            $0.id = record.id
                            $0.title = record.title
                            $0.descriptionText = record.descriptionText
                            $0.startDate = record.startDate
                            $0.endDate = record.endDate
                            $0.categoryID = record.categoryID
                            $0.categoryName = record.categoryName
                        }
                    })
                }
            } catch {
                assertionFailure("Failed to replace events: \(error)")
            }
        }.value
    }

    static func fetchAll() -> Results<Event> {
        let realm = Database.shared.database
        return realm.objects(Event.self)
    }

    static func deleteAll() {
        let realm = Database.shared.database
        do {
            try realm.write {
                realm.delete(realm.objects(Event.self))
            }
        } catch {
            assertionFailure("Failed to delete events: \(error)")
        }
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
        guard let todayStart = Self.dateOnlyFormatter.date(from: today) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar.dateComponents([.day], from: todayStart, to: start).day
    }

    private static let categoryPalette: [UIColor] = [
        .systemBlue, .systemOrange, .systemGreen, .systemPurple,
        .systemRed, .systemTeal, .systemIndigo, .systemBrown
    ]

    var categoryColor: UIColor {
        Self.categoryPalette[abs(categoryID) % Self.categoryPalette.count]
    }
}
