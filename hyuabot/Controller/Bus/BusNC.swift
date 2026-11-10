//
//  BusNC.swift
//  hyuabot
//

import UIKit

class BusNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: BusRealtimeVC())
    }

    func moveToTimetableVC(stopID: Int32, routes: [Int32], routeNames: [String], stopName: String) {
        let vc = BusTimetableVC(stopID: stopID, routes: routes, routeNames: routeNames, stopName: stopName)
        pushViewController(vc, animated: true)
    }
}
