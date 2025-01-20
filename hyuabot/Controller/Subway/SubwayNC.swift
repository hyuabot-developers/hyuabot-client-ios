import UIKit

class SubwayNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: SubwayRealtimeVC())
    }
    
    func moveToTimetableVC(timetableTitle: String.LocalizationValue) {
        let timetableVC = SubwayTimetableVC(timetableTitle: timetableTitle)
        pushViewController(timetableVC, animated: false)
    }
}
