//
//  CafeteriaDebugFixture.swift
//  hyuabot
//

#if DEBUG
    import Foundation

    enum CafeteriaDebugFixture {
        enum Mode: String, CaseIterable {
            case standard
            case loading
            case emptyDay
            case emptyMeal
        }

        static var activeMode: Mode? {
            let arguments = ProcessInfo.processInfo.arguments
            guard let index = arguments.firstIndex(of: "-cafeteriaFixture"), arguments.indices.contains(index + 1) else { return nil }
            return Mode(rawValue: arguments[index + 1])
        }

        static var now: Date {
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = 2026
            components.month = 11
            components.day = 9
            components.hour = 12
            components.minute = 50
            return calendar.date(from: components) ?? .now
        }

        static var today: Date {
            Calendar.current.startOfDay(for: now)
        }

        private struct Meal {
            let type: String
            let food: String
            let price: String
        }

        static func sources(for mode: Mode) -> [CafeteriaSource] {
            func source(_ seq: Int, _ times: [String?], _ meals: [Meal]) -> CafeteriaSource {
                CafeteriaSource(seq: seq, runningTimes: times, menus: meals.map {
                    CafeteriaMenuSource(type: $0.type, food: $0.food, price: $0.price)
                })
            }
            let standard = [
                source(11, [nil, "11:30~13:30", nil], [
                    Meal(type: "중식", food: "닭곰탕&소면사리, 언양식불고기, 도토리묵&양념장, 무생채, 배추김치, 잡곡밥, 그린샐러드", price: "6,500"),
                    Meal(type: "중식", food: "만두카츠&소스, 쫄면야채무침, 우동국물, 단무지, 추가밥", price: "5,500")
                ]),
                source(12, [nil, "11:30~13:30", nil], [
                    Meal(type: "중식", food: "우삼겹숙주덮밥, 알감자꼬치튀김, 단무지무침, 배추김치, 요구르트", price: "6,500"),
                    Meal(type: "중식", food: "잔치국수, 김가루양념밥, 단무지무침, 배추김치", price: "4,500"),
                    Meal(type: "조식", food: "[천원의 아침밥] 돼지고기고추장찌개, 쌀밥, 소고기잡채, 도시락김, 콩자반, 배추김치", price: "1,000")
                ]),
                source(13, ["07:40~09:00", "11:30~13:20", "17:10~18:40"], [
                    Meal(type: "조식", food: "[천원의 아침밥] 소고기미역국, 쌀밥, 야채샐러드*드레싱, 깍두기, 시리얼*우유, 삶은계란*소금", price: "1,000"),
                    Meal(type: "중식", food: "(뚝)불향숙주닭볶음탕, 쌀밥, 우동장국, 푸실리살사샐러드, 깍두기", price: "4,500"),
                    Meal(type: "석식", food: "훈제오리감자볶음, 쌀밥, 유부장국, 부추양파무침, 쌈무", price: "4,500"),
                    Meal(type: "중식", food: "돈카츠동, 쌀밥, 우동장국, 푸실리살사샐러드, 깍두기", price: "4,500")
                ]),
                source(15, [nil, "11:30~13:30", "17:00~18:30"], [
                    Meal(type: "석식", food: "겉절이비빔밥*달걀후라이, 치킨강정가라아게, 햄어묵볶음, 쌀밥, 땡초콩나물국, 배추김치, 양배추샐러드*드레싱", price: "6,500"),
                    Meal(type: "중식", food: "정통고추장제육볶음, 삼색계란찜, 아삭콩나물무침, 시래기된장국, 잡곡밥, 배추김치, 양배추샐러드*드레싱", price: "6,500")
                ])
            ]
            switch mode {
            case .standard: return standard
            case .emptyMeal:
                return standard.filter { $0.menus.contains { $0.type == "조식" } }.map { item in
                    let meals = item.menus.filter { $0.type == "조식" }.map {
                        Meal(type: $0.type, food: $0.food, price: $0.price)
                    }
                    return source(item.seq, item.runningTimes, meals)
                }
            case .loading, .emptyDay: return []
            }
        }
    }
#endif
