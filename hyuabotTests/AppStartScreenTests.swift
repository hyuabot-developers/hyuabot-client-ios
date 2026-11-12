//
//  AppStartScreenTests.swift
//  hyuabotTests
//
import XCTest
@testable import hyuabot

final class AppStartScreenTests: XCTestCase {
    func testMissingKeyDefaultsToShuttle() {
        guard let defaults = UserDefaults(suiteName: #function) else { return XCTFail("defaults") }
        defaults.removePersistentDomain(forName: #function)

        XCTAssertEqual(AppStartScreen.current(defaults: defaults), .shuttle)
    }

    func testSaveCafeteria() {
        guard let defaults = UserDefaults(suiteName: #function) else { return XCTFail("defaults") }
        defaults.removePersistentDomain(forName: #function)

        AppStartScreen.save(.cafeteria, defaults: defaults)

        XCTAssertEqual(AppStartScreen.current(defaults: defaults), .cafeteria)
        XCTAssertEqual(AppStartScreen.current(defaults: defaults).tabIndex, 3)
    }

    func testSubwayTabIndex() {
        guard let defaults = UserDefaults(suiteName: #function) else { return XCTFail("defaults") }
        defaults.removePersistentDomain(forName: #function)

        AppStartScreen.save(.subway, defaults: defaults)

        XCTAssertEqual(AppStartScreen.current(defaults: defaults).tabIndex, 2)
    }

    func testInvalidRawValueDefaultsToShuttle() {
        guard let defaults = UserDefaults(suiteName: #function) else { return XCTFail("defaults") }
        defaults.removePersistentDomain(forName: #function)
        defaults.set(9, forKey: AppStartScreen.defaultsKey)

        XCTAssertEqual(AppStartScreen.current(defaults: defaults), .shuttle)
    }

    func testAllCasesOrder() {
        XCTAssertEqual(AppStartScreen.allCases, [.shuttle, .bus, .cafeteria, .subway])
    }
}
