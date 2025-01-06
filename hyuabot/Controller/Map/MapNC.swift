import UIKit

class MapNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: MapVC())
    }
}
