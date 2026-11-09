//
//  ShuttleNC.swift
//  hyuabot
//

import UIKit

class ShuttleNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: HomeExperienceManager.isEnabled ? TodayHomeVC() : ShuttleRealtimeVC())
    }

    func showHome(animated: Bool = true) {
        HomeExperienceManager.enable()
        updateTabBarItemForCurrentExperience()
        if let homeVC = viewControllers.first as? TodayHomeVC {
            popToViewController(homeVC, animated: animated)
        } else {
            setViewControllers([TodayHomeVC()], animated: animated)
        }
    }

    func showLegacyShuttle() {
        HomeExperienceManager.disable()
        updateTabBarItemForCurrentExperience()
        setViewControllers([ShuttleRealtimeVC()], animated: true)
    }

    func showShuttleDetailFromHome(stopID: String? = nil) {
        updateTabBarItemForCurrentExperience()
        pushViewController(ShuttleRealtimeVC(returnsToHome: true, initialStopID: stopID), animated: true)
    }

    func openShuttle(stopID: String?, destinationID: String?, animated: Bool = false) {
        updateTabBarItemForCurrentExperience()
        let shuttleVC = ShuttleRealtimeVC(
            returnsToHome: HomeExperienceManager.isEnabled,
            initialStopID: stopID,
            initialDestinationID: destinationID
        )
        if HomeExperienceManager.isEnabled {
            let homeVC = (viewControllers.first as? TodayHomeVC) ?? TodayHomeVC()
            setViewControllers([homeVC, shuttleVC], animated: animated)
        } else {
            setViewControllers([shuttleVC], animated: animated)
        }
    }

    func showShuttleTimetableFromHome(
        stopID: String.LocalizationValue,
        destination: String.LocalizationValue
    ) {
        updateTabBarItemForCurrentExperience()
        pushViewController(
            ShuttleTimetableVC(stopID: stopID, destination: destination),
            animated: true
        )
    }

    func updateTabBarItemForCurrentExperience() {
        if HomeExperienceManager.isEnabled {
            tabBarItem.title = String(localized: "tabbar.home")
            tabBarItem.image = UIImage(systemName: "house")
            tabBarItem.accessibilityIdentifier = "tab.home"
        } else {
            tabBarItem.title = String(localized: "tabbar.shuttle")
            tabBarItem.image = UIImage(systemName: "bus")
            tabBarItem.accessibilityIdentifier = "tab.shuttle"
        }
        (tabBarController as? RootVC)?.refreshFloatingTabItem(for: self)
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
