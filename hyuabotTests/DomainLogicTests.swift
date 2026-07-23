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
