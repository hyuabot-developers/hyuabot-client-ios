//
//  AppIntentEnumSynonymsTests.swift
//  hyuabotTests
//

import XCTest
@testable import hyuabot

final class AppIntentEnumSynonymsTests: XCTestCase {
    func testEveryBusRouteHasSpokenSynonymsContainingItsRouteNumber() {
        for route in BusRouteOption.allCases {
            let synonyms = BusRouteOption.spokenSynonyms[route, default: []]

            XCTAssertFalse(synonyms.isEmpty, "Missing synonyms for \\(route)")
            XCTAssertTrue(synonyms.contains(route.rawValue), "Missing route number synonym for \\(route)")
        }
    }
}
