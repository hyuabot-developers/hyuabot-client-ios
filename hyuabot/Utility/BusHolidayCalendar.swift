//
//  BusHolidayCalendar.swift
//  hyuabot
//

import Api
import Foundation

/// Route buses run the Sunday timetable on public holidays. This set feeds
/// BusRecentDates day types; until it loads, an empty set uses plain weekday,
/// Saturday, and Sunday classification. The poll never awaits this load.
@MainActor
final class BusHolidayCalendar {
    typealias Fetcher = @Sendable (_ start: String, _ end: String) async throws -> [String]

    static let shared = BusHolidayCalendar(fetcher: BusHolidayCalendar.networkFetcher)
    nonisolated static let lookbackDays = 36
    nonisolated static let retryInterval: TimeInterval = 300

    nonisolated static let networkFetcher: Fetcher = { start, end in
        let response = try await Network.shared.client.fetch(
            query: PublicHolidayQuery(start: start, end: end),
            cachePolicy: .networkOnly
        )
        if let errors = response.errors, !errors.isEmpty {
            throw BusHolidayCalendarError.graphQLErrors
        }
        guard let data = response.data else {
            throw BusHolidayCalendarError.missingData
        }
        return data.publicHolidays
    }

    private let fetcher: Fetcher
    private var calendar: Calendar
    private let formatter: DateFormatter
    private(set) var holidays: Set<String> = []
    private var loadedDayKey: String?
    private var isLoading = false
    private var lastFailureAt: Foundation.Date?

    init(fetcher: @escaping Fetcher, calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.fetcher = fetcher
        var seoulCalendar = calendar
        seoulCalendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        self.calendar = seoulCalendar
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = seoulCalendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        formatter = dateFormatter
    }

    @discardableResult
    func refreshIfNeeded(now: Foundation.Date = .now, onChange: (@MainActor () -> Void)? = nil) -> Task<Void, Never>? {
        let todayKey = formatter.string(from: now)
        guard loadedDayKey != todayKey, !isLoading else { return nil }
        if let lastFailureAt, now.timeIntervalSince(lastFailureAt) < Self.retryInterval { return nil }
        let today = calendar.startOfDay(for: now)
        let startDate = calendar.date(byAdding: .day, value: -Self.lookbackDays, to: today) ?? today
        let endDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)
        isLoading = true
        return Task { @MainActor in
            defer { isLoading = false }
            do {
                let list = try await fetcher(start, end)
                let newSet = Set(list)
                let changed = newSet != holidays
                holidays = newSet
                loadedDayKey = todayKey
                lastFailureAt = nil
                if changed { onChange?() }
            } catch {
                lastFailureAt = now
            }
        }
    }
}

enum BusHolidayCalendarError: Error {
    case graphQLErrors
    case missingData
}
