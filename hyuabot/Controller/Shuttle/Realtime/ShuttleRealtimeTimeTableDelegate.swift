import UIKit
import Api

class ShuttleRealtimeTimeTableDelegate: NSObject {
    let showViaVC: ((_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void)
    let stopID: ShuttleStopEnum
    
    required init(showViaVC: @escaping (_: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void, stopID: ShuttleStopEnum) {
        self.showViaVC = showViaVC
        self.stopID = stopID
    }
}

extension ShuttleRealtimeTimeTableDelegate: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.stopID == .dormiotryOut) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if (self.stopID == .shuttlecockOut) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if (self.stopID == .station) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if (self.stopID == .terminal) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if (self.stopID == .jungangStation) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if (self.stopID == .shuttlecockIn) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (self.stopID == .dormiotryOut) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .dormiotryOut, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .shuttlecockOut) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .shuttlecockOut, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .station) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .station, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .terminal) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .terminal, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .jungangStation) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .jungangStation, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        } else if (self.stopID == .shuttlecockIn) {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeCellView.reuseIdentifier, for: indexPath) as! ShuttleRealtimeCellView
                cell.setupUI(stopID: .shuttlecockIn, indexPath: indexPath, item: data[indexPath.row])
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ShuttleRealtimeCellView else { return }
        if (cell.itemByOrder != nil) {
            let item = cell.itemByOrder!
            self.showViaVC(item)
        }
    }
}
