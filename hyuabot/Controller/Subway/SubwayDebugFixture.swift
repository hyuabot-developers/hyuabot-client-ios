//
//  SubwayDebugFixture.swift
//  hyuabot
//
#if DEBUG
    import Foundation

    enum SubwayDebugFixture {
        enum Mode: String {
            case day
            case late
            case loading
        }

        static var activeMode: Mode? {
            argumentValue(for: "-subwayFixture").flatMap(Mode.init(rawValue:))
        }

        static var dayType: SubwayDayType {
            argumentValue(for: "-subwayFixtureDay") == "weekends" ? .weekends : .weekdays
        }

        static var now: Date {
            let value = argumentValue(for: "-subwayFixtureNow")
            let parts = value?.split(separator: ":").compactMap { Int($0) }
            guard let parts, parts.count == 2,
                  let date = Calendar.current.date(
                      bySettingHour: parts[0], minute: parts[1], second: 0, of: Date()
                  )
            else {
                let hour = activeMode == .late ? 0 : 14
                let minute = activeMode == .late ? 41 : 2
                return Calendar.current.date(
                    bySettingHour: hour, minute: minute, second: 0, of: Date()
                ) ?? Date()
            }
            return date
        }

        static func arrivals(line: SubwayLine, heading: SubwayHeadingEnum, mode: Mode) -> [SubwayArrivalInfo] {
            if mode == .late {
                guard line == .line4, heading == .down else { return [] }
                return [arrival("안산", 6, true, 1, "반월", isLast: true)]
            }

            switch (line, heading) {
            case (.line4, .up):
                return [
                    arrival("당고개", 2, true, 2, "중앙"),
                    arrival("진접", 7, true, 1, "고잔"),
                    arrival("당고개", 12, true, 0, "초지"),
                    arrival("사당", 19, false)
                ]
            case (.line4, .down):
                return [
                    arrival("오이도", 1, true, 3, "상록수"),
                    arrival("안산", 6, true, 1, "반월"),
                    arrival("오이도", 13, true, 2, "수리산"),
                    arrival("오이도", 22, false)
                ]
            case (.suin, .up):
                return [
                    arrival("왕십리", 4, true, 2, "중앙"),
                    arrival("고색", 15, true, 1, "초지"),
                    arrival("왕십리", 27, false)
                ]
            case (.suin, .down):
                return [
                    arrival("인천", 9, true, 2, "야목"),
                    arrival("오이도", 24, false),
                    arrival("인천", 38, false)
                ]
            }
        }

        static func transferRoutes(toIncheon: Bool, mode: Mode) -> [SubwayTransferRouteInfo] {
            guard mode != .late else { return [] }
            let station = String(localized: "subway.station.k258")
            if toIncheon {
                return [
                    SubwayTransferRouteInfo(
                        first: SubwayTransferLegInfo(line: .line4, terminalName: "오이도", minutes: 1),
                        transferStation: station,
                        waitMinutes: 4,
                        second: SubwayTransferLegInfo(line: .suin, terminalName: "인천", minutes: 19)
                    ),
                    SubwayTransferRouteInfo(
                        first: SubwayTransferLegInfo(line: .suin, terminalName: "인천", minutes: 9),
                        transferStation: nil,
                        waitMinutes: nil,
                        second: nil
                    )
                ]
            }
            return [
                SubwayTransferRouteInfo(
                    first: SubwayTransferLegInfo(
                        line: .suin,
                        terminalName: "왕십리",
                        minutes: 28,
                        location: "달월",
                        status: 2
                    ),
                    transferStation: station,
                    waitMinutes: 3,
                    second: SubwayTransferLegInfo(line: .line4, terminalName: "당고개", minutes: 31)
                ),
                SubwayTransferRouteInfo(
                    first: SubwayTransferLegInfo(
                        line: .suin,
                        terminalName: "왕십리",
                        minutes: 34,
                        location: "인천논현",
                        status: 1
                    ),
                    transferStation: nil,
                    waitMinutes: nil,
                    second: nil
                )
            ]
        }

        static func departures(line: SubwayLine, heading: SubwayHeadingEnum, day: SubwayDayType) -> [SubwayTimetableDeparture] {
            let destinations: [String]
            let firstTime: String
            let lastTime: String
            let lastDestination: String
            switch (line, heading) {
            case (.line4, .up):
                destinations = ["당고개", "진접", "당고개", "사당"]
                firstTime = "05:14"
                lastTime = "00:06"
                lastDestination = "당고개"
            case (.line4, .down):
                destinations = ["오이도", "안산"]
                firstTime = "05:31"
                lastTime = "00:52"
                lastDestination = "안산"
            case (.suin, .up):
                destinations = ["왕십리", "고색", "왕십리"]
                firstTime = "05:22"
                lastTime = "23:51"
                lastDestination = destinations[0]
            case (.suin, .down):
                destinations = ["인천", "오이도", "인천"]
                firstTime = "05:40"
                lastTime = "23:58"
                lastDestination = destinations[0]
            }

            let first = SubwayDisplayLogic.sortableMinutes(firstTime) ?? 0
            let rawLast = SubwayDisplayLogic.sortableMinutes(lastTime) ?? 0
            let end = rawLast < first ? rawLast + 24 * 60 : rawLast
            var minutes = first
            var index = 0
            var items: [(time: String, terminalName: String)] = []
            while minutes < end {
                items.append((time: timeString(minutes), terminalName: destinations[index % destinations.count]))
                let hour = (minutes / 60) % 24
                minutes += headway(line: line, hour: hour, day: day) + (index % 3) - 1
                index += 1
            }
            items.append((time: timeString(end), terminalName: lastDestination))
            return SubwayDisplayLogic.departures(items, line: line)
        }

        private static func headway(line: SubwayLine, hour: Int, day: SubwayDayType) -> Int {
            let base: Int = switch line {
            case .suin:
                (hour < 7 || hour >= 22) ? 20 : (hour == 7 || hour == 8 || hour == 18) ? 12 : 16
            case .line4:
                if hour < 6 || hour >= 23 {
                    14
                } else if hour == 7 || hour == 8 || hour == 18 {
                    6
                } else if hour == 6 || hour == 17 || hour == 19 {
                    8
                } else {
                    10
                }
            }
            let weekendAddition = day == .weekends ? (line == .suin ? 4 : 3) : 0
            return base + weekendAddition
        }

        private static func timeString(_ minutes: Int) -> String {
            String(format: "%02d:%02d:00", (minutes / 60) % 24, minutes % 60)
        }

        private static func arrival(
            _ terminalName: String,
            _ minutes: Int,
            _ isRealtime: Bool,
            _ status: Int? = nil,
            _ location: String? = nil,
            isLast: Bool = false
        ) -> SubwayArrivalInfo {
            SubwayArrivalInfo(
                terminalName: terminalName,
                minutes: minutes,
                isRealtime: isRealtime,
                isLast: isLast,
                status: status,
                location: location
            )
        }

        private static func argumentValue(for name: String) -> String? {
            let arguments = ProcessInfo.processInfo.arguments
            guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else {
                return nil
            }
            return arguments[index + 1]
        }
    }
#endif
