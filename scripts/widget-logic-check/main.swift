import Foundation

var failures: [String] = []

func seoul(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, _ s: Int = 0) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    return calendar.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi, second: s))!
}

func expect(_ ok: Bool, _ name: String) {
    print("\(ok ? "PASS" : "FAIL") \(name)")
    if !ok { failures.append(name) }
}

let midnight = seoul(2026, 3, 4, 0, 0)
let expired = ShuttleDestinationGroup(destination: "A", times: ["23:59"], destinationKey: "STATION", serviceDate: seoul(2026, 3, 3, 23, 58))
expect(ShuttleDepartureMath.upcoming(in: expired, now: seoul(2026, 3, 3, 23, 58))[0].minutes == 1, "departure minute ceiling")
expect(ShuttleDepartureMath.upcoming(in: expired, now: midnight).isEmpty, "departure stays expired after midnight")
let timeline = ShuttleDepartureMath.minuteTimelineDates(from: seoul(2026, 3, 3, 23, 58), count: 5)
expect(timeline.allSatisfy { date in
    let departures = ShuttleDepartureMath.upcoming(in: expired, now: date)
    if date >= midnight { return departures.isEmpty }
    return departures.allSatisfy { $0.minutes <= 2 }
}, "midnight timeline has no 1439 minute departure")
let minuteDates = ShuttleDepartureMath.minuteTimelineDates(from: seoul(2026, 3, 3, 14, 0, 30), count: 5)
expect(minuteDates.count == 5 && minuteDates.dropFirst().first == seoul(2026, 3, 3, 14, 1), "minute timeline aligns to next minute")
expect(!ShuttleDepartureMath.transferHasContent(groups: [expired], transitArrivalCount: 0, now: midnight), "transfer ended when empty")
expect(ShuttleDepartureMath.transferHasContent(groups: [expired], transitArrivalCount: 1, now: midnight), "transfer has transit arrival")
let future = ShuttleDestinationGroup(destination: "A", times: ["00:10"], destinationKey: "STATION", serviceDate: midnight)
expect(ShuttleDepartureMath.transferHasContent(groups: [future], transitArrivalCount: 0, now: midnight), "transfer has future shuttle")
expect(ShuttleSampleData.referenceDate == seoul(2026, 3, 3, 14, 0), "sample reference date")

let cafeteriaItem = CafeteriaMenuItem(cafeteriaName: "c", menus: [CafeteriaMenuRow(food: "m", price: "1000")], runningTime: "11:00~13:30")
expect(CafeteriaPresentation.status(runningTime: "11:00~13:30", now: seoul(2026, 3, 3, 13, 10), isNextDay: false) == .closingSoon(closing: "13:30"), "cafeteria closing soon boundary")
expect(CafeteriaPresentation.status(runningTime: "11:00~13:30", now: seoul(2026, 3, 3, 12, 0), isNextDay: false) == .open(closing: "13:30"), "cafeteria open")
expect(CafeteriaPresentation.status(runningTime: "11:00~13:30", now: seoul(2026, 3, 3, 10, 0), isNextDay: false) == .upcoming(opening: "11:00"), "cafeteria upcoming")
expect(CafeteriaPresentation.status(runningTime: "11:00~13:30", now: seoul(2026, 3, 3, 14, 0), isNextDay: false) == .closed, "cafeteria closed")
expect(CafeteriaPresentation.status(runningTime: "11:00~13:30", now: seoul(2026, 3, 3, 21, 0), isNextDay: true) == .upcoming(opening: "11:00"), "next day is upcoming")
let dayStart = seoul(2026, 3, 3, 0, 0)
let dayEnd = seoul(2026, 3, 3, 10, 0)
let timelineItem = CafeteriaMenuItem(cafeteriaName: "c", menus: [CafeteriaMenuRow(food: "m", price: "1000")], runningTime: "08:00~09:30")
let cafeteriaDates = CafeteriaPresentation.timelineDates(for: [timelineItem], from: dayStart, until: dayEnd, isNextDay: false)
let expectedDates = [dayStart, seoul(2026, 3, 3, 8, 0), seoul(2026, 3, 3, 9, 0), seoul(2026, 3, 3, 9, 30)]
expect(cafeteriaDates == expectedDates, "cafeteria timeline dates")
let expectedStatuses: [CafeteriaRunningStatus] = [.upcoming(opening: "08:00"), .open(closing: "09:30"), .closingSoon(closing: "09:30"), .closed]
expect(zip(cafeteriaDates, expectedStatuses).allSatisfy { date, status in CafeteriaPresentation.status(runningTime: "08:00~09:30", now: date, isNextDay: false) == status }, "cafeteria status timeline")
expect(CafeteriaPresentation.timelineDates(for: [timelineItem], from: dayStart, until: dayEnd, isNextDay: true) == [dayStart], "next day timeline only start")

func menuItem(_ count: Int) -> CafeteriaMenuItem {
    CafeteriaMenuItem(cafeteriaName: "c", menus: (0..<count).map { _ in CafeteriaMenuRow(food: "m", price: "1000") }, runningTime: "08:00~09:00")
}
expect(CafeteriaPresentation.fittingCount(of: [menuItem(13)], availableHeight: 236) == 0, "zero fit")
expect(CafeteriaPresentation.fittingCount(of: [menuItem(13), menuItem(2)], availableHeight: 236) == 0, "first oversized block prevents later fit")
expect(CafeteriaPresentation.fittingCount(of: [menuItem(5), menuItem(4)], availableHeight: 210.5) == 2, "exact fit without footer")
expect(CafeteriaPresentation.fittingCount(of: [menuItem(5), menuItem(4), menuItem(3)], availableHeight: 210.5) == 1, "footer reserved when not all fit")
expect(CafeteriaPresentation.fittingCount(of: [], availableHeight: 300) == 0, "empty fit")
expect(CafeteriaPresentation.blockHeight(menuCount: 13) == 245.5, "block height")
let xl = CafeteriaPresentation.fittingColumns(of: [menuItem(3), menuItem(14), menuItem(4)], availableHeight: 400, maxColumns: 5)
expect(xl.count == 3 && xl[1].menus.count == 14, "XL supports more than 12 menus")
let skipped = CafeteriaPresentation.fittingColumns(of: [menuItem(30), menuItem(3)], availableHeight: 400, maxColumns: 5)
expect(skipped.count == 1 && skipped[0].menus.count == 3, "XL skips oversized column")
expect(CafeteriaPresentation.fittingColumns(of: (0..<7).map { _ in menuItem(1) }, availableHeight: 400, maxColumns: 5).count == 5, "XL max columns")

print("\(failures.isEmpty ? "PASS" : "FAIL") summary: \(failures.isEmpty ? "all checks passed" : "\(failures.count) failure(s)")")
if !failures.isEmpty { exit(1) }
