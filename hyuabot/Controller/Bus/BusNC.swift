import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }
    
    func moveToTimetableVC(stopID: Int, routes: [Int], title: String.LocalizationValue) {
        let vc = BusTimetableVC(stopID: stopID, routes: routes, title: title)
        self.pushViewController(vc, animated: false)
    }
}
