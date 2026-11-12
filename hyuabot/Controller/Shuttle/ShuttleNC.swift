//
//  ShuttleNC.swift
//  hyuabot
//

import UIKit

class ShuttleNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: ShuttleRealtimeVC())
    }

    func openShuttle(stopID: String?, destinationID: String?, animated: Bool = false) {
        let shuttleVC = ShuttleRealtimeVC(
            initialStopID: stopID,
            initialDestinationID: destinationID
        )
        setViewControllers([shuttleVC], animated: animated)
    }

    func moveToTimetableVC(stop: ShuttleStopEnum, section: Int) {
        pushViewController(timetableOptions(stop: stop, section: section), animated: true)
    }

    private func timetableOptions(stop: ShuttleStopEnum, section: Int) -> ShuttleTimetableVC {
        switch stop {
        case .dormiotryOut:
            ShuttleTimetableVC(stopID: "shuttle.stop.dormitory.out", destination: outboundDestination(section))
        case .shuttlecockOut:
            ShuttleTimetableVC(stopID: "shuttle.stop.shuttlecock.out", destination: outboundDestination(section))
        case .station:
            ShuttleTimetableVC(stopID: "shuttle.stop.station", destination: stationDestination(section))
        case .terminal:
            ShuttleTimetableVC(stopID: "shuttle.stop.terminal", destination: "shuttle.destination.shorten.campus")
        case .jungangStation:
            ShuttleTimetableVC(stopID: "shuttle.stop.jungang.station", destination: "shuttle.destination.shorten.campus")
        case .shuttlecockIn:
            ShuttleTimetableVC(stopID: "shuttle.stop.shuttlecock.in", destination: "shuttle.destination.shorten.campus")
        }
    }

    private func outboundDestination(_ section: Int) -> String.LocalizationValue {
        switch section {
        case 0: "shuttle.destination.shorten.station"
        case 1: "shuttle.destination.shorten.terminal"
        case 2: "shuttle.destination.shorten.jungang_station"
        default: fatalError("Invalid section")
        }
    }

    private func stationDestination(_ section: Int) -> String.LocalizationValue {
        switch section {
        case 0: "shuttle.destination.shorten.campus"
        case 1: "shuttle.destination.shorten.terminal"
        case 2: "shuttle.destination.shorten.jungang_station"
        default: fatalError("Invalid section")
        }
    }

    func openBirthdayDialog() {
        // Get Current Year
        let currentYear = Calendar.current.component(.year, from: Date())
        if UserDefaults.standard.bool(forKey: "hideBirthdayPopup\(currentYear)") {
            return
        }
        let birthdayVC = BirthdayVC()
        birthdayVC.modalPresentationStyle = .overCurrentContext
        birthdayVC.modalTransitionStyle = .crossDissolve
        present(birthdayVC, animated: true, completion: nil)
    }
}
