import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }
    
    func moveToTimetableVC(stopID: Int, routes: [Int]) {
        let vc = BusTimetableVC(stopID: stopID, routes: routes)
        self.pushViewController(vc, animated: false)
    }
}
