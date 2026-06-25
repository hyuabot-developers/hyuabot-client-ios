//
//  AppDelegate.swift
//  hyuabot
//
//  Created by 이정인 on 1/3/25.
//

import Firebase
import FirebaseMessaging
import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Firebase SDK
        FirebaseApp.configure()
        AnalyticsManager.applyCollectionSettings()
        // Initialize Firebase Cloud Messaging
        Messaging.messaging().delegate = self
        configureApplicationShortcuts(application)
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        // Global tab bar appearance
        let tabBarAppearance = UITabBarItem.appearance()
        tabBarAppearance.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.godo(size: 10, weight: .regular)], for: .normal)
        // Global navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance().then {
            $0.backgroundColor = .hanyangBlue
            $0.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.godo(size: 16, weight: .bold),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            $0.buttonAppearance.normal.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.godo(size: 16, weight: .regular),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            $0.backButtonAppearance.normal.titleTextAttributes = [
                NSAttributedString.Key.font: UIFont.godo(size: 16, weight: .regular),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        }
        UINavigationBar.appearance().do {
            $0.standardAppearance = navigationBarAppearance
            $0.scrollEdgeAppearance = navigationBarAppearance
            $0.compactAppearance = navigationBarAppearance
            $0.compactScrollEdgeAppearance = navigationBarAppearance
        }
        UIBarButtonItem.appearance().tintColor = .white
        return true
    }

    private func configureApplicationShortcuts(_ application: UIApplication) {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "net.jaram.hyuabot.shortcut.shuttle",
                localizedTitle: String(localized: "tabbar.shuttle"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "bus.fill"),
                userInfo: ["url": "hyuabot://shuttle" as NSSecureCoding]
            ),
            UIApplicationShortcutItem(
                type: "net.jaram.hyuabot.shortcut.cafeteria",
                localizedTitle: String(localized: "tabbar.cafeteria"),
                localizedSubtitle: String(localized: "cafeteria.lunch"),
                icon: UIApplicationShortcutIcon(systemImageName: "fork.knife"),
                userInfo: ["url": "hyuabot://cafeteria?tab=lunch" as NSSecureCoding]
            ),
            UIApplicationShortcutItem(
                type: "net.jaram.hyuabot.shortcut.readingroom",
                localizedTitle: String(localized: "tabbar.readingroom"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "book.fill"),
                userInfo: ["url": "hyuabot://reading-room" as NSSecureCoding]
            ),
            UIApplicationShortcutItem(
                type: "net.jaram.hyuabot.shortcut.map",
                localizedTitle: String(localized: "tabbar.map"),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "map.fill"),
                userInfo: ["url": "hyuabot://map" as NSSecureCoding]
            )
        ]
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after
        // application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("Failed to register for remote notifications with error: \(error)")
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "")")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        let readingRoomID = userInfo["id"] as? String
        let availableSeats = userInfo["available"] as? String
        guard let itemKey = readingRoomID, let available = availableSeats else {
            completionHandler(UIBackgroundFetchResult.noData)
            return
        }
        // Create notification
        let readingRoomName: String.LocalizationValue = switch itemKey {
        case "reading_room_1": "reading_room_1"
        case "reading_room_53": "reading_room_53"
        case "reading_room_54": "reading_room_54"
        case "reading_room_55": "reading_room_55"
        case "reading_room_56": "reading_room_56"
        case "reading_room_61": "reading_room_61"
        case "reading_room_63": "reading_room_63"
        case "reading_room_131": "reading_room_131"
        case "reading_room_132": "reading_room_132"
        default: "Unknown"
        }
        let notificationContent = UNMutableNotificationContent().then {
            $0.title = String(
                format: String(localized: "readingroom.notification.title.%@"),
                String(localized: readingRoomName)
            )
            $0.body = String(format: String(localized: "readingroom.notification.body.%@"), available)
        }
        let notificationRequest = UNNotificationRequest(identifier: "reading_room_\(itemKey)", content: notificationContent, trigger: nil)
        UNUserNotificationCenter.current().add(notificationRequest) { error in
            if let error {
                print("Error adding notification request: \(error)")
            }
        }
        // Unsubscribe from topic
        let notifiedRooms = UserDefaults.standard.stringArray(forKey: "readingRoomNotificationArray") ?? []
        if notifiedRooms.contains(itemKey) {
            UserDefaults.standard.set(notifiedRooms.filter { $0 != itemKey }, forKey: "readingRoomNotificationArray")
            Messaging.messaging().unsubscribe(fromTopic: itemKey) { _ in
                print("Unsubscribed to \(itemKey) topic")
            }
        }
        completionHandler(UIBackgroundFetchResult.noData)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        return [.list, .banner, .badge, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        if let urlString = userInfo["url"] as? String,
           let url = URL(string: urlString)
        {
            UIApplication.shared.open(url)
        }
        completionHandler()
    }
}
