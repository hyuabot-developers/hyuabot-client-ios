import UIKit

class SubwayNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: SubwayRealtimeVC())
    }
    
    func moveToTimetableVC(timetableTitle: String.LocalizationValue, heading: SubwayHeadingEnum) {
        let timetableVC = SubwayTimetableVC(timetableTitle: timetableTitle, heading: heading)
        pushViewController(timetableVC, animated: false)
    }
}
