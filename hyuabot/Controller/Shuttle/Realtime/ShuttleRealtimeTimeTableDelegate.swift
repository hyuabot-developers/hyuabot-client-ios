import Api
import UIKit

@MainActor
class ShuttleRealtimeTimeTableDelegate: NSObject {
    let showViaVC: @MainActor (_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    let showAlarmVC: @MainActor (_ stopID: ShuttleStopEnum, _ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    let stopID: ShuttleStopEnum
    var activeBoardingAlarmKeys: Set<String> = []
    var showsInitialSkeleton = true

    required init(
        showViaVC: @escaping @MainActor (_: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void,
        showAlarmVC: @escaping @MainActor (_ stopID: ShuttleStopEnum, _ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order)
            -> Void,
        stopID: ShuttleStopEnum
    ) {
        self.showViaVC = showViaVC
        self.showAlarmVC = showAlarmVC
        self.stopID = stopID
    }
}

extension ShuttleRealtimeTimeTableDelegate: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsInitialSkeleton {
            return 6
        }
        if stopID == .dormiotryOut {
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if stopID == .shuttlecockOut {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if stopID == .station {
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if stopID == .terminal {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if stopID == .jungangStation {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        } else if stopID == .shuttlecockIn {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInData.value() else { return 0 }
            return max(min(data.count, 8), 1)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsInitialSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        if stopID == .dormiotryOut {
            guard let data = try? ShuttleRealtimeData.shared.shuttleDormitoryData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(
                    stopID: .dormiotryOut,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .dormiotryOut, item: item)
                ) { [weak self] in
                    self?.showAlarmVC(.dormiotryOut, item)
                }
                return cell
            }
        } else if stopID == .shuttlecockOut {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(
                    stopID: .shuttlecockOut,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .shuttlecockOut, item: item)
                ) { [weak self] in
                    self?.showAlarmVC(.shuttlecockOut, item)
                }
                return cell
            }
        } else if stopID == .station {
            guard let data = try? ShuttleRealtimeData.shared.shuttleStationData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(
                    stopID: .station,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .station, item: item)
                ) { [weak self] in
                    self?.showAlarmVC(.station, item)
                }
                return cell
            }
        } else if stopID == .terminal {
            guard let data = try? ShuttleRealtimeData.shared.shuttleTerminalData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(
                    stopID: .terminal,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .terminal, item: item)
                ) { [weak self] in
                    self?.showAlarmVC(.terminal, item)
                }
                return cell
            }
        } else if stopID == .jungangStation {
            guard let data = try? ShuttleRealtimeData.shared.shuttleJungangStationData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(
                    stopID: .jungangStation,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .jungangStation, item: item)
                ) { [weak self] in
                    self?.showAlarmVC(.jungangStation, item)
                }
                return cell
            }
        } else if stopID == .shuttlecockIn {
            guard let data = try? ShuttleRealtimeData.shared.shuttleShuttlecockInData.value() else { return UITableViewCell() }
            if !data.isEmpty {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
                    for: indexPath
                ) as! ShuttleRealtimeCellView
                let item = data[indexPath.row]
                cell.setupUI(
                    stopID: .shuttlecockIn,
                    indexPath: indexPath,
                    item: item,
                    isBoardingAlarmActive: isBoardingAlarmActive(stopID: .shuttlecockIn, item: item)
                ) { [weak self] in
                    self?.showAlarmVC(.shuttlecockIn, item)
                }
                return cell
            }
        }
        return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
    }

    private func isBoardingAlarmActive(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Bool {
        guard let context = ShuttleRealtimeTabVC.makeAlarmContext(stopID: stopID, item: item, directionDisplayName: nil) else {
            return false
        }
        return activeBoardingAlarmKeys.contains(context.key)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ShuttleRealtimeCellView else { return }
        if cell.itemByOrder != nil {
            let item = cell.itemByOrder!
            AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
            showViaVC(item)
        }
    }
}
