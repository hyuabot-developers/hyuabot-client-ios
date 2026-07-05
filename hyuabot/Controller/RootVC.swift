import SafariServices
import SwiftUI
import Then
import UIKit

class RootVC: UITabBarController {
    // NavigationController for each Tab
    let shuttleNC = ShuttleNC()
    let busNC = BusNC()
    let subwayNC = SubwayNC()
    let cafeteriaNC = CafeteriaNC()
    let mapNC = MapNC()
    let readingRoomNC = ReadingRoomNC()
    let contactNC = ContactNC()
    let calendarNC = CalendarNC()
    let settingNC = SettingNC()
    let chatVC = WebViewVC(url: URL(string: "https://open.kakao.com/o/sW2kAinb")!)
    let donateVC = WebViewVC(url: URL(string: "https://qr.kakaopay.com/FWxVPo8iO")!)
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
            showMoreCoachMarkIfNeeded()
        }
    }

    @objc private func onCoachMarkPageShown(_ notification: Notification) {
        guard let pageId = notification.userInfo?["pageId"] as? String,
              pageId == "shuttle.realtime" else { return }
        isWaitingForShuttleCoachMarksAfterReset = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.showMoreCoachMarkIfNeeded()
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

    func showMoreCoachMarkIfNeeded() {
        presentCoachMarks(pageId: "root.more", items: [
            CoachMarkItem(
                id: "root.more",
                targetViewProvider: { [weak self] in self?.moreButtonView },
                title: String(localized: "coach.root.more.title"),
                message: String(localized: "coach.root.more.message")
            )
        ])
    }

    private var moreButtonView: UIView? {
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
        mapNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.map"), image: UIImage(systemName: "map.fill"), tag: 4)
        mapNC.tabBarItem.accessibilityIdentifier = "tab.map"
        readingRoomNC.tabBarItem = UITabBarItem(
            title: String(localized: "tabbar.readingroom"),
            image: UIImage(systemName: "book.fill"),
            tag: 5
        )
        readingRoomNC.tabBarItem.accessibilityIdentifier = "tab.readingroom"
        contactNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.contact"), image: UIImage(systemName: "person.fill"), tag: 6)
        contactNC.tabBarItem.accessibilityIdentifier = "tab.contact"
        calendarNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.calendar"), image: UIImage(systemName: "calendar"), tag: 7)
        calendarNC.tabBarItem.accessibilityIdentifier = "tab.calendar"
        settingNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.setting"), image: UIImage(systemName: "gear"), tag: 8)
        settingNC.tabBarItem.accessibilityIdentifier = "tab.setting"
        chatVC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.chat"), image: UIImage(systemName: "message.fill"), tag: 9)
        chatVC.tabBarItem.accessibilityIdentifier = "tab.chat"
        donateVC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.donate"), image: UIImage(systemName: "heart.fill"), tag: 10)
        donateVC.tabBarItem.accessibilityIdentifier = "tab.donate"
        if let moreTableView = moreNavigationController.viewControllers.first?.view as? UITableView {
            moreTableView.delegate = self
            moreTableView.tintColor = .plainButtonText
        }
        delegate = self
        setViewControllers(
            [shuttleNC, busNC, subwayNC, cafeteriaNC, mapNC, readingRoomNC, contactNC, calendarNC, settingNC, chatVC, donateVC],
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
        case shuttleNC: .tabShuttle
        case busNC: .tabBus
        case subwayNC: .tabSubway
        case cafeteriaNC: .tabCafeteria
        case mapNC: .tabMap
        case readingRoomNC: .tabReadingRoom
        case contactNC: .tabContact
        case calendarNC: .tabCalendar
        case settingNC: .tabSetting
        case chatVC: .tabChat
        case donateVC: .tabDonate
        default: nil
        }
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

extension RootVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont.godo(size: 16, weight: .regular)
        cell.textLabel?.textColor = .label
        cell.imageView?.tintColor = .plainButtonText
        cell.tintColor = .plainButtonText
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell?.textLabel?.text {
        case String(localized: "tabbar.shuttle"):
            selectedViewController = shuttleNC
            retryShuttleCoachMarksIfNeeded()
        case String(localized: "tabbar.bus"):
            selectedViewController = busNC
        case String(localized: "tabbar.subway"):
            selectedViewController = subwayNC
        case String(localized: "tabbar.cafeteria"):
            selectedViewController = cafeteriaNC
        case String(localized: "tabbar.map"):
            selectedViewController = mapNC
        case String(localized: "tabbar.readingroom"):
            selectedViewController = readingRoomNC
        case String(localized: "tabbar.contact"):
            selectedViewController = contactNC
        case String(localized: "tabbar.calendar"):
            selectedViewController = calendarNC
        case String(localized: "tabbar.setting"):
            selectedViewController = settingNC
        case String(localized: "tabbar.chat"):
            selectedViewController = chatVC
        case String(localized: "tabbar.donate"):
            selectedViewController = donateVC
        default:
            break
        }
        if let item = analyticsItem(for: selectedViewController) {
            AnalyticsManager.logSelect(item, type: .tab)
        }
    }
}
