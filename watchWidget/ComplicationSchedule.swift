import Foundation

/// Pure schedule logic for the watch complication. No WidgetKit or network types live here so it can be verified in isolation.
enum ComplicationLanguage: String {
    case ko, en, ja, zh

    static var current: ComplicationLanguage {
        ComplicationLanguage(rawValue: Locale.current.language.languageCode?.identifier ?? "ko") ?? .ko
    }
}

struct ComplicationStop: Equatable {
    let id: String
    /// Timetable stop names queried for this stop. Each complication stop maps to exactly one query stop.
    /// The shuttlecock complication shows outbound departures only; the watch app list still shows both directions.
    let queryStops: [String]
}

enum ComplicationStops {
    static let all: [ComplicationStop] = [
        ComplicationStop(id: "dormitory", queryStops: ["dormitory_o"]),
        ComplicationStop(id: "shuttlecock", queryStops: ["shuttlecock_o"]),
        ComplicationStop(id: "station", queryStops: ["station"]),
        ComplicationStop(id: "terminal", queryStops: ["terminal"]),
        ComplicationStop(id: "jungang", queryStops: ["jungang_stn"])
    ]

    static func find(_ id: String) -> ComplicationStop? {
        all.first(where: { $0.id == id })
    }
}

/// One scheduled departure.
struct Departure: Codable, Equatable, Sendable {
    let date: Date
    let routeTag: String
    let routeName: String
}

/// Departures the complication can vouch for. `coverageEnd == nil` means the timetable was not truncated, so an empty
/// list after the last departure is a confirmed end of service. A non-nil value means departures after that instant are
/// unknown, so an empty list there must not be presented as "no more shuttles".
struct KnownSchedule: Codable, Equatable, Sendable {
    let departures: [Departure]
    let coverageEnd: Date?
}

/// One raw timetable row from the backend, before KST date resolution.
struct TimetableRow: Equatable, Sendable {
    let localTime: String
    let routeTag: String
    let routeName: String
}

/// The backend response for one queried stop name.
struct StopTimetableResult: Equatable, Sendable {
    let stopName: String
    let rows: [TimetableRow]
}

enum ComplicationCoverage {
    /// Per-stop `order` cap sent with every timetable query. The backend honors it (`order` truncates the list; `destination` does not).
    static let fetchLimit = 10

    /// Combines per-stop results into one schedule. A stop whose response filled the `fetchLimit` is truncated: its
    /// departures after its last returned row are unknown, so the combined schedule is cut at the earliest such horizon.
    static func assemble(results: [StopTimetableResult], day: Date, limit: Int = fetchLimit) -> KnownSchedule {
        var coverageEnd: Date?
        var dated: [Departure] = []

        for result in results {
            let rowDates = result.rows.compactMap { row -> (Date, TimetableRow)? in
                guard let date = ShuttleClock.departureDate(localTime: row.localTime, on: day) else { return nil }
                return (date, row)
            }
            if result.rows.count >= limit, let horizon = rowDates.map(\.0).max() {
                coverageEnd = min(coverageEnd ?? horizon, horizon)
            }
            dated += rowDates.map { Departure(date: $0.0, routeTag: $0.1.routeTag, routeName: $0.1.routeName) }
        }

        let known = dated
            .filter { departure in coverageEnd.map { departure.date <= $0 } ?? true }
            .sorted(by: { $0.date < $1.date })
        return KnownSchedule(departures: known, coverageEnd: coverageEnd)
    }
}

/// Countdown wording shared by the families. Minutes are rounded up so a bus 61 seconds away reads as 2 minutes.
struct Countdown {
    let value: String
    let unit: String
    let long: String
    let short: String

    init(departure: Departure, at date: Date) {
        let seconds = departure.date.timeIntervalSince(date)
        if seconds < 60 {
            value = ComplicationText.text("now")
            unit = ""
            long = ComplicationText.text("now")
            short = ComplicationText.text("now")
        } else {
            let minutes = Int(ceil(seconds / 60))
            value = "\(minutes)"
            unit = ComplicationText.text("minutesUnit")
            long = String(format: ComplicationText.text("minutes"), minutes)
            short = "\(minutes)\(ComplicationText.text("minutesUnit"))"
        }
    }
}

enum ShuttleClock {
    /// LocalTime values from the backend are wall-clock times in Korea, so all parsing and display uses KST.
    static let timeZone = TimeZone(identifier: "Asia/Seoul")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// `HH:mm` in KST, used for the `after` filter of the timetable query and for display.
    static func queryTime(_ date: Date) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    static func displayTime(_ date: Date) -> String {
        queryTime(date)
    }

    /// Converts a backend `HH:mm` or `HH:mm:ss` value into an absolute date on the KST day containing `day`.
    /// Hours above 23 are allowed because late-night timetables can roll past midnight.
    static func departureDate(localTime: String, on day: Date) -> Date? {
        let parts = localTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        let seconds = parts[0] * 3600 + parts[1] * 60 + (parts.count > 2 ? parts[2] : 0)
        return calendar.date(byAdding: .second, value: seconds, to: calendar.startOfDay(for: day))
    }
}

enum ComplicationText {
    private static let table: [String: [ComplicationLanguage: String]] = [
        "placeholder": [.ko: "셔틀", .en: "Shuttle", .ja: "シャトル", .zh: "校车"],
        "noStop": [.ko: "정류장을 선택하세요", .en: "Choose a stop", .ja: "停留所を選択", .zh: "请选择车站"],
        "offline": [.ko: "오프라인", .en: "Offline", .ja: "オフライン", .zh: "离线"],
        "empty": [.ko: "운행 종료", .en: "No more shuttles", .ja: "本日の運行終了", .zh: "今日已无班车"],
        "updating": [.ko: "갱신 중", .en: "Updating", .ja: "更新中", .zh: "更新中"],
        "now": [.ko: "지금", .en: "Now", .ja: "今", .zh: "现在"],
        "stale": [.ko: "오래된 정보", .en: "Outdated", .ja: "古い情報", .zh: "信息过期"],
        "minutes": [.ko: "%d분", .en: "%d min", .ja: "%d分", .zh: "%d分钟"],
        "minutesUnit": [.ko: "분", .en: "min", .ja: "分", .zh: "分钟"],
        "route.circular": [.ko: "순환", .en: "Circular", .ja: "循環", .zh: "循环"],
        "route.direct": [.ko: "직행", .en: "Direct", .ja: "直行", .zh: "直达"],
        "stop.dormitory": [.ko: "기숙사", .en: "Dormitory", .ja: "寮", .zh: "宿舍"],
        "stop.shuttlecock": [.ko: "셔틀콕", .en: "Shuttlecock", .ja: "シャトルコック", .zh: "羽毛球场"],
        "stop.station": [.ko: "한대앞", .en: "Station", .ja: "韓大前駅", .zh: "汉大前站"],
        "stop.terminal": [.ko: "예술인", .en: "Terminal", .ja: "芸術人村", .zh: "艺术人村"],
        "stop.jungang": [.ko: "중앙역", .en: "Jungang Stn.", .ja: "中央駅", .zh: "中央站"]
    ]

    static func text(_ key: String, _ language: ComplicationLanguage = .current) -> String {
        table[key]?[language] ?? table[key]?[.ko] ?? key
    }

    static func stopName(_ stopID: String, _ language: ComplicationLanguage = .current) -> String {
        text("stop.\(stopID)", language)
    }

    /// Line label for one timetable row, resolved by `ShuttleLineLabel`. Returns "" when the row has no label,
    /// so the caller keeps the countdown layout and shows nothing in the label slot.
    /// The raw route code and the 직행 text are never returned.
    static func routeLabel(stopID: String, routeTag: String, routeName: String, _ language: ComplicationLanguage = .current) -> String {
        guard let label = ShuttleLineLabel.resolve(complicationStopID: stopID, routeTag: routeTag, routeName: routeName) else {
            return ""
        }
        return text(label.localizationKey, language)
    }
}

/// What the complication renders at one instant.
struct ComplicationSnapshot: Equatable, Sendable {
    enum Status: Equatable, Sendable {
        /// Sample content for the gallery and placeholder.
        case placeholder
        /// No stop has been chosen on the watch yet.
        case noStop
        /// No schedule is available at all (no fetch yet, or the cache is too old).
        case offline
        /// The timetable is complete for the day and there are no departures left.
        case empty
        /// Departures are known for this instant.
        case departures
        /// Departures cannot be confirmed here: the fetch was truncated or the cache is stale.
        case unknown
        /// The timeline window ended. Shown instead of a countdown that WidgetKit could leave on screen if a reload is delayed.
        case expired
    }

    let date: Date
    let status: Status
    let stopID: String?
    /// Enough upcoming departures to pick one per route. Each view decides how many to show.
    static let maxUpcoming = 10

    /// The next departures after `date`, nearest first (at most `maxUpcoming`).
    let upcoming: [Departure]
    let isStale: Bool

    static func placeholder(at date: Date) -> ComplicationSnapshot {
        ComplicationSnapshot(
            date: date, status: .placeholder, stopID: "dormitory",
            upcoming: [
                Departure(date: date.addingTimeInterval(5 * 60), routeTag: "C", routeName: ""),
                Departure(date: date.addingTimeInterval(25 * 60), routeTag: "C", routeName: "")
            ],
            isStale: false
        )
    }
}

enum ComplicationTimeline {
    /// Entries cover this window; the timeline is rebuilt when it ends.
    static let window: TimeInterval = 15 * 60
    /// Retry sooner after a failed fetch so offline states recover quickly.
    static let retryInterval: TimeInterval = 5 * 60

    /// Builds per-minute and per-departure entries inside the window, so countdowns advance without network calls.
    /// The final entry sits at the end of the window and never shows a countdown: if WidgetKit delays the next reload,
    /// the complication shows "updating" instead of a positive countdown that has gone stale.
    static func snapshots(now: Date, stopID: String?, schedule: KnownSchedule?, isStale: Bool) -> [ComplicationSnapshot] {
        guard let stopID else {
            return [ComplicationSnapshot(date: now, status: .noStop, stopID: nil, upcoming: [], isStale: false)]
        }
        guard let schedule else {
            return [ComplicationSnapshot(date: now, status: .offline, stopID: stopID, upcoming: [], isStale: false)]
        }

        let future = schedule.departures.filter { $0.date > now }
        let end = now.addingTimeInterval(window)

        var transitions: Set<Date> = [now]
        var minute = nextMinuteBoundary(after: now)
        while minute < end {
            transitions.insert(minute)
            minute = minute.addingTimeInterval(60)
        }
        for departure in future where departure.date < end {
            transitions.insert(departure.date)
        }
        if let coverageEnd = schedule.coverageEnd, coverageEnd > now, coverageEnd < end {
            transitions.insert(coverageEnd)
        }

        var snapshots = transitions.sorted().map { time -> ComplicationSnapshot in
            let upcoming = future.filter { $0.date > time }
            return ComplicationSnapshot(
                date: time,
                status: status(upcoming: upcoming, schedule: schedule, isStale: isStale),
                stopID: stopID,
                upcoming: Array(upcoming.prefix(ComplicationSnapshot.maxUpcoming)),
                isStale: isStale
            )
        }

        snapshots.append(ComplicationSnapshot(date: end, status: .expired, stopID: stopID, upcoming: [], isStale: isStale))
        return snapshots
    }

    private static func status(upcoming: [Departure], schedule: KnownSchedule, isStale: Bool) -> ComplicationSnapshot.Status {
        if !upcoming.isEmpty { return .departures }
        if schedule.coverageEnd == nil && !isStale { return .empty }
        return .unknown
    }

    /// When WidgetKit should rebuild the timeline: at the window end, or earlier if the known timetable runs out first.
    static func refreshDate(now: Date, coverageEnd: Date?) -> Date {
        let windowEnd = now.addingTimeInterval(window)
        guard let coverageEnd, coverageEnd > now else { return windowEnd }
        return min(coverageEnd, windowEnd)
    }

    static func nextMinuteBoundary(after date: Date) -> Date {
        let floor = ShuttleClock.calendar.dateInterval(of: .minute, for: date)?.start ?? date
        return floor.addingTimeInterval(60)
    }
}
