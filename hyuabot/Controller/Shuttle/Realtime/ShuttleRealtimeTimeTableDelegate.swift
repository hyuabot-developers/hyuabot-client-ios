//
//  ShuttleRealtimeTimeTableDelegate.swift
//  hyuabot
//

import Api
import UIKit

@MainActor
class ShuttleRealtimeTimeTableDelegate: NSObject {
    nonisolated static func nextDayInputs(
        table: ShuttleNextDayTimetable?,
        boardingStop: String,
        destinationKey: String?,
        now: Foundation.Date,
        calendar: Calendar
    ) -> (departureTimes: [String]?, isWeekend: Bool) {
        let expected = ShuttleDisplayLogic.nextServiceDate(after: now, calendar: calendar)
        let isWeekend = calendar.isDateInWeekend(expected)
        // A cached table of another date (stale cache, failed or pending replacement) is treated as not loaded.
        guard let table, table.date == ShuttleDisplayLogic.serviceDateString(expected, calendar: calendar) else {
            return (nil, isWeekend)
        }
        let groups = table.departures[boardingStop] ?? [:]
        if let destinationKey {
            return (groups[destinationKey] ?? [], isWeekend)
        }
        return (groups.values.flatMap { $0 }, isWeekend)
    }

    static func emptyText(stopID: ShuttleStopEnum, section: Int?, now: Foundation.Date = Foundation.Date()) -> ShuttleDisplayLogic.EmptyText {
        let boardingStop = ShuttleDisplayLogic.stopKey(stopID)
        let stops = (try? ShuttleRealtimeData.shared.arrival.value()) ?? []
        let timetable = stops.first { $0.name == boardingStop }?.timetable
        let destinationKey = section.flatMap { ShuttleDisplayLogic.destinationKey(stopID: boardingStop, section: $0) }
        let times: [String]
        if let destinationKey {
            times = timetable?.destination.first { $0.destination == destinationKey }?.entries.map(\.time) ?? []
        } else {
            times = timetable?.order.map(\.time) ?? []
        }
        let destinationStop: String
        switch destinationKey {
        case "STATION": destinationStop = "station"
        case "TERMINAL": destinationStop = "terminal"
        case "JUNGANG": destinationStop = "jungang_stn"
        default: destinationStop = "dormitory_i"
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let nextDay = nextDayInputs(
            table: try? ShuttleRealtimeData.shared.nextDayTimetable.value(),
            boardingStop: boardingStop,
            destinationKey: destinationKey,
            now: now,
            calendar: calendar
        )
        return ShuttleDisplayLogic.emptyText(
            destination: destinationStop == "dormitory_i"
                ? String(localized: "shuttle.realtime.empty.destination.campus")
                : ShuttleDisplayLogic.stopShortName(destinationStop) ?? "",
            departureTimes: times,
            isWeekend: calendar.isDateInWeekend(now),
            nextDayDepartureTimes: nextDay.departureTimes,
            isNextDayWeekend: nextDay.isWeekend
        )
    }

    let showViaVC: @MainActor (_ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    let showAlarmVC: @MainActor (_ stopID: ShuttleStopEnum, _ item: ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> Void
    let stopID: ShuttleStopEnum
    var activeBoardingAlarmKeys: Set<String> = []
    var showsInitialSkeleton = true
    var transferViewProvider: ((ShuttleRealtimePageQuery.Data.Shuttle.Stop.Timetable.Order) -> [ShuttleTransferInfoView])?
    private var expandedRow: Int?

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
        CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        ShuttleRealtimeFooterView.cardGap + ShuttleRealtimeFooterView.timetableButtonHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if showsInitialSkeleton {
            return ShuttleRealtimeCellView.informationRowHeight
        }
        if isExpansionRow(indexPath) {
            let item = expandedRow.flatMap { timetableData?.indices.contains($0) == true ? timetableData?[$0] : nil }
            return ShuttleExpandedTransferCellView.preferredHeight(transferViews: item.flatMap { transferViewProvider?($0) } ?? [])
        }
        if hasNoEntries {
            return UITableView.automaticDimension
        }
        if indexPath.row == expandedRow {
            return ShuttleRealtimeCellView.expandedRowHeight
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
        let count = max(min(timetableData.count, 8), 1)
        return count + (expandedRow == nil ? 0 : 1)
    }

    private func isExpansionRow(_ indexPath: IndexPath) -> Bool {
        guard let expandedRow else { return false }
        return indexPath.row == expandedRow + 1
    }

    private func dataRow(for indexPath: IndexPath) -> Int {
        guard let expandedRow, indexPath.row > expandedRow + 1 else { return indexPath.row }
        return indexPath.row - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsInitialSkeleton {
            return tableView.dequeueReusableCell(withIdentifier: ShuttleRealtimeSkeletonCellView.reuseIdentifier, for: indexPath)
        }
        guard let data = timetableData, !data.isEmpty else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ShuttleRealtimeEmptyCellView.reuseIdentifier, for: indexPath
            )
            let text = Self.emptyText(stopID: stopID, section: nil)
            (cell as? ShuttleRealtimeEmptyCellView)?.configure(title: text.title, body: text.body)
            return cell
        }
        if isExpansionRow(indexPath), let expandedRow, data.indices.contains(expandedRow) {
            guard let expandedCell = tableView.dequeueReusableCell(
                withIdentifier: ShuttleExpandedTransferCellView.reuseIdentifier,
                for: indexPath
            ) as? ShuttleExpandedTransferCellView else { return UITableViewCell() }
            let item = data[expandedRow]
            let stopID = stopID
            expandedCell.setCardBottomRounded(expandedRow == min(data.count, 8) - 1)
            expandedCell.setup(
                transferViews: transferViewProvider?(item) ?? [],
                isAlarmActive: isBoardingAlarmActive(stopID: stopID, item: item),
                onAlarm: { [weak self] in self?.showAlarmVC(stopID, item) },
                onStops: { [weak self] in self?.showViaVC(item) }
            )
            return expandedCell
        }
        let row = dataRow(for: indexPath)
        guard data.indices.contains(row) else { return UITableViewCell() }
        let cell = dequeueRealtimeCell(from: tableView, for: indexPath)
        cell.showsTopSeparator = row > 0
        cell.setCardCorners(isFirst: row == 0, isLast: row == min(data.count, 8) - 1 && expandedRow != row)
        let item = data[row]
        cell.setupUI(
            stopID: stopID,
            indexPath: IndexPath(row: row, section: indexPath.section),
            item: item,
            isBoardingAlarmActive: isBoardingAlarmActive(stopID: stopID, item: item)
        )
        cell.setExpanded(expandedRow == row)
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
        guard !showsInitialSkeleton, !hasNoEntries, !isExpansionRow(indexPath) else { return }
        let row = dataRow(for: indexPath)
        let previous = expandedRow
        let isCollapsing = previous == row
        if !isCollapsing {
            AnalyticsManager.logSelect(.shuttleSelectViaRow, type: .listItem)
        }
        expandedRow = isCollapsing ? nil : row
        (tableView.cellForRow(at: indexPath) as? ShuttleRealtimeCellView)?.setExpanded(!isCollapsing)
        if let previous, !isCollapsing {
            (tableView.cellForRow(at: IndexPath(row: previous, section: 0)) as? ShuttleRealtimeCellView)?.setExpanded(false)
        }
        tableView.performBatchUpdates {
            if let previous {
                tableView.deleteRows(at: [IndexPath(row: previous + 1, section: 0)], with: .fade)
            }
            if !isCollapsing {
                tableView.insertRows(at: [IndexPath(row: row + 1, section: 0)], with: .fade)
            }
        }
    }
}
