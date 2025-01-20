import UIKit
import RxSwift
import QueryAPI

class SubwayTimetableVC: UIViewController {
    private let timetableTitle: String.LocalizationValue
    
    init(timetableTitle: String.LocalizationValue) {
        self.timetableTitle = timetableTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
