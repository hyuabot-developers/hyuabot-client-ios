//
//  AppDomainLogic.swift
//  hyuabot
//
import Foundation
import UIKit
enum CafeteriaStatus: Equatable {
    case noMenu
    case soon
    case open
    case closed
    var localizationKey: String.LocalizationValue {
        switch self {
        case .noMenu: "cafeteria.status.no.menu"
        case .soon: "cafeteria.status.soon"
        case .open: "cafeteria.status.open"
        case .closed: "cafeteria.status.closed"
        }
    }
}
enum CafeteriaStatusResolver {
    static func status(runningTime: String, hasMenu: Bool, now: Date = Date(), calendar: Calendar = .current) -> CafeteriaStatus? {
        if !hasMenu { return .noMenu }
        let minutes = runningTime.matches(of: /\d{1,2}:\d{2}/)
            .prefix(2)
            .compactMap { minutesSinceStartOfDay(String($0.output)) }
        guard minutes.count == 2 else { return nil }
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        if nowMinutes < minutes[0] { return .soon }
        if nowMinutes > minutes[1] { return .closed }
        return .open
    }
    private static func minutesSinceStartOfDay(_ value: String) -> Int? {
        let parts = value.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0 ... 23).contains(hour),
              (0 ... 59).contains(minute) else { return nil }
        return hour * 60 + minute
    }
}
enum ReadingRoomOccupancyLevel: Equatable {
    case good, mid, busy, full
    var localizedTitle: String {
        switch self {
        case .good: String(localized: "reading_room.level.good")
        case .mid: String(localized: "reading_room.level.mid")
        case .busy: String(localized: "reading_room.level.busy")
        case .full: String(localized: "reading_room.level.full")
        }
    }

    var color: UIColor {
        switch self {
        case .good: SettingsStyle.Color.levelGood
        case .mid: SettingsStyle.Color.levelMid
        case .busy: SettingsStyle.Color.levelBusy
        case .full: SettingsStyle.Color.levelFull
        }
    }

    var fillColor: UIColor {
        switch self {
        case .good: SettingsStyle.Color.levelGoodFill
        case .mid: SettingsStyle.Color.levelMidFill
        case .busy: SettingsStyle.Color.levelBusyFill
        case .full: SettingsStyle.Color.levelFullFill
        }
    }
}

enum ReadingRoomDisplayLogic {
    static func occupancyLevel(available: Int, active: Int) -> ReadingRoomOccupancyLevel {
        guard available > 0, active > 0 else { return .full }
        let ratio = Double(available) / Double(active)
        if ratio < 0.1 { return .busy }
        if ratio < 0.3 { return .mid }
        return .good
    }

    static func usedRatio(available: Int, active: Int) -> CGFloat {
        guard active > 0 else { return 0 }
        return CGFloat(min(max(Double(active - max(available, 0)) / Double(active), 0), 1))
    }

    static func splitDisplayName(_ localizedName: String) -> (name: String, floor: String?) {
        let text = localizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasSuffix("]"), let bracket = text.lastIndex(of: "[") else { return (text, nil) }
        let name = text[..<bracket].trimmingCharacters(in: .whitespacesAndNewlines)
        let floorStart = text.index(after: bracket)
        let floorEnd = text.index(before: text.endIndex)
        let floor = text[floorStart..<floorEnd].trimmingCharacters(in: .whitespacesAndNewlines)
        return (name, floor.isEmpty ? nil : floor)
    }

    static func occupancyRatio(occupied: Int, active: Int) -> Float {
        guard active > 0 else { return 0 }
        return Float(occupied) / Float(active)
    }

    static func occupancyColor(progress: Float) -> UIColor {
        if progress >= 0.9 { return .systemRed }
        if progress >= 0.7 { return .systemOrange }
        return .systemGreen
    }

    static func localizationKey(for id: Int) -> String.LocalizationValue {
        switch id {
        case 1: "reading_room_1"
        case 53: "reading_room_53"
        case 54: "reading_room_54"
        case 55: "reading_room_55"
        case 56: "reading_room_56"
        case 61: "reading_room_61"
        case 63: "reading_room_63"
        case 131: "reading_room_131"
        case 132: "reading_room_132"
        default: "Unknown"
        }
    }
}

enum SettingsLogic {
    static func campusID(for key: String.LocalizationValue) -> Int {
        key == "campus.seoul" ? 1 : 2
    }

    static func campusKey(for id: Int) -> String.LocalizationValue {
        id == 1 ? "campus.seoul" : "campus.erica"
    }

    static func themeID(for key: String.LocalizationValue) -> Int {
        switch key {
        case "theme.system": 0
        case "theme.light": 1
        default: 2
        }
    }

    static func themeKey(for id: Int) -> String.LocalizationValue {
        switch id {
        case 0: "theme.system"
        case 1: "theme.light"
        default: "theme.dark"
        }
    }
}

enum MapSearchLogic {
    static let skeletonRowCount = 4

    static func isSearchResultVisible(keyword: String) -> Bool {
        !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func searchLaunchKeyword(_ keyword: String?, isSearching: Bool) -> String? {
        guard isSearching, let keyword, isSearchResultVisible(keyword: keyword) else { return nil }
        return keyword
    }

    static func rowCount(for items: [RoomItem], isLoading: Bool) -> Int {
        isLoading ? skeletonRowCount : rowCount(for: items)
    }

    static func rowCount(for items: [some Any]) -> Int {
        max(1, items.count)
    }

    static func roomNumberText(_ number: String) -> String {
        String(format: String(localized: "map.room.number_format"), number)
    }

    static func cardTitle(number: String, name: String) -> String {
        let formattedNumber = roomNumberText(number)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              !trimmedName.contains(formattedNumber),
              !trimmedName.contains(number) else {
            return formattedNumber
        }
        return "\(formattedNumber) \(trimmedName)"
    }

    static func guideURL(forBuildingNamed name: String, in buildings: [(name: String, url: String?)]) -> URL? {
        for building in buildings where building.name == name {
            guard let rawURL = building.url?.trimmingCharacters(in: .whitespacesAndNewlines), !rawURL.isEmpty,
                  let url = URL(string: rawURL) else { continue }
            return url
        }
        return nil
    }

    static func searchFieldText(building: String, roomTitle: String) -> String {
        let trimmed = building.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || roomTitle.contains(trimmed) { return roomTitle }
        return "\(trimmed) \(roomTitle)"
    }

    static func translatedSearchFieldText(token: Int, gate: MapRequestGate, building: String, roomTitle: String) -> String? {
        guard gate.isCurrent(token) else { return nil }
        return searchFieldText(building: building, roomTitle: roomTitle)
    }
}

struct MapRequestGate: Equatable {
    private(set) var current: Int = 0

    mutating func begin() -> Int {
        current += 1
        return current
    }

    mutating func invalidate() {
        current += 1
    }

    func isCurrent(_ token: Int) -> Bool {
        token == current
    }
}

enum MapRegionLogic {
    static func isUsable(north: Double, south: Double, west: Double, east: Double) -> Bool {
        (-90...90).contains(north) && (-90...90).contains(south)
            && (-180...180).contains(west) && (-180...180).contains(east)
            && north > south && east > west
            && north - south < 1 && east - west < 1
    }
}

// MARK: - Calendar

struct CalendarSpan: Equatable {
    let id: Int
    let start: String
    let end: String
    let categoryID: Int
}

struct CalendarBarSegment: Equatable {
    let spanID: Int
    let categoryID: Int
    let slot: Int
    let startCol: Int
    let endCol: Int
    let roundLeft: Bool
    let roundRight: Bool
    let showsLabel: Bool
    let dimmed: Bool
}

struct CalendarWeekLayout: Equatable {
    let bars: [CalendarBarSegment]
    let totals: [Int]
    let overflow: [Int: Int]
}
struct CalendarCategoryItem: Equatable {
    let id: Int
    let name: String
}
enum CalendarLayoutLogic {
    static let maxVisibleSlots = 2
    static let upcomingLimit = 5
    private struct Placement {
        let span: CalendarSpan
        let startCol: Int
        let endCol: Int
        let slot: Int
    }
    private static let parsingFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()
    static func weekLayout(weekDays: [String], monthKey: String, spans: [CalendarSpan]) -> CalendarWeekLayout {
        guard weekDays.count == 7 else {
            return CalendarWeekLayout(bars: [], totals: Array(repeating: 0, count: 7), overflow: [:])
        }
        let ws = weekDays[0]
        let we = weekDays[6]
        let placements = makePlacements(weekDays: weekDays, spans: spans, weekStart: ws, weekEnd: we)
        let totals = placementTotals(placements)
        let (over, overflow) = overflowColumns(totals)
        let bars = visibleSegments(placements, weekDays: weekDays, monthKey: monthKey, over: over)
        return CalendarWeekLayout(bars: bars, totals: totals, overflow: overflow)
    }
    private static func makePlacements(
        weekDays: [String], spans: [CalendarSpan], weekStart: String, weekEnd: String
    ) -> [Placement] {
        let sortedSpans = spans
            .filter { $0.start <= weekEnd && $0.end >= weekStart }
            .sorted {
                if $0.start != $1.start { return $0.start < $1.start }
                if $0.end != $1.end { return $0.end > $1.end }
                return $0.id < $1.id
            }
        var occupancy: [[Bool]] = []
        var placements: [Placement] = []
        for span in sortedSpans {
            let clippedStart = max(span.start, weekStart)
            let clippedEnd = min(span.end, weekEnd)
            guard let startCol = weekDays.firstIndex(of: clippedStart),
                  let endCol = weekDays.firstIndex(of: clippedEnd),
                  startCol <= endCol else { continue }
            var slot = 0
            while slot < occupancy.count && (startCol...endCol).contains(where: { occupancy[slot][$0] }) {
                slot += 1
            }
            if slot == occupancy.count { occupancy.append(Array(repeating: false, count: 7)) }
            for column in startCol...endCol { occupancy[slot][column] = true }
            placements.append(Placement(span: span, startCol: startCol, endCol: endCol, slot: slot))
        }
        return placements
    }
    private static func placementTotals(_ placements: [Placement]) -> [Int] {
        var totals = Array(repeating: 0, count: 7)
        for placement in placements {
            for column in placement.startCol...placement.endCol { totals[column] += 1 }
        }
        return totals
    }
    private static func overflowColumns(_ totals: [Int]) -> ([Bool], [Int: Int]) {
        var over: [Bool] = []
        var overflow: [Int: Int] = [:]
        for column in 0..<7 {
            let isOver = totals[column] > maxVisibleSlots
            over.append(isOver)
            if isOver { overflow[column] = totals[column] - 1 }
        }
        return (over, overflow)
    }
    private static func visibleSegments(
        _ placements: [Placement], weekDays: [String], monthKey: String, over: [Bool]
    ) -> [CalendarBarSegment] {
        var bars: [CalendarBarSegment] = []
        for placement in placements {
            if placement.slot == 0 {
                bars.append(segment(placement, placement.startCol...placement.endCol, true,
                                    weekDays: weekDays, monthKey: monthKey, over: over))
            } else if placement.slot == 1 {
                bars += secondarySegments(placement, weekDays: weekDays, monthKey: monthKey, over: over)
            }
        }
        return bars
    }
    private static func secondarySegments(
        _ placement: Placement, weekDays: [String], monthKey: String, over: [Bool]
    ) -> [CalendarBarSegment] {
        var segments: [CalendarBarSegment] = []
        var column = placement.startCol
        while column <= placement.endCol {
            while column <= placement.endCol && over[column] { column += 1 }
            guard column <= placement.endCol else { break }
            let runStart = column
            while column < placement.endCol && !over[column + 1] { column += 1 }
            segments.append(segment(
                placement, runStart...column, segments.isEmpty,
                weekDays: weekDays, monthKey: monthKey, over: over
            ))
            column += 1
        }
        return segments
    }
    private static func segment(
        _ placement: Placement, _ columns: ClosedRange<Int>, _ showsLabel: Bool,
        weekDays: [String], monthKey: String, over: [Bool]
    ) -> CalendarBarSegment {
        let span = placement.span
        let startCol = columns.lowerBound
        let endCol = columns.upperBound
        return CalendarBarSegment(
            spanID: span.id,
            categoryID: span.categoryID,
            slot: placement.slot,
            startCol: startCol,
            endCol: endCol,
            roundLeft: span.start == weekDays[startCol] || (startCol > 0 && over[startCol - 1]),
            roundRight: span.end == weekDays[endCol] || (endCol < 6 && over[endCol + 1]),
            showsLabel: showsLabel,
            dimmed: !weekDays[startCol].hasPrefix(monthKey) && !weekDays[endCol].hasPrefix(monthKey)
        )
    }
    static func monthHasEvents(monthKey: String, spans: [CalendarSpan]) -> Bool {
        spans.contains { String($0.start.prefix(7)) <= monthKey && String($0.end.prefix(7)) >= monthKey }
    }
    static func panelSpanIDs(spans: [CalendarSpan], selectedDay: String?, today: String) -> [Int] {
        if let day = selectedDay {
            return spans.filter { $0.start <= day && $0.end >= day }
                .sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
                .map(\.id)
        }
        return Array(spans.filter { $0.end >= today }
            .sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
            .prefix(upcomingLimit).map(\.id))
    }
    static func categoryItems(_ pairs: [(id: Int, name: String)]) -> [CalendarCategoryItem] {
        var names: [Int: String] = [:]
        for pair in pairs where names[pair.id] == nil { names[pair.id] = pair.name }
        return names.keys.sorted().compactMap { id in
            names[id].map { CalendarCategoryItem(id: id, name: $0) }
        }
    }
    static func toggledHidden(_ hidden: Set<Int>, toggling id: Int, allIDs: [Int]) -> Set<Int> {
        if hidden.contains(id) {
            var result = hidden
            result.remove(id)
            return result
        }
        guard allIDs.contains(where: { $0 != id && !hidden.contains($0) }) else { return hidden }
        var result = hidden
        result.insert(id)
        return result
    }
    static func metaText(categoryName: String, start: String, end: String, locale: Locale) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M.dd (E)"
        displayFormatter.locale = locale
        displayFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        let startText = parsingFormatter.date(from: start).map(displayFormatter.string(from:)) ?? start
        let endText = parsingFormatter.date(from: end).map(displayFormatter.string(from:)) ?? end
        let dateText = start == end ? startText : "\(startText) – \(endText)"
        return categoryName.isEmpty ? dateText : "\(categoryName) · \(dateText)"
    }
}
