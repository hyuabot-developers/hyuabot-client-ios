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
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), app.debugDescription)

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

    func testShuttleQuickSettingsRowsHaveMatchingHeights() {
        let app = makeApp()
        app.launchArguments += [
            "-homeExperienceEnabled", "NO",
            "-homeExperiencePromptDecision", "YES"
        ]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let quickSettingsButton = app.buttons["shuttle.quick_settings"]
        XCTAssertTrue(quickSettingsButton.waitForExistence(timeout: 15))
        quickSettingsButton.tap()

        let firstRow = app.otherElements["shuttle.quick_settings.arrival_by_time_row"]
        let secondRow = app.otherElements["shuttle.quick_settings.departure_time_row"]
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
        XCTAssertTrue(secondRow.waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Shuttle quick settings sheet"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertEqual(firstRow.frame.height, secondRow.frame.height, accuracy: 1)
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestsDisableCoachMarks",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-homeExperienceEnabled", "NO",
            "-homeExperiencePromptDecision", "YES"
        ]
        return app
    }
}
