import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }

    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .hanyangBlue
    }
}
