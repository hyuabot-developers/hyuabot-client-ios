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
    let floatingTabBar = FloatingTabBar()

    override var selectedIndex: Int {
        didSet { syncFloatingTabBar() }
    }

    override var selectedViewController: UIViewController? {
        didSet { syncFloatingTabBar() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let navigationController = selectedViewController as? UINavigationController,
              let top = navigationController.topViewController,
              top is TodayHomeVC || top is SettingsStyledScreen
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
        guard floatingTabBar.window != nil, !floatingTabBar.isHidden else { return nil }
        return floatingTabBar.button(at: 4)
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
        shuttleNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.shuttle"), image: UIImage(systemName: "bus"), tag: 0)
        shuttleNC.tabBarItem.accessibilityIdentifier = "tab.shuttle"
        shuttleNC.updateTabBarItemForCurrentExperience()
        busNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.bus"), image: UIImage(systemName: "bus.doubledecker"), tag: 1)
        busNC.tabBarItem.accessibilityIdentifier = "tab.bus"
        subwayNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.subway"), image: UIImage(systemName: "tram"), tag: 2)
        subwayNC.tabBarItem.accessibilityIdentifier = "tab.subway"
        cafeteriaNC.tabBarItem = UITabBarItem(
            title: String(localized: "tabbar.cafeteria"),
            image: UIImage(systemName: "fork.knife"),
            tag: 3
        )
        cafeteriaNC.tabBarItem.accessibilityIdentifier = "tab.cafeteria"
        campusNC.tabBarItem = UITabBarItem(
            title: String(localized: "tabbar.campus"),
            image: UIImage(systemName: "square.grid.2x2"),
            tag: 4
        )
        campusNC.tabBarItem.accessibilityIdentifier = "tab.campus"
        delegate = self
        setViewControllers(
            [shuttleNC, busNC, subwayNC, cafeteriaNC, campusNC],
            animated: true
        )
        tabBar.isHidden = true
        configureFloatingTabBar()
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

    func refreshFloatingTabItem(for viewController: UIViewController) {
        guard let index = viewControllers?.firstIndex(where: { $0 === viewController }) else { return }
        floatingTabBar.updateItem(viewController.tabBarItem, at: index)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        hideSystemTabBar()
        view.bringSubviewToFront(floatingTabBar)
        updateChildBottomInset()
    }
}

extension RootVC: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard tabBarController.selectedViewController === viewController,
              let navigationController = viewController as? UINavigationController,
              navigationController.viewControllers.count > 1
        else { return true }
        navigationController.popToRootViewController(animated: true)
        return false
    }

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

extension RootVC {
    private func configureFloatingTabBar() {
        hideSystemTabBar()
        floatingTabBar.setItems((viewControllers ?? []).map(\.tabBarItem))
        floatingTabBar.onSelect = { [weak self] index in self?.selectTab(at: index) }
        floatingTabBar.selectedIndex = selectedIndex
        installFloatingTabBar()
        for case let navigationController as UINavigationController in viewControllers ?? [] {
            navigationController.delegate = self
        }
    }

    private func hideSystemTabBar() {
        if #available(iOS 18.0, *) {
            if !isTabBarHidden { setTabBarHidden(true, animated: false) }
        } else if !tabBar.isHidden {
            tabBar.isHidden = true
        }
    }

    private func installFloatingTabBar() {
        floatingTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(floatingTabBar)
        let guide = view.safeAreaLayoutGuide
        let preferredLeading = floatingTabBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: FloatingTabBar.sideInset)
        preferredLeading.priority = .defaultHigh
        let preferredWidth = floatingTabBar.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -2 * FloatingTabBar.sideInset)
        preferredWidth.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            floatingTabBar.heightAnchor.constraint(equalToConstant: FloatingTabBar.barHeight),
            floatingTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -FloatingTabBar.bottomInset),
            floatingTabBar.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            floatingTabBar.leadingAnchor.constraint(greaterThanOrEqualTo: guide.leadingAnchor, constant: FloatingTabBar.sideInset),
            floatingTabBar.trailingAnchor.constraint(lessThanOrEqualTo: guide.trailingAnchor, constant: -FloatingTabBar.sideInset),
            floatingTabBar.widthAnchor.constraint(lessThanOrEqualToConstant: FloatingTabBar.maxWidth),
            preferredLeading,
            preferredWidth
        ])
    }

    private func syncFloatingTabBar() {
        floatingTabBar.selectedIndex = selectedIndex
        if let nav = selectedViewController as? UINavigationController, let top = nav.topViewController {
            updateFloatingTabBarVisibility(for: nav, showing: top, animated: false)
        }
        view.setNeedsLayout()
    }

    private func selectTab(at index: Int) {
        guard let controllers = viewControllers, controllers.indices.contains(index) else { return }
        let target = controllers[index]
        guard tabBarController(self, shouldSelect: target) else { return }
        selectedViewController = target
        tabBarController(self, didSelect: target)
    }

    private func updateChildBottomInset() {
        guard let child = selectedViewController else { return }
        let covered = floatingTabBar.isHidden ? 0 : max(0, view.bounds.maxY - floatingTabBar.frame.minY)
        let systemBottom = child.view.safeAreaInsets.bottom - child.additionalSafeAreaInsets.bottom
        let wanted = max(0, covered - systemBottom)
        if abs(child.additionalSafeAreaInsets.bottom - wanted) > 0.5 {
            child.additionalSafeAreaInsets.bottom = wanted
        }
    }

    private func updateFloatingTabBarVisibility(for navigationController: UINavigationController, showing viewController: UIViewController, animated: Bool) {
        guard navigationController === selectedViewController else { return }
        let stack = navigationController.viewControllers
        let shown = stack.firstIndex { $0 === viewController }.map { Array(stack[...$0]) } ?? [viewController]
        let hidden = shown.contains { $0.hidesBottomBarWhenPushed }
        if !hidden { floatingTabBar.isHidden = false }
        let apply = { self.floatingTabBar.alpha = hidden ? 0 : 1 }
        let finish = { [weak self] in
            guard let self else { return }
            self.floatingTabBar.isHidden = hidden
            self.view.setNeedsLayout()
        }
        if animated, let coordinator = navigationController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in apply() }, completion: { _ in finish() })
        } else {
            apply()
            finish()
        }
    }
}

extension RootVC: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        updateFloatingTabBarVisibility(for: navigationController, showing: viewController, animated: animated)
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        updateFloatingTabBarVisibility(for: navigationController, showing: viewController, animated: false)
    }
}
