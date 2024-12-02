//
//  AppDelegate.swift
//  hyuabot
//
//  Created by 이정인 on 12/2/24.
//

import UIKit
import FirebaseCore
import FirebaseMessaging


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
