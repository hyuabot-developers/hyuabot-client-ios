import UIKit

class CalendarNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: CalendarVC())
    }
}
