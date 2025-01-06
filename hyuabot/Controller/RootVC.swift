import UIKit
import SafariServices
import Then

class RootVC: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        // TabBar
        shuttleNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.shuttle"), image: UIImage(systemName: "bus.fill"), tag: 0)
        busNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.bus"), image: UIImage(systemName: "bus.doubledecker.fill"), tag: 1)
        subwayNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.subway"), image: UIImage(systemName: "tram.fill"), tag: 2)
        cafeteriaNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.cafeteria"), image: UIImage(systemName: "fork.knife"), tag: 3)
        mapNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.map"), image: UIImage(systemName: "map.fill"), tag: 4)
        readingRoomNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.readingroom"), image: UIImage(systemName: "book.fill"), tag: 5)
        contactNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.contact"), image: UIImage(systemName: "person.fill"), tag: 6)
        calendarNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.calendar"), image: UIImage(systemName: "calendar"), tag: 7)
        settingNC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.setting"), image: UIImage(systemName: "gear"), tag: 8)
        chatVC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.chat"), image: UIImage(systemName: "message.fill"), tag: 9)
        donateVC.tabBarItem = UITabBarItem(title: String(localized: "tabbar.donate"), image: UIImage(systemName: "heart.fill"), tag: 10)
        // More NavigationController Appearance
        let moreTitleAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [type(of: self.moreNavigationController)])
        moreTitleAppearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.godo(size: 16, weight: .bold)]
        let moreEditButtonAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [type(of: self.moreNavigationController)])
        moreEditButtonAppearance.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.godo(size: 16, weight: .regular)], for: .normal)
        if let moreTableVC = self.moreNavigationController.topViewController?.view as? UITableView {
            moreTableVC.visibleCells.forEach { $0.textLabel?.font = UIFont.godo(size: 14, weight: .regular) }
        }
        self.setViewControllers([shuttleNC, busNC, subwayNC, cafeteriaNC, mapNC, readingRoomNC, contactNC, calendarNC, settingNC, chatVC, donateVC], animated: true)
    }
}
