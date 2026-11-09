//
//  ShuttleRealtimeTimeTableDelegate.swift
//  hyuabot
//

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
    private var timetableData: [ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order]? {
        let shuttle = ShuttleRealtimeData.shared
        return switch stopID {
        case .dormiotryOut: try? shuttle.shuttleDormitoryData.value()
        case .shuttlecockOut: try? shuttle.shuttleShuttlecockData.value()
        case .station: try? shuttle.shuttleStationData.value()
        case .terminal: try? shuttle.shuttleTerminalData.value()
        case .jungangStation: try? shuttle.shuttleJungangStationData.value()
        case .shuttlecockIn: try? shuttle.shuttleShuttlecockInData.value()
        default: nil
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if showsInitialSkeleton {
            return ShuttleRealtimeCellView.informationRowHeight
        }
        if hasNoEntries {
            return UITableView.automaticDimension
        }
        return ShuttleRealtimeCellView.informationRowHeight
    }

    private var hasNoEntries: Bool {
        timetableData?.isEmpty ?? true
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showsInitialSkeleton {
            return 6
        }
        guard let timetableData else { return 0 }
        return max(min(timetableData.count, 8), 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsInitialSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let data = timetableData, !data.isEmpty else {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath)
        }
        let cell = dequeueRealtimeCell(from: tableView, for: indexPath)
        let item = data[indexPath.row]
        let stopID = stopID
        cell.setupUI(
            stopID: stopID,
            indexPath: indexPath,
            item: item,
            isBoardingAlarmActive: isBoardingAlarmActive(stopID: stopID, item: item)
        ) { [weak self] in
            self?.showAlarmVC(stopID, item)
        }
        return cell
    }

    private func dequeueRealtimeCell(from tableView: UITableView, for indexPath: IndexPath) -> ShuttleRealtimeCellView {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShuttleRealtimeCellView.reuseIdentifier,
            for: indexPath
        ) as? ShuttleRealtimeCellView else {
            fatalError("Expected ShuttleRealtimeCellView for timetable row")
        }
        return cell
    }

    private func isBoardingAlarmActive(stopID: ShuttleStopEnum, item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Bool {
        guard let context = ShuttleRealtimeTabVC.makeAlarmContext(stopID: stopID, item: item, directionDisplayName: nil) else {
            return false
        }
        return activeBoardingAlarmKeys.contains(context.key)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ShuttleRealtimeCellView else { return }
        guard let item = cell.itemByOrder else { return }
        AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
        showViaVC(item)
    }
}
