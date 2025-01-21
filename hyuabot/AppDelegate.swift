//
//  AppDelegate.swift
//  hyuabot
//
//  Created by 이정인 on 1/3/25.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseMessaging


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Firebase SDK
        FirebaseApp.configure()
        // Initialize Firebase Cloud Messaging
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
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

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
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
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
            
        return [.banner, .badge, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse) async {
    }
}

