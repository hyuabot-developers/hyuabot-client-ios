import UIKit
import SafariServices
import Then

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

    override func viewDidLoad() {
        super.viewDidLoad()
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
        if let moreTableView = self.moreNavigationController.viewControllers.first?.view as? UITableView {
            moreTableView.delegate = self
        }
        self.setViewControllers([shuttleNC, busNC, subwayNC, cafeteriaNC, mapNC, readingRoomNC, contactNC, calendarNC, settingNC, chatVC, donateVC], animated: true)
    }
}

extension RootVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.font = UIFont.godo(size: 16, weight: .regular)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell?.textLabel?.text {
        case String(localized: "tabbar.shuttle"):
            self.selectedViewController = shuttleNC
        case String(localized: "tabbar.bus"):
            self.selectedViewController = busNC
        case String(localized: "tabbar.subway"):
            self.selectedViewController = subwayNC
        case String(localized: "tabbar.cafeteria"):
            self.selectedViewController = cafeteriaNC
        case String(localized: "tabbar.map"):
            self.selectedViewController = mapNC
        case String(localized: "tabbar.readingroom"):
            self.selectedViewController = readingRoomNC
        case String(localized: "tabbar.contact"):
            self.selectedViewController = contactNC
        case String(localized: "tabbar.calendar"):
            self.selectedViewController = calendarNC
        case String(localized: "tabbar.setting"):
            self.selectedViewController = settingNC
        case String(localized: "tabbar.chat"):
            self.selectedViewController = chatVC
        case String(localized: "tabbar.donate"):
            self.selectedViewController = donateVC
        default:
            break
        }
    }
}
