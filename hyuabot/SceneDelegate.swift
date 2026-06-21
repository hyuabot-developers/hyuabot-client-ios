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
        CoachMarkManager.shared.initialize()
        ReviewRequestManager.shared.trackLaunch()
        self.showLanguageSuggestionIfNeeded()

        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(urlContext.url)
        } else if let userActivity = connectionOptions.userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb }),
                  let url = userActivity.webpageURL {
            handleDeepLink(url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeepLink(url)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        handleDeepLink(url)
    }

    private func handleDeepLink(_ url: URL) {
        guard let rootVC = window?.rootViewController as? RootVC,
              let route = routePath(for: url) else { return }
        let params = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        switch route {
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

    private func routePath(for url: URL) -> String? {
        if url.scheme == "hyuabot" {
            return url.host
        }

        guard url.scheme == "https",
              url.host == "hyuabot.app" else { return nil }
        return url.pathComponents.dropFirst().first
    }

    private func showLanguageSuggestionIfNeeded() {
        guard LanguageManager.shared.shouldShowSuggestion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.presentLanguageSuggestion()
        }
    }

    private func presentLanguageSuggestion() {
        guard let rootVC = window?.rootViewController else { return }
        LanguageManager.shared.markSuggestionShown()
        let alert = UIAlertController(
            title: String(localized: "language.suggestion.title"),
            message: String(localized: "language.suggestion.message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "language.open.settings"), style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        alert.addAction(UIAlertAction(title: String(localized: "language.keep.current"), style: .cancel))
        rootVC.present(alert, animated: true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene {
            ReviewRequestManager.shared.requestReviewIfAppropriate(in: windowScene)
        }
    }


}
