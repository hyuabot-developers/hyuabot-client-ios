import UIKit

class ShuttleTimetableTabVC: UIViewController {
    private let isWeekdays: Bool
    
    init(isWeekdays: Bool) {
        self.isWeekdays = isWeekdays
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
