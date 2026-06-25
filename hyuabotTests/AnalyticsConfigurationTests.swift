//
//  AnalyticsConfigurationTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class AnalyticsConfigurationTests: XCTestCase {
    func testFirebaseAutomaticScreenReportingIsDisabled() throws {
        let infoPlist = try loadInfoPlist()

        XCTAssertEqual(infoPlist["FirebaseAutomaticScreenReportingEnabled"] as? Bool, false)
    }

    func testAnalyticsScreenNamesAreReportable() {
        for screen in AnalyticsScreen.allCases {
            XCTAssertFalse(screen.rawValue.isEmpty)
            XCTAssertFalse(screen.rawValue.contains(" "))
        }
    }

    private func loadInfoPlist() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hyuabot/Info.plist")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }
}
