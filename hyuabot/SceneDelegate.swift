//
//  SceneDelegate.swift
//  hyuabot
//
//  Created by 이정인 on 1/3/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let theme = UserDefaults.standard.integer(forKey: "themeID")
        if theme == 0 {
            window.overrideUserInterfaceStyle = .unspecified
        } else if theme == 1 {
            window.overrideUserInterfaceStyle = .light
        } else {
            window.overrideUserInterfaceStyle = .dark
        }
        let vc = RootVC()
        window.rootViewController = vc
        window.makeKeyAndVisible()
        self.window = window

        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "hyuabot",
              let rootVC = window?.rootViewController as? RootVC else { return }
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        switch url.host {
        case "cafeteria":
            rootVC.selectedIndex = 3
            let tab = params?.first(where: { $0.name == "tab" })?.value
            let tabIndex: Int? = switch tab {
                case "breakfast": 0
                case "lunch": 1
                case "dinner": 2
                default: nil
            }
            if let index = tabIndex {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let nc = rootVC.viewControllers?[3] as? UINavigationController,
                       let vc = nc.viewControllers.first as? CafeteriaVC {
                        vc.scrollToMealTab(index)
                    }
                }
            }

        case "shuttle":
            rootVC.selectedIndex = 0
            let stop = params?.first(where: { $0.name == "stop" })?.value
            if let stop {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let nc = rootVC.viewControllers?[0] as? UINavigationController,
                       let vc = nc.viewControllers.first as? ShuttleRealtimeVC {
                        vc.scrollToStop(stop)
                    }
                }
            }

        default:
            break
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

