import SwiftUI
import UIKit

class RootVC: UITabBarController {
    // NavigationController for each Tab
    let shuttleNC = ShuttleNC()
    let busNC = BusNC()
    let subwayNC = SubwayNC()
    let cafeteriaNC = CafeteriaNC()
    let campusNC = CampusNC()
    private var translationPreparationHost: UIViewController?
    private var isWaitingForShuttleCoachMarksAfterReset = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let navigationController = selectedViewController as? UINavigationController,
              navigationController.topViewController is TodayHomeVC
        else {
            return .lightContent
        }
        return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
    }

    override var childForStatusBarStyle: UIViewController? {
        nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        installTranslationPreparationHostIfNeeded()
        retryShuttleCoachMarksIfNeeded()
        // Shuttle marks already shown on a previous launch — show immediately
        if !isWaitingForShuttleCoachMarksAfterReset,
           !CoachMarkManager.shared.shouldShowPage("shuttle.realtime")
        {
            showCampusCoachMarkIfNeeded()
        }
    }

    @objc private func onCoachMarkPageShown(_ notification: Notification) {
        guard let pageId = notification.userInfo?["pageId"] as? String,
              pageId == "shuttle.realtime" else { return }
        isWaitingForShuttleCoachMarksAfterReset = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.showCampusCoachMarkIfNeeded()
        }
    }

    @objc private func onCoachMarkReset() {
        isWaitingForShuttleCoachMarksAfterReset = true
    }

    private func retryShuttleCoachMarksIfNeeded() {
        guard selectedViewController === shuttleNC,
              let shuttleVC = shuttleNC.viewControllers.first as? ShuttleRealtimeVC else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shuttleVC.retryCoachMarksIfNeeded()
        }
    }

    func showCampusCoachMarkIfNeeded() {
        presentCoachMarks(pageId: "root.campus", items: [
            CoachMarkItem(
                id: "root.campus",
                targetViewProvider: { [weak self] in self?.campusButtonView },
                title: String(localized: "coach.root.campus.title"),
                message: String(localized: "coach.root.more.message")
            )
        ])
    }

    private var campusButtonView: UIView? {
        guard tabBar.bounds.width > 0 else { return nil }
        let slotWidth = tabBar.bounds.width / 5
        let point = CGPoint(x: slotWidth * 4.5, y: tabBar.bounds.midY)
        return tabBar.hitTest(point, with: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCoachMarkPageShown(_:)),
            name: .coachMarkPageShown,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCoachMarkReset),
            name: .coachMarkReset,
            object: nil
        )
        // TabBar
        shuttleNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.shuttle"), image: UIImage(systemName: "bus.fill"), tag: 0)
        shuttleNC.tabBarItem.accessibilityIdentifier = "tab.shuttle"
        shuttleNC.updateTabBarItemForCurrentExperience()
        busNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.bus"), image: UIImage(systemName: "bus.doubledecker.fill"), tag: 1)
        busNC.tabBarItem.accessibilityIdentifier = "tab.bus"
        subwayNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.subway"), image: UIImage(systemName: "tram.fill"), tag: 2)
        subwayNC.tabBarItem.accessibilityIdentifier = "tab.subway"
        cafeteriaNC.tabBarItem = UITabBarItem(
            title: String(localized: "tabbar.cafeteria"),
            image: UIImage(systemName: "fork.knife"),
            tag: 3
        )
        cafeteriaNC.tabBarItem.accessibilityIdentifier = "tab.cafeteria"
        campusNC.tabBarItem = UITabBarItem(
            title: String(localized: "tabbar.campus"),
            image: UIImage(systemName: "square.grid.2x2.fill"),
            tag: 4
        )
        campusNC.tabBarItem.accessibilityIdentifier = "tab.campus"
        delegate = self
        setViewControllers(
            [shuttleNC, busNC, subwayNC, cafeteriaNC, campusNC],
            animated: true
        )
        // Appearance
        UITabBar.appearance().backgroundColor = .systemBackground
    }

    private func installTranslationPreparationHostIfNeeded() {
        guard #available(iOS 26.0, *), translationPreparationHost == nil else { return }

        let host = UIHostingController(rootView: TranslationPreparationView())
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.widthAnchor.constraint(equalToConstant: 1),
            host.view.heightAnchor.constraint(equalToConstant: 1),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        host.didMove(toParent: self)
        translationPreparationHost = host
    }

    /// Maps a tab's view controller to its analytics item for tab-switch tracking.
    func analyticsItem(for viewController: UIViewController?) -> AnalyticsItem? {
        switch viewController {
        case shuttleNC: HomeExperienceManager.isEnabled ? .tabHome : .tabShuttle
        case busNC: .tabBus
        case subwayNC: .tabSubway
        case cafeteriaNC: .tabCafeteria
        case campusNC: .tabCampus
        default: nil
        }
    }

    func openCampus(_ destination: CampusDestination, animated: Bool = false) {
        selectedViewController = campusNC
        campusNC.open(destination, animated: animated)
    }
}

extension RootVC: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let item = analyticsItem(for: viewController) {
            AnalyticsManager.logSelect(item, type: .tab)
        }
        setNeedsStatusBarAppearanceUpdate()
        if viewController === shuttleNC {
            retryShuttleCoachMarksIfNeeded()
        }
    }
}
