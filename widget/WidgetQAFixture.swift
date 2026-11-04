//
//  WidgetQAFixture.swift
//  hyuabot
//

import Foundation

#if DEBUG
    enum WidgetQAFixture {
        static let appGroupID = "group.net.jaram.hyuabot"
        static let fileName = "widget-qa-fixture"

        static func selected(prefix: String) -> String? {
            guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
                .appendingPathComponent(fileName),
                let text = try? String(contentsOf: url, encoding: .utf8)
            else { return nil }
            return text.components(separatedBy: CharacterSet(charactersIn: ", \n\t"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty && $0.hasPrefix(prefix + "-") }
        }

        static func holdForPlaceholderCapture() async {
            try? await Task.sleep(nanoseconds: 20_000_000_000)
        }

        static func cafeteriaEntry(named name: String) -> CafeteriaEntry? {
            let lunch = Date(timeIntervalSince1970: 1_772_507_400)
            let evening = Date(timeIntervalSince1970: 1_772_537_400)
            let tomorrow = Date(timeIntervalSince1970: 1_772_580_600)
            switch name {
            case "cafeteria-lunch": return CafeteriaEntry(date: lunch, mealType: .lunch, items: lunchItems(), menuDate: lunch)
            case "cafeteria-overflow": return CafeteriaEntry(date: lunch, mealType: .lunch, items: overflowItems(), menuDate: lunch)
            case "cafeteria-oversized": return CafeteriaEntry(date: lunch, mealType: .lunch, items: oversizedItems(), menuDate: lunch)
            case "cafeteria-tomorrow": return CafeteriaEntry(date: evening, mealType: .closed, items: breakfastItems(), menuDate: tomorrow)
            case "cafeteria-empty": return CafeteriaEntry(date: lunch, mealType: .lunch, items: [], menuDate: lunch)
            case "cafeteria-error": return CafeteriaEntry(date: lunch, mealType: .lunch, items: [], menuDate: lunch, loadFailed: true)
            default: return nil
            }
        }

        private static func lunchItems() -> [CafeteriaMenuItem] {
            [
                item("학생식당", ["제육볶음", "된장찌개", "잡채"], "11:00~14:00"),
                item("교직원식당", ["불고기정식", "미역국", "김치전", "샐러드"], "11:00~12:30"),
                item("창업보육센터", ["돈까스", "우동", "단무지"], "17:00~19:00"),
                item("생활과학관", ["비빔밥", "콩나물국", "계란말이", "김치", "과일"], "08:00~09:30")
            ]
        }

        private static func overflowItems() -> [CafeteriaMenuItem] {
            let foods = ["제육볶음", "된장찌개", "잡채", "불고기", "김치전", "비빔밥", "미역국", "돈까스", "계란말이", "콩나물국", "닭갈비", "볶음밥", "만두국", "생선구이"]
            return [
                item("학생식당", ["오늘의 메뉴", "된장찌개", "김치"], "11:00~14:00"),
                item("교직원식당", foods, "11:00~14:00")
            ] + (3 ... 7).map { index in
                item("식당 \(index)", Array(foods.prefix(3 + index % 4)), "11:00~14:00")
            }
        }

        private static func oversizedItems() -> [CafeteriaMenuItem] {
            let foods = [
                "제육볶음",
                "된장찌개",
                "잡채",
                "불고기",
                "김치전",
                "비빔밥",
                "미역국",
                "돈까스",
                "계란말이",
                "콩나물국",
                "닭갈비",
                "볶음밥",
                "만두국",
                "생선구이",
                "순두부찌개",
                "카레라이스"
            ]
            return [
                item("학생식당", foods, "11:00~14:00"),
                item("교직원식당", ["불고기", "미역국", "김치"], "11:00~14:00"),
                item("창업보육센터", ["돈까스", "우동", "단무지"], "11:00~14:00")
            ]
        }

        private static func breakfastItems() -> [CafeteriaMenuItem] {
            [
                item("학생식당", ["소고기무국", "계란말이", "김치"], "08:00~09:30"),
                item("교직원식당", ["황태해장국", "두부조림", "깍두기", "과일"], "08:00~09:30"),
                item("생활과학관", ["토스트", "우유", "샐러드"], "08:00~09:30")
            ]
        }

        private static func item(_ name: String, _ foods: [String], _ time: String) -> CafeteriaMenuItem {
            CafeteriaMenuItem(cafeteriaName: name, menus: foods.enumerated().map { index, food in
                CafeteriaMenuRow(food: food, price: ["5000", "2000", "1500", "4500", "3000"][index % 5])
            }, runningTime: time)
        }
    }
#endif
