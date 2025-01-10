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
                ShuttleTimetableVC(stopID: "dormitory_o", tags: ["DH", "DJ", "C"])
            } else if (section == 1) {
                ShuttleTimetableVC(stopID: "dormitory_o", tags: ["DY", "C"])
            } else if (section == 2) {
                ShuttleTimetableVC(stopID: "dormitory_o", tags: ["DJ"])
            } else {
                fatalError("Invalid section")
            }
        } else if (stop == .shuttlecockOut) {
            if (section == 0) {
                ShuttleTimetableVC(stopID: "shuttlecock_o", tags: ["DH", "DJ", "C"])
            } else if (section == 1) {
                ShuttleTimetableVC(stopID: "shuttlecock_o", tags: ["DY", "C"])
            } else if (section == 2) {
                ShuttleTimetableVC(stopID: "shuttlecock_o", tags: ["DJ"])
            } else {
                fatalError("Invalid section")
            }
        } else if (stop == .station) {
            if (section == 0) {
                ShuttleTimetableVC(stopID: "station", tags: ["DH", "DJ", "C"])
            } else if (section == 1) {
                ShuttleTimetableVC(stopID: "station", tags: ["C"])
            } else if (section == 2) {
                ShuttleTimetableVC(stopID: "station", tags: ["DJ"])
            } else {
                fatalError("Invalid section")
            }
        } else if (stop == .terminal) {
            ShuttleTimetableVC(stopID: "terminal", tags: ["DY", "C"])
        } else if (stop == .jungangStation) {
            ShuttleTimetableVC(stopID: "jungang_station", tags: ["DJ"])
        } else if (stop == .shuttlecockIn) {
            ShuttleTimetableVC(stopID: "shuttlecock_i", tags: ["DH", "DJ", "DY", "C"])
        } else {
            fatalError("Invalid stop")
        }
        self.pushViewController(vc, animated: false)
    }
}
