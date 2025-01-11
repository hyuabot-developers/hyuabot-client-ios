import UIKit

class ShuttleNC: UINavigationController {
    convenience init() {
        self.init(rootViewController: ShuttleRealtimeVC())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .hanyangBlue
        self.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.setNavigationBarHidden(false, animated: false)
    }
    
    func moveToTimetableVC(stop: ShuttleStopEnum, section: Int) {
        let vc = if (stop == .dormiotryOut) {
            if (section == 0) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.dormitory.out",
                    destination: "shuttle.destination.shorten.station"
                )
            } else if (section == 1) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.dormitory.out",
                    destination: "shuttle.destination.shorten.terminal"
                )
            } else if (section == 2) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.dormitory.out",
                    destination: "shuttle.destination.shorten.jungang_station"
                )
            } else {
                fatalError("Invalid section")
            }
        } else if (stop == .shuttlecockOut) {
            if (section == 0) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.shuttlecock.out",
                    destination: "shuttle.destination.shorten.station"
                )
            } else if (section == 1) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.shuttlecock.out",
                    destination: "shuttle.destination.shorten.terminal"
                )
            } else if (section == 2) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.shuttlecock.out",
                    destination: "shuttle.destination.shorten.jungang_station"
                )
            } else {
                fatalError("Invalid section")
            }
        } else if (stop == .station) {
            if (section == 0) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.station",
                    destination: "shuttle.destination.shorten.campus"
                )
            } else if (section == 1) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.station",
                    destination: "shuttle.destination.shorten.terminal"
                )
            } else if (section == 2) {
                ShuttleTimetableVC(
                    stopID: "shuttle.stop.station",
                    destination: "shuttle.destination.shorten.jungang_station"
                )
            } else {
                fatalError("Invalid section")
            }
        } else if (stop == .terminal) {
            ShuttleTimetableVC(
                stopID: "shuttle.stop.terminal",
                destination: "shuttle.destination.shorten.campus"
            )
        } else if (stop == .jungangStation) {
            ShuttleTimetableVC(
                stopID: "shuttle.stop.jungang.station",
                destination: "shuttle.destination.shorten.campus"
            )
        } else if (stop == .shuttlecockIn) {
            ShuttleTimetableVC(
                stopID: "shuttle.stop.shuttlecock.in",
                destination: "shuttle.destination.shorten.campus"
            )
        } else {
            fatalError("Invalid stop")
        }
        self.pushViewController(vc, animated: false)
    }
}
