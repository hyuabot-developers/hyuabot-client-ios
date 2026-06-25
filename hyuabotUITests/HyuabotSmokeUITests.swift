//
//  HyuabotSmokeUITests.swift
//  hyuabotUITests
//

import XCTest

final class HyuabotSmokeUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAppLaunches() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    func testPrimaryTabsCanBeOpened() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        for tab in ["tab.shuttle", "tab.bus", "tab.subway", "tab.cafeteria"] {
            let button = tabBar.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "\(tab) should exist")
            button.tap()
        }
    }

    func testMoreMenuDestinationsCanBeOpened() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons["More"].tap()

        let moreTable = app.tables.firstMatch
        XCTAssertTrue(moreTable.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(moreTable.cells.count, 4)
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestsDisableCoachMarks",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        return app
    }
}
