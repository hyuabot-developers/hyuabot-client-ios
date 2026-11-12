//
//  LegacyHomeExperienceCleanupTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class LegacyHomeExperienceCleanupTests: XCTestCase {
    func testRemovesRetiredHomeKeysAndKeepsShuttleTransferSettings() throws {
        let suiteName = "LegacyHomeExperienceCleanupTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "homeExperienceEnabled")
        defaults.set(true, forKey: "homeExperiencePromptDecision")
        defaults.set(true, forKey: "home.showSeoulBusStop")
        defaults.set("gangnam", forKey: "home.seoulBusStop")
        defaults.set(false, forKey: "home.showBus50Transfer")

        LegacyHomeExperienceCleanup.run(defaults: defaults)

        XCTAssertNil(defaults.object(forKey: "homeExperienceEnabled"))
        XCTAssertNil(defaults.object(forKey: "homeExperiencePromptDecision"))
        XCTAssertNil(defaults.object(forKey: "home.showSeoulBusStop"))
        XCTAssertNil(defaults.object(forKey: "home.seoulBusStop"))
        XCTAssertEqual(defaults.object(forKey: "home.showBus50Transfer") as? Bool, false)
    }

    func testObsoleteKeysListIsStable() {
        XCTAssertEqual(
            LegacyHomeExperienceCleanup.obsoleteKeys,
            ["homeExperienceEnabled", "homeExperiencePromptDecision", "home.showSeoulBusStop", "home.seoulBusStop"]
        )
    }
}
