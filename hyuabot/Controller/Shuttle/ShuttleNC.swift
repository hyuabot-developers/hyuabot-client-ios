import UIKit

class ShuttleNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: ShuttleRealtimeVC())
    }
}
