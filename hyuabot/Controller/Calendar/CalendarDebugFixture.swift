//
//  CalendarDebugFixture.swift
//  hyuabot
//

import Foundation

#if DEBUG
enum CalendarDebugFixture {
    enum Mode: String {
        case full
        case pastOnly
        case hiddenUpcoming
        case loading
    }

    static var activeMode: Mode? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-calendarFixture"),
              arguments.indices.contains(arguments.index(after: index)) else { return nil }
        return Mode(rawValue: arguments[arguments.index(after: index)])
    }

    static func events(mode: Mode, today: Date) -> [Event] {
        func day(_ offset: Int) -> String {
            let start = calendar.startOfDay(for: today)
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            return formatter.string(from: date)
        }

        func make(
            id: Int,
            title: String,
            desc: String,
            days: ClosedRange<Int>,
            category: Int,
            name: String
        ) -> Event {
            Event().then {
                $0.id = id
                $0.title = title
                $0.descriptionText = desc
                $0.startDate = "\(day(days.lowerBound)) 00:00:00"
                $0.endDate = "\(day(days.upperBound)) 23:59:59"
                $0.categoryID = category
                $0.categoryName = name
            }
        }

        switch mode {
        case .full, .loading:
            return [
                make(id: 9001, title: "수강신청 정정 기간", desc: "포털에서 정정 신청", days: -1...1, category: 1, name: "학사"),
                make(id: 9002, title: "중간고사", desc: "", days: 3...5, category: 2, name: "시험"),
                make(id: 9003, title: "개교기념 행사", desc: "", days: 3...3, category: 3, name: "행사"),
                make(id: 9004, title: "보강일", desc: "", days: 3...3, category: 4, name: "휴일"),
                make(id: 9005, title: "학위수여식", desc: "", days: 10...10, category: 3, name: "행사"),
                make(id: 9006, title: "지난 설명회", desc: "", days: -6 ... -5, category: 1, name: "학사")
            ]
        case .pastOnly:
            return [
                make(id: 9101, title: "지난 오리엔테이션", desc: "", days: -10 ... -8, category: 1, name: "학사"),
                make(id: 9102, title: "지난 특강", desc: "", days: -3 ... -3, category: 2, name: "시험")
            ]
        case .hiddenUpcoming:
            return [
                make(id: 9201, title: "지난 설명회", desc: "", days: -4 ... -4, category: 1, name: "학사"),
                make(id: 9202, title: "기말고사", desc: "", days: 2...3, category: 2, name: "시험")
            ]
        }
    }

    private static let calendar: Calendar = {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return value
    }()

    private static let formatter: DateFormatter = {
        let value = DateFormatter()
        value.locale = Locale(identifier: "en_US_POSIX")
        value.timeZone = TimeZone(identifier: "Asia/Seoul")
        value.dateFormat = "yyyy-MM-dd"
        return value
    }()

}
#endif
