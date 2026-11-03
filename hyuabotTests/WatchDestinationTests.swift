//
//  WatchDestinationTests.swift
//  hyuabot
//

import XCTest

final class WatchDestinationTests: XCTestCase {
    private let toDorm = ["dormitory_o", "shuttlecock_o", "station", "terminal", "shuttlecock_i", "dormitory_i"]
    private let endsAtShuttlecock = ["dormitory_o", "shuttlecock_o", "station", "shuttlecock_i"]
    private let jungangTrip = ["dormitory_o", "shuttlecock_o", "station", "jungang_stn", "shuttlecock_i", "dormitory_i"]

    func testStopsAfter() {
        XCTAssertEqual(WatchDestination.stopsAfter("station", in: toDorm), ["terminal", "shuttlecock_i", "dormitory_i"])
        XCTAssertEqual(WatchDestination.stopsAfter("shuttlecock_i", in: endsAtShuttlecock), [])
        XCTAssertEqual(WatchDestination.stopsAfter("missing", in: toDorm), [])
        XCTAssertEqual(WatchDestination.stopsAfter("station", in: []), [])
    }

    func testIsDeparture() {
        XCTAssertTrue(WatchDestination.isDeparture(
            queryStop: "shuttlecock_i",
            stopsAfterCurrent: WatchDestination.stopsAfter("shuttlecock_i", in: toDorm)
        ))
        XCTAssertFalse(WatchDestination.isDeparture(
            queryStop: "shuttlecock_i",
            stopsAfterCurrent: WatchDestination.stopsAfter("shuttlecock_i", in: endsAtShuttlecock)
        ))
        XCTAssertTrue(WatchDestination.isDeparture(queryStop: "shuttlecock_o", stopsAfterCurrent: []))
        XCTAssertTrue(WatchDestination.isDeparture(queryStop: "station", stopsAfterCurrent: []))
    }

    func testDormitoryAndShuttlecockLabelKeys() {
        assertLabel(stopID: "dormitory", queryStop: "dormitory_o", tag: "DH", stopsAfterCurrent: [], equals: "stop.station")
        assertLabel(stopID: "dormitory", queryStop: "dormitory_o", tag: "DY", stopsAfterCurrent: [], equals: "stop.terminal")
        assertLabel(stopID: "dormitory", queryStop: "dormitory_o", tag: "DJ", stopsAfterCurrent: [], equals: "stop.jungang")
        assertLabel(stopID: "dormitory", queryStop: "dormitory_o", tag: "C", stopsAfterCurrent: [], equals: "route.circular")
        assertLabel(stopID: "dormitory", queryStop: "dormitory_o", tag: "X", stopsAfterCurrent: [], equals: nil)
        assertLabel(stopID: "shuttlecock", queryStop: "shuttlecock_o", tag: "DH", stopsAfterCurrent: [], equals: "stop.station")
        assertLabel(stopID: "shuttlecock", queryStop: "shuttlecock_o", tag: "C", stopsAfterCurrent: [], equals: "route.circular")
        for tag in ["C", "DH", "DY"] {
            assertLabel(
                stopID: "shuttlecock",
                queryStop: "shuttlecock_i",
                tag: tag,
                stopsAfterCurrent: [],
                equals: "stop.dormitory"
            )
        }
    }

    func testStationAndTerminalLabelKeys() {
        let stationToDorm = WatchDestination.stopsAfter("station", in: toDorm)
        let stationToShuttlecock = WatchDestination.stopsAfter("station", in: endsAtShuttlecock)
        assertLabel(stopID: "station", queryStop: "station", tag: "DH", stopsAfterCurrent: stationToDorm, equals: "stop.dormitory")
        assertLabel(
            stopID: "station",
            queryStop: "station",
            tag: "DH",
            stopsAfterCurrent: stationToShuttlecock,
            equals: "stop.shuttlecock"
        )
        assertLabel(stopID: "station", queryStop: "station", tag: "C", stopsAfterCurrent: [], equals: "route.circular")
        assertLabel(stopID: "station", queryStop: "station", tag: "DJ", stopsAfterCurrent: [], equals: "stop.jungang")
        assertLabel(
            stopID: "terminal",
            queryStop: "terminal",
            tag: "DY",
            stopsAfterCurrent: ["shuttlecock_i", "dormitory_i"],
            equals: "stop.dormitory"
        )
        assertLabel(
            stopID: "terminal",
            queryStop: "terminal",
            tag: "DY",
            stopsAfterCurrent: ["shuttlecock_i"],
            equals: "stop.shuttlecock"
        )
        assertLabel(
            stopID: "terminal",
            queryStop: "terminal",
            tag: "DH",
            stopsAfterCurrent: ["shuttlecock_i", "dormitory_i"],
            equals: "stop.dormitory"
        )
        assertLabel(
            stopID: "terminal",
            queryStop: "terminal",
            tag: "C",
            stopsAfterCurrent: ["shuttlecock_i", "dormitory_i"],
            equals: "stop.dormitory"
        )
        assertLabel(
            stopID: "terminal",
            queryStop: "terminal",
            tag: "C",
            stopsAfterCurrent: ["shuttlecock_i"],
            equals: "stop.shuttlecock"
        )
        assertLabel(
            stopID: "terminal",
            queryStop: "terminal",
            tag: "XX",
            stopsAfterCurrent: ["shuttlecock_i"],
            equals: "stop.shuttlecock"
        )
    }

    func testJungangAndFallbackLabelKeys() {
        let afterJungang = WatchDestination.stopsAfter("jungang_stn", in: jungangTrip)
        assertLabel(
            stopID: "jungang",
            queryStop: "jungang_stn",
            tag: "DJ",
            stopsAfterCurrent: afterJungang,
            equals: "stop.dormitory"
        )
        assertLabel(stopID: "jungang", queryStop: "jungang_stn", tag: "C", stopsAfterCurrent: [], equals: "stop.dormitory")
        assertLabel(stopID: "foo", queryStop: "foo", tag: "X", stopsAfterCurrent: [], equals: "route.direct")
    }

    private func assertLabel(
        stopID: String,
        queryStop: String,
        tag: String,
        stopsAfterCurrent: [String],
        equals expected: String?
    ) {
        XCTAssertEqual(
            WatchDestination.labelKey(
                stopID: stopID,
                queryStop: queryStop,
                tag: tag,
                stopsAfterCurrent: stopsAfterCurrent
            ),
            expected
        )
    }
}
