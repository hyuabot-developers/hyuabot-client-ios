//
//  DomainLogicTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class DomainLogicTests: XCTestCase {
    func testZonedDateTimeParsesWithAndWithoutFractionalSeconds() {
        XCTAssertNotNil("2026-07-21T16:00:00+09:00".toZonedDateTimeOrNil())
        XCTAssertNotNil("2026-07-21T16:00:00.123+09:00".toZonedDateTimeOrNil())
        XCTAssertNil("invalid".toZonedDateTimeOrNil())
    }

    func testCafeteriaStatusResolvesAroundRunningTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        XCTAssertEqual(
            CafeteriaStatusResolver.status(
                runningTime: "11:00 ~ 14:00",
                hasMenu: true,
                now: makeDate(hour: 10, minute: 59, calendar: calendar),
                calendar: calendar
            ),
            .soon
        )
        XCTAssertEqual(
            CafeteriaStatusResolver.status(
                runningTime: "11:00 ~ 14:00",
                hasMenu: true,
                now: makeDate(hour: 12, minute: 0, calendar: calendar),
                calendar: calendar
            ),
            .open
        )
        XCTAssertEqual(
            CafeteriaStatusResolver.status(
                runningTime: "11:00 ~ 14:00",
                hasMenu: true,
                now: makeDate(hour: 14, minute: 1, calendar: calendar),
                calendar: calendar
            ),
            .closed
        )
        XCTAssertEqual(CafeteriaStatusResolver.status(runningTime: "11:00 ~ 14:00", hasMenu: false), .noMenu)
        XCTAssertNil(CafeteriaStatusResolver.status(runningTime: "운영시간 미정", hasMenu: true))
    }

    func testReadingRoomDisplayLogic() {
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyRatio(occupied: 30, active: 100), 0.3, accuracy: 0.001)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyRatio(occupied: 30, active: 0), 0)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyColor(progress: 0.69), .systemGreen)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyColor(progress: 0.7), .systemOrange)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyColor(progress: 0.9), .systemRed)
        XCTAssertTrue(String(describing: ReadingRoomDisplayLogic.localizationKey(for: 53)).contains("reading_room_53"))
    }

    func testReadingRoomOccupancyLevel() {
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 0, active: 100), .full)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 3, active: 0), .full)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: -2, active: 100), .full)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 5, active: 100), .busy)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 9, active: 100), .busy)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 10, active: 100), .mid)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 29, active: 100), .mid)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 30, active: 100), .good)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 128, active: 312), .good)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 37, active: 220), .mid)
        XCTAssertEqual(ReadingRoomDisplayLogic.occupancyLevel(available: 6, active: 96), .busy)
    }

    func testReadingRoomUsedRatio() {
        XCTAssertEqual(ReadingRoomDisplayLogic.usedRatio(available: 0, active: 0), 0)
        XCTAssertEqual(ReadingRoomDisplayLogic.usedRatio(available: 100, active: 100), 0)
        XCTAssertEqual(ReadingRoomDisplayLogic.usedRatio(available: 0, active: 100), 1)
        XCTAssertEqual(ReadingRoomDisplayLogic.usedRatio(available: -5, active: 100), 1)
        XCTAssertEqual(
            ReadingRoomDisplayLogic.usedRatio(available: 128, active: 312),
            184.0 / 312.0,
            accuracy: 0.0001
        )
    }

    func testReadingRoomSplitDisplayName() {
        let koreanName = ReadingRoomDisplayLogic.splitDisplayName("제1열람실[지하1층]")
        XCTAssertEqual(koreanName.name, "제1열람실")
        XCTAssertEqual(koreanName.floor, "지하1층")

        let englishName = ReadingRoomDisplayLogic.splitDisplayName("1st reading room [B1]")
        XCTAssertEqual(englishName.name, "1st reading room")
        XCTAssertEqual(englishName.floor, "B1")

        let nameWithoutFloor = ReadingRoomDisplayLogic.splitDisplayName("HOLMZ 열람석")
        XCTAssertEqual(nameWithoutFloor.name, "HOLMZ 열람석")
        XCTAssertNil(nameWithoutFloor.floor)
    }

    func testSettingsLogic() {
        XCTAssertEqual(SettingsLogic.campusID(for: "campus.seoul"), 1)
        XCTAssertEqual(SettingsLogic.campusID(for: "campus.erica"), 2)
        XCTAssertTrue(String(describing: SettingsLogic.campusKey(for: 1)).contains("campus.seoul"))
        XCTAssertTrue(String(describing: SettingsLogic.campusKey(for: 2)).contains("campus.erica"))
        XCTAssertEqual(SettingsLogic.themeID(for: "theme.system"), 0)
        XCTAssertEqual(SettingsLogic.themeID(for: "theme.light"), 1)
        XCTAssertEqual(SettingsLogic.themeID(for: "theme.dark"), 2)
        XCTAssertTrue(String(describing: SettingsLogic.themeKey(for: 2)).contains("theme.dark"))
    }

    func testMapSearchLogic() {
        XCTAssertEqual(MapSearchLogic.cardTitle(number: "304", name: "304"), "304호")
        XCTAssertEqual(MapSearchLogic.cardTitle(number: "304", name: "304 강의실"), "304호")
        XCTAssertEqual(MapSearchLogic.cardTitle(number: "304", name: "304호"), "304호")
        XCTAssertEqual(MapSearchLogic.cardTitle(number: "304", name: "세미나실"), "304호 세미나실")
        XCTAssertEqual(MapSearchLogic.cardTitle(number: "304", name: ""), "304호")
        XCTAssertFalse(MapSearchLogic.isSearchResultVisible(keyword: ""))
        XCTAssertFalse(MapSearchLogic.isSearchResultVisible(keyword: "   "))
        XCTAssertTrue(MapSearchLogic.isSearchResultVisible(keyword: "제1공학관"))
        XCTAssertEqual(MapSearchLogic.rowCount(for: [RoomItem]()), 1)
        XCTAssertEqual(MapSearchLogic.rowCount(for: [
            RoomItem(name: "101", number: "101", building: "A", latitude: 1, longitude: 2),
            RoomItem(name: "102", number: "102", building: "A", latitude: 1, longitude: 2)
        ]), 2)
    }

    func testMapSearchDesignHelpers() {
        let items = [
            RoomItem(name: "101", number: "101", building: "본관", latitude: 1, longitude: 2),
            RoomItem(name: "102", number: "102", building: "본관", latitude: 1, longitude: 2)
        ]
        XCTAssertEqual(MapSearchLogic.rowCount(for: [RoomItem](), isLoading: true), 4)
        XCTAssertEqual(MapSearchLogic.rowCount(for: [RoomItem](), isLoading: false), 1)
        XCTAssertEqual(MapSearchLogic.rowCount(for: items, isLoading: false), 2)
        XCTAssertEqual(
            MapSearchLogic.guideURL(forBuildingNamed: "본관", in: [(name: "본관", url: "https://example.com/a")])?.absoluteString,
            "https://example.com/a"
        )
        XCTAssertNil(MapSearchLogic.guideURL(forBuildingNamed: "별관", in: [(name: "본관", url: "https://example.com/a")]))
        XCTAssertNil(MapSearchLogic.guideURL(forBuildingNamed: "본관", in: [(name: "본관", url: nil)]))
        XCTAssertNil(MapSearchLogic.guideURL(forBuildingNamed: "본관", in: [(name: "본관", url: "  ")]))
        XCTAssertTrue(MapSearchLogic.roomNumberText("304").contains("304"))
    }

    func testMapRequestGate() {
        var gate = MapRequestGate()
        let requestA = gate.begin()
        let requestB = gate.begin()
        XCTAssertFalse(gate.isCurrent(requestA))
        XCTAssertTrue(gate.isCurrent(requestB))
        gate.invalidate()
        XCTAssertFalse(gate.isCurrent(requestB))
        let requestC = gate.begin()
        XCTAssertTrue(gate.isCurrent(requestC))
    }

    func testMapSearchTimingScenarios() {
        var gate = MapRequestGate()
        let requestA = gate.begin()
        XCTAssertEqual(MapSearchLogic.searchLaunchKeyword("B", isSearching: true), "B")
        let requestB = gate.begin()
        XCTAssertFalse(gate.isCurrent(requestA))
        XCTAssertTrue(gate.isCurrent(requestB))

        var g2 = MapRequestGate()
        let a2 = g2.begin()
        XCTAssertNil(MapSearchLogic.searchLaunchKeyword("", isSearching: true))
        XCTAssertNil(MapSearchLogic.searchLaunchKeyword("   ", isSearching: true))
        XCTAssertNil(MapSearchLogic.searchLaunchKeyword(nil, isSearching: true))
        g2.invalidate()
        XCTAssertFalse(g2.isCurrent(a2))

        var g3 = MapRequestGate()
        let a3 = g3.begin()
        g3.invalidate()
        XCTAssertNil(MapSearchLogic.searchLaunchKeyword("301", isSearching: false))
        g3.invalidate()
        XCTAssertFalse(g3.isCurrent(a3))

        XCTAssertEqual(MapSearchLogic.searchLaunchKeyword(" 301 ", isSearching: true), " 301 ")
    }

    private func makeDate(hour: Int, minute: Int, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}

@MainActor
extension DomainLogicTests {
    func testShuttlePayloadIncludesTransfersForEveryStopTab() {
        let selection = ShuttlePayloadSelection(
            byDestination: true,
            showBus: true,
            showSubway: true,
            subwayDestination: .seoul,
            alternatives: .always
        )
        XCTAssertTrue(selection.needsBus)
        XCTAssertEqual(selection.subwayPairs.map { "\($0.0):\($0.1)" }, ["K449:up", "K450:up"])

        let timeView = ShuttlePayloadSelection(
            byDestination: false,
            showBus: true,
            showSubway: true,
            subwayDestination: .seoul,
            alternatives: .hidden
        )
        XCTAssertTrue(timeView.needsBus)
        XCTAssertEqual(timeView.subwayPairs.map { "\($0.0):\($0.1)" }, ["K449:up", "K450:up"])
        XCTAssertTrue(timeView.alternativePairs.isEmpty)
    }

    func testShuttlePayloadKeepsRequiredTransferLegs() {
        let expected: [(ShuttleSubwayTransferDestination, [String])] = [
            (.seoul, ["K449:up", "K450:up"]),
            (.suwonYongin, ["K251:up"]),
            (.oido, ["K449:down", "K251:down", "K450:down"]),
            (.incheon, ["K449:down", "K251:down", "K258:down"]),
            (.sosa, ["K449:down", "K251:down", "S26:up", "K450:down"])
        ]
        for (destination, pairs) in expected {
            let selection = ShuttlePayloadSelection(
                byDestination: true,
                showBus: true,
                showSubway: true,
                subwayDestination: destination,
                alternatives: .always
            )
            XCTAssertTrue(selection.needsBus)
            XCTAssertEqual(selection.subwayPairs.map { "\($0.0):\($0.1)" }, pairs)
        }
    }

    func testShuttlePayloadIncludesAlternativesForEveryStopTab() {
        let selection = ShuttlePayloadSelection(
            byDestination: true,
            showBus: true,
            showSubway: true,
            subwayDestination: .seoul,
            alternatives: .always
        )
        XCTAssertEqual(selection.alternativePairs.count, 12)
        XCTAssertTrue(selection.alternativePairs.contains { $0.0 == 216_000_068 && $0.1 == 216_000_138 })
        XCTAssertTrue(selection.alternativePairs.contains { $0.0 == 216_000_068 && $0.1 == 216_000_379 })
        XCTAssertEqual(Set(BusLocationInputs.inputs.map(\.stop)).count, 11)
    }
}

@MainActor
extension DomainLogicTests {
    func testSubwayPayloadIncludesTheDataNeededByEveryTab() {
        let keys = SubwayPayloadSelection.allKeys(weekday: "weekends")
        XCTAssertEqual(keys.map(\.stationID), ["K449", "K251", "K258", "K456"])
        XCTAssertEqual(keys.map(\.direction), [["up", "down"], ["up", "down"], ["up", "down"], ["up"]])
        XCTAssertTrue(keys.allSatisfy { $0.weekdays == ["weekends"] })
        XCTAssertEqual(keys[0].limit.unwrapped, 4)
        XCTAssertEqual(keys[1].limit.unwrapped, 4)
        XCTAssertNil(keys[2].limit.unwrapped)
        XCTAssertNil(keys[3].limit.unwrapped)
    }
}

extension DomainLogicTests {
    func testMapSearchFieldText() {
        let cases = [("", "304호"), ("   ", "304호"), ("제1공학관", "제1공학관 304호"), (" 본관 ", "본관 304호"), ("Main Building", "Main Building 304호")]
        for (building, expected) in cases {
            XCTAssertEqual(MapSearchLogic.searchFieldText(building: building, roomTitle: "304호"), expected)
        }
    }

    func testMapSearchFieldTranslationStaleness() {
        var gate = MapRequestGate(); let tokenA = gate.begin(); gate.invalidate()
        XCTAssertNil(MapSearchLogic.translatedSearchFieldText(token: tokenA, gate: gate, building: "Engineering Hall", roomTitle: "304호"))
        var gate2 = MapRequestGate(); let tokenA2 = gate2.begin(); let tokenB = gate2.begin()
        XCTAssertNil(MapSearchLogic.translatedSearchFieldText(
            token: tokenA2, gate: gate2, building: "Engineering Hall", roomTitle: "304호"
        ))
        XCTAssertEqual(MapSearchLogic.translatedSearchFieldText(
            token: tokenB, gate: gate2, building: "Science Hall", roomTitle: "304호"
        ), "Science Hall 304호")
        var gate3 = MapRequestGate(); let tokenC = gate3.begin(); gate3.invalidate()
        XCTAssertNil(MapSearchLogic.translatedSearchFieldText(token: tokenC, gate: gate3, building: "Engineering Hall", roomTitle: "304호"))
        var gate4 = MapRequestGate(); let token = gate4.begin()
        XCTAssertEqual(MapSearchLogic.translatedSearchFieldText(
            token: token, gate: gate4, building: "Engineering Hall", roomTitle: "304호"
        ), "Engineering Hall 304호")
    }
}
