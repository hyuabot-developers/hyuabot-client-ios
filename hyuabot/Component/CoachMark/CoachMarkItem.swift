import UIKit

struct CoachMarkItem {
    let id: String
    let version: Int
    let title: String
    let message: String
    private let targetViewProvider: () -> UIView?

    var targetView: UIView? {
        targetViewProvider()
    }

    init(id: String, version: Int = 1, targetView: UIView, title: String, message: String) {
        self.id = id
        self.version = version
        self.title = title
        self.message = message
        targetViewProvider = { targetView }
    }

    init(id: String, version: Int = 1, targetViewProvider: @escaping () -> UIView?, title: String, message: String) {
        self.id = id
        self.version = version
        self.title = title
        self.message = message
        self.targetViewProvider = targetViewProvider
    }
}
