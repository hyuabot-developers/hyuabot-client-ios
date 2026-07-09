//
//  ShuttleServiceNoticeScheduler.swift
//  hyuabot
//

import Api
import Foundation
import UserNotifications

final class ShuttleServiceNoticeScheduler {
    static let shared = ShuttleServiceNoticeScheduler()

    private let calendar = Calendar(identifier: .gregorian)
    private let center = UNUserNotificationCenter.current()
    private let scheduledIDsKey = "shuttle.serviceNotice.scheduledIDs"

    private init() {}

    func sync() async {
        let start = Foundation.Date()
        guard let end = calendar.date(byAdding: .day, value: 30, to: start) else { return }
        let queryDateFormatter = DateFormatter().then {
            $0.calendar = calendar
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.dateFormat = "yyyy-MM-dd"
        }
        let response = try? await Network.shared.client.fetch(
            query: ShuttleServiceNoticeQuery(
                start: queryDateFormatter.string(from: start),
                end: queryDateFormatter.string(from: end)
            ),
            cachePolicy: .networkOnly
        )
        guard let notices = response?.data?.shuttle.serviceNotices else { return }

        let oldIDs = UserDefaults.standard.stringArray(forKey: scheduledIDsKey) ?? []
        center.removePendingNotificationRequests(withIdentifiers: oldIDs)
        notices.forEach(schedule)
        let noticeIDs: [String] = notices.map(\.id)
        UserDefaults.standard.set(noticeIDs, forKey: scheduledIDsKey)
    }

    private func schedule(_ notice: ShuttleServiceNoticeQuery.Data.Shuttle.ServiceNotice) {
        guard let noticeDate = notice.date.toLocalDateOrNil(),
              let triggerDate = triggerDate(for: noticeDate)
        else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "shuttle.service_notice.title")
        content.body = bodyText(for: notice, date: noticeDate)
        content.sound = .default
        content.userInfo = ["url": "hyuabot://shuttle"]

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: notice.id, content: content, trigger: trigger))
    }

    private func triggerDate(for date: Foundation.Date) -> Foundation.Date? {
        let now = Foundation.Date()
        let preferred = calendar.date(byAdding: .day, value: -1, to: date).flatMap {
            calendar.date(bySettingHour: 9, minute: 0, second: 0, of: $0)
        }
        let fallback = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)
        if let preferred, preferred > now {
            return preferred
        }
        if let fallback, fallback > now {
            return fallback
        }
        return nil
    }

    private func bodyText(for notice: ShuttleServiceNoticeQuery.Data.Shuttle.ServiceNotice, date: Foundation.Date) -> String {
        let dateText = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        switch notice.kind {
        case "period":
            return String(
                format: String(localized: "shuttle.service_notice.period.body"),
                dateText,
                periodName(notice.period?.type)
            )
        case "holiday":
            let bodyKey = notice.holiday?.type == "halt"
                ? "shuttle.service_notice.halt.body"
                : "shuttle.service_notice.holiday.body"
            return String(
                format: String(localized: String.LocalizationValue(bodyKey)),
                dateText
            )
        default:
            return String(format: String(localized: "shuttle.service_notice.generic.body"), dateText)
        }
    }

    private func periodName(_ type: String?) -> String {
        switch type {
        case "semester":
            String(localized: "shuttle.service_notice.period.semester")
        case "vacation":
            String(localized: "shuttle.service_notice.period.vacation")
        case "vacation_session":
            String(localized: "shuttle.service_notice.period.session")
        default:
            String(localized: "shuttle.service_notice.period.unknown")
        }
    }
}
