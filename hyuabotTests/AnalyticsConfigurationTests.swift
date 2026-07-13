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
            XCTAssertTrue(isReportable(screen.rawValue))
        }
        XCTAssertEqual(Set(AnalyticsScreen.allCases.map(\.rawValue)).count, AnalyticsScreen.allCases.count)
    }

    func testAnalyticsItemNamesAreReportable() {
        for item in AnalyticsItem.allCases {
            XCTAssertTrue(isReportable(item.rawValue))
        }
        XCTAssertEqual(Set(AnalyticsItem.allCases.map(\.rawValue)).count, AnalyticsItem.allCases.count)
    }

    func testAnalyticsContentTypesAreReportable() {
        for type in AnalyticsContentType.allCases {
            XCTAssertTrue(isReportable(type.rawValue))
        }
        XCTAssertEqual(Set(AnalyticsContentType.allCases.map(\.rawValue)).count, AnalyticsContentType.allCases.count)
    }

    func testHomeUsesDedicatedCrossPlatformIdentifiers() {
        XCTAssertEqual(AnalyticsScreen.home.rawValue, "home")
        XCTAssertEqual(AnalyticsItem.tabHome.rawValue, "tab_home")
        XCTAssertEqual(AnalyticsItem.homeOpenShuttleDetail.rawValue, "home_open_shuttle_detail")
        XCTAssertEqual(AnalyticsItem.homeSelectDestination.rawValue, "home_select_destination")
    }

    func testSelectionParametersIncludeReportableDimensions() {
        let parameters = AnalyticsManager.selectionParameters(
            .campusSelectTool,
            type: .listItem,
            name: "map",
            destinationID: "map"
        )

        XCTAssertEqual(parameters[AnalyticsParameter.schemaVersion] as? String, analyticsSchemaVersion)
        XCTAssertEqual(parameters[AnalyticsParameter.elementID] as? String, "campus_select_tool")
        XCTAssertEqual(parameters[AnalyticsParameter.elementType] as? String, "list_item")
        XCTAssertEqual(parameters[AnalyticsParameter.destinationID] as? String, "map")
    }

    private func loadInfoPlist() throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hyuabot/Info.plist")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    private func isReportable(_ id: String) -> Bool {
        guard !id.isEmpty, id.count <= 40, id.first?.isLetter == true else { return false }
        return id.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" }
    }
}
