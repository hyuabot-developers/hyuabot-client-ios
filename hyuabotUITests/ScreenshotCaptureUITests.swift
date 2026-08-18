//
//  ScreenshotCaptureUITests.swift
//  hyuabotUITests
//
//  Screenshot capture test for App Store assets.
//  Usage: xcodebuild test -only-testing:hyuabotUITests/ScreenshotCaptureUITests/testCaptureScreenshots
//  Environment variables:
//    SCREENSHOT_DIR  – destination folder (must already exist)
//    SCREENSHOT_LANG – "en" | "zh-Hans" | "ja"

import XCTest

final class ScreenshotCaptureUITests: XCTestCase {
    // MARK: - Main test

    func testCaptureScreenshots() throws {
        // Try reading from config file first (written by the shell orchestrator),
        // then fall back to env vars, then hard-coded defaults.
        var outputDir = "/tmp/hyuabot_screenshots"
        var language = "en"

        let configPath = "/tmp/screenshot_config.json"
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        {
            outputDir = json["SCREENSHOT_DIR"] ?? outputDir
            language = json["SCREENSHOT_LANG"] ?? language
        } else {
            outputDir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] ?? outputDir
            language = ProcessInfo.processInfo.environment["SCREENSHOT_LANG"] ?? language
        }

        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true
        )

        // Phase 1 – Home screen (requires home experience to be enabled)
        captureHomeScreen(language: language, outputDir: outputDir)

        // Phase 2 – All other screens (home experience disabled)
        captureRemainingScreens(language: language, outputDir: outputDir)
    }

    // MARK: - Phase helpers

    private func captureHomeScreen(language: String, outputDir: String) {
        let app = makeApp(language: language, homeEnabled: true)
        app.launch()
        guard app.wait(for: .runningForeground, timeout: 15) else {
            XCTFail("App failed to launch for home screen capture")
            return
        }
        waitForSettle()
        saveScreenshot(name: "home", to: outputDir)
        app.terminate()
    }

    private func captureRemainingScreens(language: String, outputDir: String) {
        let app = makeApp(language: language, homeEnabled: false)
        app.launch()
        guard app.wait(for: .runningForeground, timeout: 15) else {
            XCTFail("App failed to launch for remaining screens capture")
            return
        }
        waitForSettle()

        // Shuttle realtime (default screen when home is disabled)
        saveScreenshot(name: "shuttle", to: outputDir)

        // Shuttle timetable
        captureShuttleTimetable(app: app, language: language, outputDir: outputDir)

        // Remaining tabs
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar not found")
            return
        }

        for (tabID, screenName) in [
            ("tab.bus", "bus"),
            ("tab.subway", "subway"),
            ("tab.cafeteria", "cafeteria"),
            ("tab.campus", "campus")
        ] {
            let button = tabBar.buttons[tabID]
            guard button.waitForExistence(timeout: 5) else {
                XCTFail("\(tabID) not found")
                continue
            }
            button.tap()
            waitForSettle()
            saveScreenshot(name: screenName, to: outputDir)
        }

        // Settings screen (from Campus tab)
        let settingButton = app.buttons["campus.tool.setting"]
        guard settingButton.waitForExistence(timeout: 5) else {
            XCTFail("campus.tool.setting not found")
            return
        }
        settingButton.tap()
        waitForSettle()
        saveScreenshot(name: "settings", to: outputDir)

        app.terminate()
    }

    private func captureShuttleTimetable(
        app: XCUIApplication,
        language: String,
        outputDir: String
    ) {
        let buttonLabel = timetableButtonLabel(for: language)

        // The "Show Entire Timetable" button lives in the table footer.
        // Try finding it directly, then scroll down repeatedly if needed.
        var tapped = false
        let maxSwipes = 6

        for attempt in 0 ... maxSwipes {
            let btn = app.buttons.matching(
                NSPredicate(format: "label == %@", buttonLabel)
            ).firstMatch

            if btn.waitForExistence(timeout: attempt == 0 ? 3 : 1) {
                btn.tap()
                tapped = true
                break
            }
            if attempt < maxSwipes {
                app.swipeUp()
            }
        }

        waitForSettle()
        saveScreenshot(name: "shuttle-timetable", to: outputDir)

        if tapped {
            // Navigate back to shuttle realtime
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.waitForExistence(timeout: 3) {
                backButton.tap()
                waitForSettle()
            }
        }
    }

    // MARK: - Factory helpers

    private func makeApp(language: String, homeEnabled: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestsDisableCoachMarks",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", localeIdentifier(for: language),
            "-homeExperienceEnabled", homeEnabled ? "YES" : "NO",
            "-homeExperiencePromptDecision", "YES"
        ]
        return app
    }

    private func localeIdentifier(for language: String) -> String {
        switch language {
        case "en": "en_US"
        case "zh-Hans": "zh_Hans_CN"
        case "ja": "ja_JP"
        default: language
        }
    }

    private func timetableButtonLabel(for language: String) -> String {
        switch language {
        case "en": "Show Entire Timetable"
        case "zh-Hans": "查看完整时刻表"
        case "ja": "全時刻表を表示"
        default: "전체 시간표 보기"
        }
    }

    // MARK: - Capture helpers

    private func waitForSettle() {
        Thread.sleep(forTimeInterval: 2.0)
    }

    private func saveScreenshot(name: String, to dir: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let data = screenshot.pngRepresentation
        let path = (dir as NSString).appendingPathComponent("\(name).png")
        let success = FileManager.default.createFile(atPath: path, contents: data)
        if !success {
            XCTFail("Failed to write screenshot: \(path)")
        }
    }
}
