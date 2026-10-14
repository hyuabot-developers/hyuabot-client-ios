//
//  ComplicationLineLabelTests.swift
//  hyuabot
//

import XCTest

/// Pure-logic tests for the watch complication line label. The complication sources are compiled into this target
/// through the `watchWidget` folder, so these tests exercise the same code the widget ships.
final class ComplicationLineLabelTests: XCTestCase {
    private struct Case {
        let stopID: String
        let routeTag: String
        let routeName: String
        let expected: ShuttleLineLabel?
    }

    /// Every row of the phone-derived mapping, plus the negative cases the phone leaves blank.
    private let cases: [Case] = [
        // dormitory and shuttlecock: outbound by tag only.
        Case(stopID: "dormitory", routeTag: "DH", routeName: "XXS", expected: .station),
        Case(stopID: "dormitory", routeTag: "DY", routeName: "XXD", expected: .terminal),
        Case(stopID: "dormitory", routeTag: "DJ", routeName: "", expected: .jungang),
        Case(stopID: "dormitory", routeTag: "C", routeName: "", expected: .circular),
        Case(stopID: "shuttlecock", routeTag: "DH", routeName: "XXS", expected: .station),
        Case(stopID: "shuttlecock", routeTag: "DY", routeName: "XXD", expected: .terminal),
        Case(stopID: "shuttlecock", routeTag: "DJ", routeName: "", expected: .jungang),
        Case(stopID: "shuttlecock", routeTag: "C", routeName: "", expected: .circular),
        Case(stopID: "dormitory", routeTag: "XX", routeName: "XXS", expected: nil),
        Case(stopID: "shuttlecock", routeTag: "XX", routeName: "XXD", expected: nil),
        Case(stopID: "dormitory", routeTag: "", routeName: "XXS", expected: nil),

        // station: DH needs S/D, DJ and C are fixed.
        Case(stopID: "station", routeTag: "DH", routeName: "XXS", expected: .shuttlecock),
        Case(stopID: "station", routeTag: "DH", routeName: "XXD", expected: .dormitory),
        Case(stopID: "station", routeTag: "DH", routeName: "", expected: nil),
        Case(stopID: "station", routeTag: "DH", routeName: "XX", expected: nil),
        Case(stopID: "station", routeTag: "DJ", routeName: "", expected: .jungang),
        Case(stopID: "station", routeTag: "DJ", routeName: "XXS", expected: .jungang),
        Case(stopID: "station", routeTag: "C", routeName: "", expected: .circular),
        Case(stopID: "station", routeTag: "C", routeName: "XXS", expected: .circular),
        Case(stopID: "station", routeTag: "C", routeName: "XXD", expected: .circular),
        Case(stopID: "station", routeTag: "DY", routeName: "XXS", expected: nil),

        // terminal: suffix only, tag ignored.
        Case(stopID: "terminal", routeTag: "DH", routeName: "XXS", expected: .shuttlecock),
        Case(stopID: "terminal", routeTag: "C", routeName: "XXD", expected: .dormitory),
        Case(stopID: "terminal", routeTag: "", routeName: "XXS", expected: .shuttlecock),
        Case(stopID: "terminal", routeTag: "DY", routeName: "", expected: nil),
        Case(stopID: "terminal", routeTag: "DH", routeName: "", expected: nil),

        // jungang: always 기숙사.
        Case(stopID: "jungang", routeTag: "DH", routeName: "", expected: .dormitory),
        Case(stopID: "jungang", routeTag: "C", routeName: "XXS", expected: .dormitory),

        // Unknown complication ids never label, even with a valid-looking tag and suffix.
        Case(stopID: "unknown", routeTag: "DH", routeName: "XXS", expected: nil),
        Case(stopID: "shuttlecock_i", routeTag: "DH", routeName: "XXS", expected: nil),

        // Suffix rules: trimmed, case-sensitive, and Korean display text is never trusted.
        Case(stopID: "terminal", routeTag: "", routeName: " XXS\n", expected: .shuttlecock),
        Case(stopID: "terminal", routeTag: "", routeName: "xxs", expected: nil),
        Case(stopID: "terminal", routeTag: "DH", routeName: "한대앞", expected: nil),
        Case(stopID: "station", routeTag: "DH", routeName: "직행", expected: nil),
        Case(stopID: "dormitory", routeTag: "XX", routeName: "한대앞", expected: nil)
    ]

    func testResolveTableMatchesPhoneMapping() {
        for testCase in cases {
            let actual = ShuttleLineLabel.resolve(
                complicationStopID: testCase.stopID,
                routeTag: testCase.routeTag,
                routeName: testCase.routeName
            )
            XCTAssertEqual(
                actual, testCase.expected,
                "stop=\(testCase.stopID) tag=\(testCase.routeTag) name=\(testCase.routeName.debugDescription)"
            )
        }
    }

    func testKoreanRouteLabelsAreTheSixRequestedStrings() {
        let expected: [ShuttleLineLabel: String] = [
            .station: "한대앞",
            .terminal: "예술인",
            .jungang: "중앙역",
            .circular: "순환",
            .dormitory: "기숙사",
            .shuttlecock: "셔틀콕"
        ]
        for testCase in cases {
            let label = ComplicationText.routeLabel(
                stopID: testCase.stopID,
                routeTag: testCase.routeTag,
                routeName: testCase.routeName,
                .ko
            )
            if let expectedLabel = testCase.expected {
                XCTAssertEqual(label, expected[expectedLabel], "stop=\(testCase.stopID) tag=\(testCase.routeTag)")
            } else {
                XCTAssertEqual(label, "", "stop=\(testCase.stopID) tag=\(testCase.routeTag) should be blank")
            }
        }
    }

    func testRouteLabelNeverShowsRouteNameOrDirect() {
        for testCase in cases {
            let label = ComplicationText.routeLabel(
                stopID: testCase.stopID,
                routeTag: testCase.routeTag,
                routeName: testCase.routeName,
                .ko
            )
            if !testCase.routeName.isEmpty {
                XCTAssertNotEqual(label, testCase.routeName, "raw route code leaked for \(testCase.routeName)")
            }
            XCTAssertNotEqual(label, "직행")
            XCTAssertNotEqual(label, "Direct")
        }
    }

    func testEveryLabelCaseIsReachableAndLocalized() {
        let reached = Set(cases.compactMap {
            ShuttleLineLabel.resolve(complicationStopID: $0.stopID, routeTag: $0.routeTag, routeName: $0.routeName)
        })
        XCTAssertEqual(reached, Set(ShuttleLineLabel.allCases))

        let koreanOutputs = Set(ShuttleLineLabel.allCases.map { ComplicationText.text($0.localizationKey, .ko) })
        XCTAssertEqual(koreanOutputs, ["한대앞", "예술인", "중앙역", "순환", "기숙사", "셔틀콕"])

        for label in ShuttleLineLabel.allCases {
            for language in [ComplicationLanguage.en, .ja, .zh] {
                let text = ComplicationText.text(label.localizationKey, language)
                XCTAssertFalse(text.isEmpty)
                XCTAssertNotEqual(text, label.localizationKey, "missing \(language) text for \(label.localizationKey)")
            }
        }
    }

    func testNonKoreanRouteLabelUsesExistingLocalizedText() {
        let label = ComplicationText.routeLabel(stopID: "shuttlecock", routeTag: "DH", routeName: "", .en)
        XCTAssertEqual(label, "Station")
        XCTAssertEqual(ComplicationText.routeLabel(stopID: "terminal", routeTag: "", routeName: "XXS", .en), "Shuttlecock")
    }

    // MARK: Stop catalog

    func testComplicationStopCatalogIsExactlyTheFiveStops() {
        XCTAssertEqual(ComplicationStops.all.map(\.id), ["dormitory", "shuttlecock", "station", "terminal", "jungang"])
    }

    func testEveryComplicationStopQueriesExactlyOneStop() {
        for stop in ComplicationStops.all {
            XCTAssertEqual(stop.queryStops.count, 1, "\(stop.id) must map to one query stop")
            XCTAssertFalse(stop.queryStops.contains("shuttlecock_i"), "\(stop.id) must never query shuttlecock_i")
        }
    }

    func testShuttlecockComplicationQueriesOutboundOnly() {
        XCTAssertEqual(ComplicationStops.find("shuttlecock")?.queryStops, ["shuttlecock_o"])
    }

    // MARK: Cache version

    func testScheduleCacheKeyPrefixIsV2() {
        XCTAssertEqual(ComplicationStore.scheduleKeyPrefix, "watch_complication_schedule_v2_")
    }

    // MARK: Single-stop assembly regression

    func testAssembleSingleShuttlecockOutboundResultKeepsAllRows() {
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        let rows = [
            TimetableRow(localTime: "08:00", routeTag: "DH", routeName: "XXS"),
            TimetableRow(localTime: "09:00", routeTag: "DY", routeName: "XXD")
        ]
        let schedule = ComplicationCoverage.assemble(
            results: [StopTimetableResult(stopName: "shuttlecock_o", rows: rows)],
            day: day
        )
        XCTAssertEqual(schedule.departures.count, 2)
        XCTAssertNil(schedule.coverageEnd, "an untruncated single stop has no coverage horizon")
    }
}
