//
//  SubwayNC.swift
//  hyuabot
//

import UIKit

class SubwayNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: SubwayRealtimeVC())
    }

    func moveToTimetableVC(line: SubwayLine, heading: SubwayHeadingEnum) {
        let timetableVC = SubwayTimetableVC(line: line, heading: heading)
        pushViewController(timetableVC, animated: true)
    }
}
