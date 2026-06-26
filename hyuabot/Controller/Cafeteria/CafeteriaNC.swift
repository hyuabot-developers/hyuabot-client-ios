import UIKit

class CafeteriaNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: CafeteriaVC())
    }

    func showMeal(date: Foundation.Date, mealIndex: Int) {
        popToRootViewController(animated: false)
        (viewControllers.first as? CafeteriaVC)?.showMeal(date: date, mealIndex: mealIndex)
    }
}
