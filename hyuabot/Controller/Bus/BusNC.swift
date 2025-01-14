import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }

    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .hanyangBlue
    }
    
    func moveToTimetableVC(stopID: Int, routes: [Int]) {
        let vc = BusTimetableVC(stopID: stopID, routes: routes)
        self.pushViewController(vc, animated: false)
    }
}
