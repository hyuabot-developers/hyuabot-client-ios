import UIKit

class ContactNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: ContactVC())
    }
}
