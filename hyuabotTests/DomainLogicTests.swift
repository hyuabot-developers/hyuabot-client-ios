//
//  DomainLogicTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class DomainLogicTests: XCTestCase {
    func testHomeWeatherTitlePrioritizesUpcomingPrecipitation() throws {
        let now = try XCTUnwrap("2026-07-21T05:35:00Z".toZonedDateTimeOrNil())
        let future = try XCTUnwrap("2026-07-21T07:00:00Z".toZonedDateTimeOrNil())
        let currentHour = try XCTUnwrap("2026-07-21T05:00:00Z".toZonedDateTimeOrNil())

        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "RAIN",
                currentTemperature: 29,
                maximumTemperature: 31,
                precipitationType: "RAIN",
                precipitationStartAt: future,
                now: now
            ),
            .precipitationLater(.rain)
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "SNOW",
                currentTemperature: -3,
                maximumTemperature: 1,
                precipitationType: "SNOW",
                precipitationStartAt: currentHour,
                now: now
            ),
            .precipitationNow(.snow)
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "SLEET",
                currentTemperature: 1,
                maximumTemperature: 3,
                precipitationType: "SLEET",
                precipitationStartAt: nil,
                now: now
            ),
            .precipitationToday(.sleet)
        )
    }

    func testHomeWeatherTitleFallsBackToTemperatureAndSkyCondition() {
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "CLEAR",
                currentTemperature: 32,
                maximumTemperature: 35,
                precipitationType: "NONE",
                precipitationStartAt: nil
            ),
            .hot
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "CLEAR",
                currentTemperature: -6,
                maximumTemperature: 1,
                precipitationType: "NONE",
                precipitationStartAt: nil
            ),
            .cold
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "CLEAR",
                currentTemperature: 20,
                maximumTemperature: 25,
                precipitationType: "NONE",
                precipitationStartAt: nil
            ),
            .clear
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "CLOUDY",
                currentTemperature: 20,
                maximumTemperature: 25,
                precipitationType: "NONE",
                precipitationStartAt: nil
            ),
            .cloudy
        )
    }

    func testHomeWeatherTitleUsesObservationBeforeUpcomingForecast() throws {
        let now = try XCTUnwrap("2026-07-21T05:35:00Z".toZonedDateTimeOrNil())
        let earlierForecast = try XCTUnwrap("2026-07-21T05:00:00Z".toZonedDateTimeOrNil())
        let laterForecast = try XCTUnwrap("2026-07-21T07:00:00Z".toZonedDateTimeOrNil())

        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "RAIN",
                currentTemperature: 24,
                maximumTemperature: 28,
                precipitationType: "RAIN",
                currentPrecipitationType: "RAIN",
                precipitationStartAt: laterForecast,
                now: now
            ),
            .precipitationNow(.rain)
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "RAIN",
                currentTemperature: 24,
                maximumTemperature: 28,
                precipitationType: "RAIN",
                currentPrecipitationType: "NONE",
                precipitationStartAt: earlierForecast,
                now: now
            ),
            .precipitationToday(.rain)
        )
        XCTAssertEqual(
            HomeWeatherDisplayLogic.titleStyle(
                condition: "RAIN",
                currentTemperature: 24,
                maximumTemperature: 28,
                precipitationType: "RAIN",
                currentPrecipitationType: "NONE",
                precipitationStartAt: laterForecast,
                now: now
            ),
            .precipitationLater(.rain)
        )
    }

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
        XCTAssertFalse(MapSearchLogic.isSearchResultVisible(keyword: ""))
        XCTAssertFalse(MapSearchLogic.isSearchResultVisible(keyword: "   "))
        XCTAssertTrue(MapSearchLogic.isSearchResultVisible(keyword: "제1공학관"))
        XCTAssertEqual(MapSearchLogic.rowCount(for: [RoomItem]()), 1)
        XCTAssertEqual(MapSearchLogic.rowCount(for: [
            RoomItem(name: "101", number: "101", building: "A", latitude: 1, longitude: 2),
            RoomItem(name: "102", number: "102", building: "A", latitude: 1, longitude: 2)
        ]), 2)
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
    func testShuttlePayloadOmitsHiddenAndInapplicableTransfers() {
        for stop in ["station", "terminal", "jungang_stn", "shuttlecock_i"] {
            let selection = ShuttlePayloadSelection(
                stop: stop,
                byDestination: true,
                showBus: true,
                showSubway: true,
                subwayDestination: .seoul,
                alternatives: .automatic
            )
            XCTAssertFalse(selection.needsBus)
            XCTAssertTrue(selection.subwayPairs.isEmpty)
        }
        let timeView = ShuttlePayloadSelection(
            stop: "dormitory_o",
            byDestination: false,
            showBus: true,
            showSubway: true,
            subwayDestination: .seoul,
            alternatives: .hidden
        )
        XCTAssertFalse(timeView.needsBus)
        XCTAssertTrue(timeView.subwayPairs.isEmpty)
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
                stop: "shuttlecock_o",
                byDestination: true,
                showBus: true,
                showSubway: true,
                subwayDestination: destination,
                alternatives: .automatic
            )
            XCTAssertTrue(selection.needsBus)
            XCTAssertEqual(selection.subwayPairs.map { "\($0.0):\($0.1)" }, pairs)
        }
    }

    func testShuttlePayloadOnlyIncludesSelectedStopAlternatives() {
        let selection = ShuttlePayloadSelection(
            stop: "station",
            byDestination: true,
            showBus: true,
            showSubway: true,
            subwayDestination: .seoul,
            alternatives: .always
        )
        XCTAssertEqual(selection.alternativePairs.map { "\($0.0):\($0.1)" }, ["216000068:216000138"])
        XCTAssertEqual(Set(BusLocationInputs.inputs.map(\.stop)).count, 11)
    }
}

@MainActor
extension DomainLogicTests {
    func testSubwayLinePayloadOnlyIncludesDisplayedStation() {
        for (tab, id) in [(0, "K449"), (1, "K251")] {
            let keys = SubwayPayloadSelection.keys(tab: tab, weekday: "weekdays")
            XCTAssertEqual(keys.count, 1)
            XCTAssertEqual(keys.first?.stationID, id)
            XCTAssertEqual(keys.first?.direction, ["up", "down"])
            XCTAssertEqual(keys.first?.weekdays, ["weekdays"])
            XCTAssertEqual(keys.first?.limit.unwrapped, 4)
        }
    }

    func testSubwayTransferPayloadKeepsOnlyRequiredLegs() {
        let keys = SubwayPayloadSelection.keys(tab: 2, weekday: "weekends")
        XCTAssertEqual(keys.map(\.stationID), ["K449", "K251", "K258", "S26"])
        XCTAssertEqual(keys.map(\.direction), [["down"], ["down"], ["down"], ["up"]])
        XCTAssertTrue(keys.allSatisfy { $0.weekdays == ["weekends"] })
        XCTAssertEqual(keys[0].limit.unwrapped, 4)
        XCTAssertEqual(keys[1].limit.unwrapped, 4)
        XCTAssertNil(keys[2].limit.unwrapped)
        XCTAssertNil(keys[3].limit.unwrapped)
    }
}

@MainActor
extension DomainLogicTests {
    func testHomePayloadOmitsHiddenOrInapplicableConnections() {
        for stop in ["dormitory_o", "shuttlecock_o", "station", "terminal", "jungang_stn", "shuttlecock_i"] {
            for destination in ["STATION", "TERMINAL", "JUNGANG", "CAMPUS"] {
                for enabled in [false, true] {
                    let selection = HomePayloadSelection(
                        stop: stop,
                        destination: destination,
                        showBus50: enabled,
                        showSubway: enabled,
                        subwayDestination: .seoul
                    )
                    let outbound = ["dormitory_o", "shuttlecock_o"].contains(stop)
                    XCTAssertEqual(selection.needsBus50, enabled && outbound && destination == "TERMINAL")
                    XCTAssertEqual(
                        !selection.subwayKeys(weekday: "weekdays").isEmpty,
                        enabled && outbound && destination == "STATION"
                    )
                }
            }
        }
    }

    func testHomePayloadPreservesEachTransferDestinationAndWeekday() {
        let expected: [(SubwayTransferDestination, [String])] = [
            (.seoul, ["K449:up"]), (.suwonYongin, ["K251:up"]),
            (.oido, ["K449:down", "K251:down"]),
            (.incheon, ["K449:down", "K251:down", "K258:down"]),
            (.sosa, ["K449:down", "K251:down", "S26:up"])
        ]
        for (destination, pairs) in expected {
            let selection = HomePayloadSelection(
                stop: "shuttlecock_o",
                destination: "STATION",
                showBus50: true,
                showSubway: true,
                subwayDestination: destination
            )
            let keys = selection.subwayKeys(weekday: "weekends")
            XCTAssertEqual(keys.map { "\($0.stationID):\($0.direction.joined(separator: ","))" }, pairs)
            XCTAssertTrue(keys.allSatisfy { $0.weekdays == ["weekends"] })
            XCTAssertTrue(keys.filter { $0.stationID != "S26" }.allSatisfy { $0.limit.unwrapped == 12 })
            XCTAssertTrue(keys.filter { $0.stationID == "S26" }.allSatisfy { $0.limit.unwrapped == nil })
        }
    }

    func testHomeAlternativesOnlyRequestSelectedPath() {
        // Keyed by "stop>destination".
        let expected: [(String, [String])] = [
            ("dormitory_o>STATION", ["216000068:216000383"]),
            ("dormitory_o>TERMINAL", ["216000081:216000028", "216000101:216000028"]),
            ("shuttlecock_o>TERMINAL", ["216000016:216000152"]),
            ("station>CAMPUS", ["216000068:216000138"]),
            ("terminal>CAMPUS", ["216000082:216000077", "216000102:216000077", "216000016:216000074"]),
            ("jungang_stn>CAMPUS", ["216000082:217000140", "216000102:217000140", "216000016:217000264"]),
            ("shuttlecock_i>CAMPUS", []), ("station>JUNGANG", [])
        ]
        for (path, pairs) in expected {
            let parts = path.split(separator: ">").map(String.init)
            let (stop, destination) = (parts[0], parts[1])
            let selection = HomePayloadSelection(
                stop: stop,
                destination: destination,
                showBus50: true,
                showSubway: true,
                subwayDestination: .seoul
            )
            XCTAssertEqual(selection.alternativePairs.map { "\($0.0):\($0.1)" }, pairs)
        }
    }
}
