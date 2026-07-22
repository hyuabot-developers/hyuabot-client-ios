import UIKit

class ShuttleNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: HomeExperienceManager.isEnabled ? TodayHomeVC() : ShuttleRealtimeVC())
    }

    func showHome() {
        HomeExperienceManager.enable()
        updateTabBarItemForCurrentExperience()
        setViewControllers([TodayHomeVC()], animated: true)
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

    func updateTabBarItemForCurrentExperience() {
        if HomeExperienceManager.isEnabled {
            tabBarItem.title = String(localized: "tabbar.home")
            tabBarItem.image = UIImage(systemName: "house.fill")
            tabBarItem.accessibilityIdentifier = "tab.home"
        } else {
            tabBarItem.title = String(localized: "tabbar.shuttle")
            tabBarItem.image = UIImage(systemName: "bus.fill")
            tabBarItem.accessibilityIdentifier = "tab.shuttle"
        }
    }

    func moveToTimetableVC(stop: ShuttleStopEnum, section: Int) {
        let vc = if stop == .dormiotryOut {
            if section == 0 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.dormitory.out",
                    destination: "shuttle.destination.shorten.station"
                )
            } else if section == 1 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.dormitory.out",
                    destination: "shuttle.destination.shorten.terminal"
                )
            } else if section == 2 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.dormitory.out",
                    destination: "shuttle.destination.shorten.jungang_station"
                )
            } else {
                fatalError("Invalid section")
            }
        } else if stop == .shuttlecockOut {
            if section == 0 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.shuttlecock.out",
                    destination: "shuttle.destination.shorten.station"
                )
            } else if section == 1 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.shuttlecock.out",
                    destination: "shuttle.destination.shorten.terminal"
                )
            } else if section == 2 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.shuttlecock.out",
                    destination: "shuttle.destination.shorten.jungang_station"
                )
            } else {
                fatalError("Invalid section")
            }
        } else if stop == .station {
            if section == 0 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.station",
                    destination: "shuttle.destination.shorten.campus"
                )
            } else if section == 1 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.station",
                    destination: "shuttle.destination.shorten.terminal"
                )
            } else if section == 2 {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.station",
                    destination: "shuttle.destination.shorten.jungang_station"
                )
            } else {
                fatalError("Invalid section")
            }
        } else if stop == .terminal {
            ShuttleTimetableVC(
                stopID: "shuttle.stop.terminal",
                destination: "shuttle.destination.shorten.campus"
            )
        } else if stop == .jungangStation {
            ShuttleTimetableVC(
                stopID: "shuttle.stop.jungang.station",
                destination: "shuttle.destination.shorten.campus"
            )
        } else if stop == .shuttlecockIn {
            ShuttleTimetableVC(
                stopID: "shuttle.stop.shuttlecock.in",
                destination: "shuttle.destination.shorten.campus"
            )
        } else {
            fatalError("Invalid stop")
        }
        pushViewController(vc, animated: false)
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
