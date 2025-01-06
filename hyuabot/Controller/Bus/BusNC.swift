import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
