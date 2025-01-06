import UIKit

class SubwayNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: SubwayRealtimeVC())
    }
}
