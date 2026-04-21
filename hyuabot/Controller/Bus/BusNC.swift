import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }
    
    func moveToTimetableVC(stopID: Int32, routes: [Int32], title: String.LocalizationValue) {
        let vc = BusTimetableVC(stopID: stopID, routes: routes, title: title)
        self.pushViewController(vc, animated: false)
    }
}
