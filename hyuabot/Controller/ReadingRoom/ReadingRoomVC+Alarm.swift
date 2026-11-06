//
//  ReadingRoomVC+Alarm.swift
//  hyuabot
//

import RxSwift
import UIKit
import UserNotifications

extension ReadingRoomVC {
    func scheduleLocalAlarm(hours: Int) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            guard granted, let self else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reading_room_extend_alarm"])
            let triggerMinutes = hours * 60 - 10
            let content = UNMutableNotificationContent()
            content.title = String(localized: "reading_room.alarm.notification.title")
            content.body = String(localized: "reading_room.alarm.notification.body")
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(triggerMinutes * 60), repeats: false)
            let request = UNNotificationRequest(
                identifier: "reading_room_extend_alarm",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
            DispatchQueue.main.async {
                let alarmTime = Foundation.Date().addingTimeInterval(TimeInterval(triggerMinutes * 60))
                UserDefaults.standard.set(alarmTime.timeIntervalSince1970, forKey: "readingRoomExtendAlarmTime")
                UserDefaults.standard.set(hours, forKey: "readingRoomExtendAlarmHours")
                self.updateAlarmUI(alarmTime: alarmTime)
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let message = String(
                    format: String(localized: "toast.readingroom.alarm.scheduled.%@"),
                    formatter.string(from: alarmTime)
                )
                SettingsToastView.show(message: message, in: self.toastContainer, icon: .bell)
                AnalyticsManager.logSelect(.readingRoomAlarmToggle, type: .toggle)
            }
        }
    }

    func cancelLocalAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reading_room_extend_alarm"])
        UserDefaults.standard.removeObject(forKey: "readingRoomExtendAlarmTime")
        UserDefaults.standard.removeObject(forKey: "readingRoomExtendAlarmHours")
        updateAlarmUI(alarmTime: nil)
        SettingsToastView.show(message: String(localized: "toast.readingroom.alarm.cancelled"), in: toastContainer, icon: .bell)
        AnalyticsManager.logSelect(.readingRoomAlarmToggle, type: .toggle)
    }

    func updateAlarmUI(alarmTime: Foundation.Date?) {
        let storedHours = UserDefaults.standard.integer(forKey: "readingRoomExtendAlarmHours")
        alarmCard.setSchedule(alarmTime.map { ReadingRoomAlarmSchedule(notifyAt: $0, hours: storedHours > 0 ? storedHours : nil) })
        view.setNeedsLayout()
    }

    func restoreAlarmUI() {
        let savedTimestamp = UserDefaults.standard.double(forKey: "readingRoomExtendAlarmTime")
        guard savedTimestamp > 0 else { updateAlarmUI(alarmTime: nil); return }
        let alarmTime = Foundation.Date(timeIntervalSince1970: savedTimestamp)
        if alarmTime > Foundation.Date() {
            updateAlarmUI(alarmTime: alarmTime)
        } else {
            UserDefaults.standard.removeObject(forKey: "readingRoomExtendAlarmTime")
            UserDefaults.standard.removeObject(forKey: "readingRoomExtendAlarmHours")
            updateAlarmUI(alarmTime: nil)
        }
    }

    func showCoachMarksIfNeeded() {
        guard CoachMarkManager.shared.shouldShowPage("readingroom") else { return }
        if let items = try? roomSubject.value(), !items.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.presentListCoachMark()
            }
            return
        }
        roomSubject.filter { !$0.isEmpty }.take(1).observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.presentListCoachMark()
                }
            }).disposed(by: disposeBag)
    }

    func presentListCoachMark() {
        presentCoachMarks(pageId: "readingroom", items: [
            CoachMarkItem(
                id: "readingroom.list",
                targetView: statusRow,
                title: String(localized: "coach.readingroom.list.title"),
                message: String(localized: "coach.readingroom.list.message")
            ),
            CoachMarkItem(id: "readingroom.alarm", targetViewProvider: { [weak self] in
                let ip = IndexPath(row: 0, section: 0)
                return (self?.readingRoomView.cellForRow(at: ip) as? ReadingRoomCellView)?.alarmButton
            },
                title: String(localized: "coach.readingroom.alarm.title"),
                message: String(localized: "coach.readingroom.alarm.message")
            ),
            CoachMarkItem(
                id: "readingroom.extend_alarm",
                targetView: alarmCard,
                title: String(localized: "coach.readingroom.extend_alarm.title"),
                message: String(localized: "coach.readingroom.extend_alarm.message")
            )
        ], shouldMarkAsShown: true, onComplete: { CoachMarkManager.shared.markPageShown("readingroom") })
    }
}
