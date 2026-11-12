//
//  HyuabotSmokeUITests.swift
//  hyuabotUITests
//

import XCTest

@MainActor
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

        XCTAssertTrue(app.buttons["tab.campus"].waitForExistence(timeout: 10), app.debugDescription)

        for tab in ["tab.shuttle", "tab.bus", "tab.subway", "tab.cafeteria", "tab.campus"] {
            let button = app.buttons[tab]
            XCTAssertTrue(button.waitForExistence(timeout: 5), "\(tab) should exist")
            button.tap()
        }
    }

    func testCampusToolsCanBeOpened() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["tab.campus"].waitForExistence(timeout: 5))
        app.buttons["tab.campus"].tap()

        let destinations = [
            (tool: "map", expected: "map.search_text_field"),
            (tool: "reading_room", expected: "reading_room.alarm_3hour"),
            (tool: "calendar", expected: "calendar.previous_month"),
            (tool: "contact", expected: "contact.search_text_field"),
            (tool: "setting", expected: "setting.campus_control")
        ]
        for destination in destinations {
            let tool = app.buttons["campus.tool.\(destination.tool)"]
            XCTAssertTrue(tool.waitForExistence(timeout: 5), "\(destination.tool) should exist")
            tool.tap()

            let expected = app.descendants(matching: .any)[destination.expected]
            XCTAssertTrue(expected.waitForExistence(timeout: 10), "\(destination.expected) should open")

            if destination.tool == "map" {
                app.buttons["tab.campus"].tap()
            } else {
                let navigationBackButton = app.navigationBars.buttons.firstMatch
                let backButton = navigationBackButton.waitForExistence(timeout: 2)
                    ? navigationBackButton
                    : app.buttons["BackButton"]
                XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Back button should exist")
                backButton.tap()
            }
            XCTAssertTrue(app.buttons["campus.tool.map"].waitForExistence(timeout: 5))
        }
    }

    func testShuttleQuickSettingsRowsHaveMatchingHeights() {
        let app = makeApp()
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
            "-AppleLocale", "en_US"
        ]
        return app
    }
}
