//
//  UIQualityUITests.swift
//  hyuabotUITests
//

import XCTest

final class UIQualityUITests: XCTestCase {
    private let screenshotLifetime: XCTAttachment.Lifetime = .keepAlways

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testPrimaryTabsVisualQuality() {
        let app = makeApp()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let pages: [Page] = [
            Page(name: "shuttle", tabIdentifier: "tab.shuttle", expectedElementIdentifier: nil),
            Page(name: "bus", tabIdentifier: "tab.bus", expectedElementIdentifier: nil),
            Page(name: "subway", tabIdentifier: "tab.subway", expectedElementIdentifier: nil),
            Page(name: "cafeteria", tabIdentifier: "tab.cafeteria", expectedElementIdentifier: "cafeteria_share_button")
        ]

        for page in pages {
            open(page, in: app)
            capture(page.name, app: app)
            let issues = auditVisibleLayout(app: app, pageName: page.name)
            XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
        }
    }

    func testShuttleQuickSettingsVisualQuality() throws {
        let app = makeApp()
        app.launchArguments += [
            "-homeExperienceEnabled", "NO",
            "-homeExperiencePromptDecision", "YES"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let button = app.buttons["shuttle.quick_settings"]
        guard button.waitForExistence(timeout: 15) else {
            throw XCTSkip("Shuttle quick settings is not available in this build.")
        }
        button.tap()

        let firstRow = app.otherElements["shuttle.quick_settings.arrival_by_time_row"]
        let secondRow = app.otherElements["shuttle.quick_settings.departure_time_row"]
        let homeButton = app.buttons["shuttle.quick_settings.open_home"]
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5))
        XCTAssertTrue(secondRow.waitForExistence(timeout: 5))
        XCTAssertTrue(homeButton.waitForExistence(timeout: 5))

        capture("shuttle-quick-settings", app: app)
        XCTAssertEqual(firstRow.frame.height, secondRow.frame.height, accuracy: 1)
        XCTAssertEqual(firstRow.frame.width, secondRow.frame.width, accuracy: 1)

        let issues = auditSheetLayout(
            pageName: "shuttle-quick-settings",
            elements: [firstRow, secondRow, homeButton],
            screen: app.windows.firstMatch.frame
        )
        XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
    }

    func testMoreDestinationsVisualQuality() {
        let app = makeApp()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        tapMoreButton(in: app)
        let moreTable = app.tables.firstMatch
        XCTAssertTrue(moreTable.waitForExistence(timeout: 5))
        capture("more", app: app)

        let issues = auditVisibleLayout(app: app, pageName: "more")
        XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
    }

    func testTopLevelPagesScrolledVisualQuality() {
        runScrolledVisualQuality(pages: [
            "shuttle",
            "bus",
            "subway",
            "cafeteria",
            "map",
            "reading-room",
            "contact",
            "calendar",
            "setting"
        ])
    }

    func testShuttleScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["shuttle"])
    }

    func testBusScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["bus"])
    }

    func testSubwayScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["subway"])
    }

    func testCafeteriaScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["cafeteria"])
    }

    func testMapScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["map"])
    }

    func testReadingRoomScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["reading-room"])
    }

    func testContactScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["contact"])
    }

    func testCalendarScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["calendar"])
    }

    func testSettingScrolledVisualQuality() {
        runScrolledVisualQuality(pages: ["setting"])
    }

    private func runScrolledVisualQuality(pages: [String]) {
        for page in pages {
            let app = makeApp(initialRoute: page)
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "\(page) should launch")
            waitForPageToSettle(app)

            let issues = captureAndAuditScrolledPage(page, app: app)
            XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
            app.terminate()
        }
    }

    func testTopLevelPagesInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: [
            "shuttle",
            "bus",
            "subway",
            "cafeteria",
            "map",
            "reading-room",
            "contact",
            "calendar",
            "setting"
        ])
    }

    func testShuttleInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["shuttle"])
    }

    func testBusInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["bus"])
    }

    func testSubwayInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["subway"])
    }

    func testCafeteriaInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["cafeteria"])
    }

    func testMapInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["map"])
    }

    func testReadingRoomInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["reading-room"])
    }

    func testContactInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["contact"])
    }

    func testCalendarInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["calendar"])
    }

    func testSettingInteractiveVisualQuality() {
        runInteractiveVisualQuality(pages: ["setting"])
    }

    private func runInteractiveVisualQuality(pages: [String]) {
        for page in pages {
            let app = makeApp(initialRoute: page)
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "\(page) should launch")
            waitForPageToSettle(app)

            var issues: [String] = []
            issues.append(contentsOf: exerciseViewPagerTabs(pageName: page, app: app))
            issues.append(contentsOf: exercisePlannedInteractions(pageName: page, app: app))
            XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
            app.terminate()
        }
    }

    private func makeApp() -> XCUIApplication {
        makeApp(initialRoute: nil)
    }

    private func makeApp(initialRoute: String?) -> XCUIApplication {
        let app = XCUIApplication()
        let language = ProcessInfo.processInfo.environment["UIQUALITY_LANGUAGE"] ?? "en"
        let locale = ProcessInfo.processInfo.environment["UIQUALITY_LOCALE"] ?? (language == "en" ? "en_US" : "ko_KR")
        let style = ProcessInfo.processInfo.environment["UIQUALITY_STYLE"] ?? "dark"
        app.launchArguments = [
            "-UITestsDisableCoachMarks",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "-homeExperienceEnabled", "NO",
            "-homeExperiencePromptDecision", "YES"
        ]
        if style == "dark" {
            app.launchArguments += ["-UITestDarkMode"]
        }
        if let initialRoute {
            app.launchArguments += ["-UITestInitialRoute", initialRoute]
        }
        return app
    }

    private func open(_ page: Page, in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))

        let button = tabBar.buttons[page.tabIdentifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(page.tabIdentifier) should exist")
        button.tap()

        if let expected = page.expectedElementIdentifier {
            XCTAssertTrue(app.descendants(matching: .any)[expected].waitForExistence(timeout: 10), "\(expected) should exist")
        } else {
            sleep(1)
        }
    }

    private func tapMoreButton(in app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))

        let englishMore = tabBar.buttons["More"]
        if englishMore.exists {
            englishMore.tap()
            return
        }

        let koreanMore = tabBar.buttons["더 보기"]
        if koreanMore.exists {
            koreanMore.tap()
            return
        }

        let buttons = tabBar.buttons.allElementsBoundByIndex
        XCTAssertFalse(buttons.isEmpty)
        buttons.last?.tap()
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "UI Quality - \(name)"
        attachment.lifetime = screenshotLifetime
        add(attachment)
    }

    private func captureAndAuditScrolledPage(_ pageName: String, app: XCUIApplication) -> [String] {
        var issues: [String] = []
        for index in 0 ..< 3 {
            waitForPageToSettle(app)
            capture("\(pageName)-scroll-\(index)", app: app)
            if pageName == "contact" {
                issues.append(contentsOf: auditElements(
                    identifiers: ["contact.search_text_field"],
                    pageName: "\(pageName)-scroll-\(index)",
                    app: app
                ))
            } else {
                issues.append(contentsOf: auditVisibleLayout(app: app, pageName: "\(pageName)-scroll-\(index)"))
            }
            app.swipeUp()
        }
        return issues
    }

    private func exerciseViewPagerTabs(pageName: String, app: XCUIApplication) -> [String] {
        var issues: [String] = []
        let tabs = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "viewpager.tab."))
            .allElementsBoundByIndex
            .filter { $0.exists && $0.isHittable }

        for (index, tab) in tabs.prefix(8).enumerated() {
            let label = tab.label.isEmpty ? "tab-\(index)" : tab.label
            tab.tap()
            waitForPageToSettle(app)
            capture("\(pageName)-viewpager-\(safeName(label))", app: app)
            issues.append(contentsOf: auditVisibleLayout(app: app, pageName: "\(pageName)-viewpager-\(label)"))
            app.swipeUp()
            waitForPageToSettle(app)
            capture("\(pageName)-viewpager-\(safeName(label))-scrolled", app: app)
            issues.append(contentsOf: auditVisibleLayout(app: app, pageName: "\(pageName)-viewpager-\(label)-scrolled"))
            app.swipeDown()
            waitForPageToSettle(app)
        }
        return issues
    }

    private func exercisePlannedInteractions(pageName: String, app: XCUIApplication) -> [String] {
        var issues: [String] = []
        switch pageName {
        case "shuttle":
            if app.buttons["shuttle.quick_settings"].waitForExistence(timeout: 5) {
                app.buttons["shuttle.quick_settings"].tap()
                waitForPageToSettle(app)
                capture("shuttle-quick-settings-from-interaction", app: app)
                issues.append(contentsOf: auditKnownSheetRows(app: app, pageName: "shuttle-quick-settings-from-interaction"))
                closePresentedUIIfNeeded(app)
            }
        case "bus":
            issues.append(contentsOf: tapAndAudit(
                identifier: "bus.open_help",
                name: "bus-help-sheet",
                app: app,
                closeAfter: true,
                requiredElementIdentifier: "bus.help.title",
                auditAfterTap: false
            ))
        case "cafeteria":
            issues.append(contentsOf: tapAndAudit(identifier: "cafeteria.previous_date", name: "cafeteria-previous-date", app: app))
            issues.append(contentsOf: tapAndAudit(identifier: "cafeteria.next_date", name: "cafeteria-next-date", app: app))
            if app.buttons["cafeteria_share_button"].exists {
                capture("cafeteria-share-button-visible", app: app)
                issues.append(contentsOf: auditVisibleLayout(app: app, pageName: "cafeteria-share-button-visible"))
            }
        case "map":
            issues.append(contentsOf: enterSearchText(
                identifier: "map.search_text_field",
                name: "map-search",
                app: app
            ))
        case "reading-room":
            issues.append(contentsOf: auditButtons([
                "reading_room.alarm_3hour",
                "reading_room.alarm_4hour"
            ], pageName: "reading-room-alarm-buttons", app: app))
        case "contact":
            issues.append(contentsOf: auditElements(
                identifiers: ["contact.search_text_field"],
                pageName: "contact-search-field",
                app: app
            ))
        case "calendar":
            issues.append(contentsOf: tapAndAudit(identifier: "calendar.previous_month", name: "calendar-previous-month", app: app))
            issues.append(contentsOf: tapAndAudit(identifier: "calendar.next_month", name: "calendar-next-month", app: app))
        case "setting":
            issues.append(contentsOf: tapSegmentedControl(identifier: "setting.campus_control", name: "setting-campus-control", app: app))
            issues.append(contentsOf: tapSegmentedControl(identifier: "setting.theme_control", name: "setting-theme-control", app: app))
            issues.append(contentsOf: tapAndAudit(identifier: "setting.analytics_switch", name: "setting-analytics-switch", app: app))
        default:
            break
        }
        return issues
    }

    private func tapAndAudit(
        identifier: String,
        name: String,
        app: XCUIApplication,
        closeAfter: Bool = false,
        requiredElementIdentifier: String? = nil,
        auditAfterTap: Bool = true
    ) -> [String] {
        let element = app.descendants(matching: .any)[identifier]
        guard element.waitForExistence(timeout: 5), element.isHittable else {
            return ["\(name): \(identifier) is missing or not hittable"]
        }
        element.tap()
        waitForPageToSettle(app)
        if let requiredElementIdentifier {
            let required = app.descendants(matching: .any)[requiredElementIdentifier]
            guard required.waitForExistence(timeout: 5) else {
                return ["\(name): \(requiredElementIdentifier) did not appear after tapping \(identifier)"]
            }
        }
        capture(name, app: app)
        let issues = auditAfterTap ? auditVisibleLayout(app: app, pageName: name) : []
        if closeAfter {
            closePresentedUIIfNeeded(app)
        }
        return issues
    }

    private func tapSegmentedControl(identifier: String, name: String, app: XCUIApplication) -> [String] {
        let element = app.segmentedControls[identifier]
        guard element.waitForExistence(timeout: 5), element.isHittable else {
            return ["\(name): \(identifier) is missing or not hittable"]
        }
        let buttons = element.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
        if let target = identifier == "setting.theme_control" ? buttons.first : buttons.last {
            target.tap()
        } else {
            element.tap()
        }
        waitForPageToSettle(app)
        capture(name, app: app)
        return auditVisibleLayout(app: app, pageName: name)
    }

    private func enterSearchText(identifier: String, name: String, app: XCUIApplication) -> [String] {
        let field = app.searchFields[identifier].exists ? app.searchFields[identifier] : app.textFields[identifier]
        guard field.waitForExistence(timeout: 5), field.isHittable else {
            return ["\(name): \(identifier) is missing or not hittable"]
        }
        field.tap()
        waitForPageToSettle(app)
        capture(name, app: app)
        let issues = auditVisibleLayout(app: app, pageName: name)
        app.keyboards.buttons["Return"].tapIfExists()
        app.swipeDown()
        waitForPageToSettle(app)
        return issues
    }

    private func auditButtons(_ identifiers: [String], pageName: String, app: XCUIApplication) -> [String] {
        auditElements(identifiers: identifiers, pageName: pageName, app: app)
    }

    private func auditElements(identifiers: [String], pageName: String, app: XCUIApplication) -> [String] {
        var issues: [String] = []
        for identifier in identifiers {
            let element = app.descendants(matching: .any)[identifier]
            guard element.waitForExistence(timeout: 5) else {
                issues.append("\(pageName): \(identifier) is missing")
                continue
            }
            if !element.isHittable {
                issues.append("\(pageName): \(identifier) is not hittable")
            }
            let screen = app.windows.firstMatch.frame
            let frame = element.frame
            if frame.minX < -1 || frame.maxX > screen.maxX + 1 {
                issues.append("\(pageName): \(identifier) is horizontally offscreen frame=\(frame), screen=\(screen)")
            }
        }
        capture(pageName, app: app)
        return issues
    }

    private func auditKnownSheetRows(app: XCUIApplication, pageName: String) -> [String] {
        let firstRow = app.otherElements["shuttle.quick_settings.arrival_by_time_row"]
        let secondRow = app.otherElements["shuttle.quick_settings.departure_time_row"]
        let homeButton = app.buttons["shuttle.quick_settings.open_home"]
        guard firstRow.exists, secondRow.exists, homeButton.exists else {
            return ["\(pageName): expected quick settings controls are missing"]
        }
        var issues = auditSheetLayout(pageName: pageName, elements: [firstRow, secondRow, homeButton], screen: app.windows.firstMatch.frame)
        if abs(firstRow.frame.height - secondRow.frame.height) > 1 {
            issues.append("\(pageName): quick settings row heights differ \(firstRow.frame.height) vs \(secondRow.frame.height)")
        }
        return issues
    }

    private func closePresentedUIIfNeeded(_ app: XCUIApplication) {
        let closeLabels = ["닫기", "취소", "Cancel", "Done", "확인"]
        for label in closeLabels {
            let button = app.buttons[label]
            if button.exists, button.isHittable {
                button.tap()
                waitForPageToSettle(app)
                return
            }
        }
        if app.navigationBars.buttons.element(boundBy: 0).exists,
           app.navigationBars.buttons.element(boundBy: 0).isHittable
        {
            app.navigationBars.buttons.element(boundBy: 0).tap()
            waitForPageToSettle(app)
            return
        }
        app.swipeDown()
        waitForPageToSettle(app)
    }

    private func safeName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
    }

    private func waitForPageToSettle(_ app: XCUIApplication) {
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
        let settleTime = UInt32(ProcessInfo.processInfo.environment["UIQUALITY_SETTLE_USEC"] ?? "800000") ?? 800_000
        usleep(settleTime)
    }

    private func auditVisibleLayout(app: XCUIApplication, pageName: String) -> [String] {
        var issues: [String] = []
        let screen = app.windows.firstMatch.frame
        let visibleElements = representativeElements(app: app, screen: screen)

        for element in visibleElements {
            let frame = element.frame
            guard frame.isFinite, !frame.isEmpty else { continue }
            guard visibleRatio(of: frame, in: screen) >= 0.5 else { continue }
            if frame.width < 1 || frame.height < 1 {
                issues.append("\(pageName): tiny visible element \(element.debugLabel) frame=\(frame)")
            }
            if frame.minX < -1 || frame.maxX > screen.maxX + 1 {
                issues.append("\(pageName): horizontally offscreen element \(element.debugLabel) frame=\(frame), screen=\(screen)")
            }
        }

        issues.append(contentsOf: auditFloatingButtons(app: app, pageName: pageName, screen: screen))
        return issues
    }

    private func auditSheetLayout(pageName: String, elements: [XCUIElement], screen: CGRect) -> [String] {
        var issues: [String] = []
        for element in elements {
            let frame = element.frame
            if frame.isEmpty {
                issues.append("\(pageName): empty sheet element \(element.debugLabel)")
            }
            if frame.minX < -1 || frame.maxX > screen.maxX + 1 || frame.minY < -1 || frame.maxY > screen.maxY + 1 {
                issues.append("\(pageName): sheet element offscreen \(element.debugLabel) frame=\(frame), screen=\(screen)")
            }
        }

        for lhsIndex in elements.indices {
            for rhsIndex in elements.indices where rhsIndex > lhsIndex {
                let lhs = elements[lhsIndex]
                let rhs = elements[rhsIndex]
                if lhs.frame.intersects(rhs.frame) {
                    issues.append("\(pageName): sheet elements overlap \(lhs.debugLabel) and \(rhs.debugLabel)")
                }
            }
        }
        return issues
    }

    private func representativeElements(app: XCUIApplication, screen: CGRect) -> [XCUIElement] {
        let queries: [XCUIElementQuery] = [
            app.staticTexts,
            app.switches,
            app.segmentedControls,
            app.images
        ]
        return queries.flatMap { query in
            query.allElementsBoundByIndex.filter { element in
                element.exists && !element.frame.isEmpty && visibleRatio(of: element.frame, in: screen) >= 0.5
                    && shouldAudit(element)
            }
        }
    }

    private func shouldAudit(_ element: XCUIElement) -> Bool {
        if element.elementType == .staticText, element.label.hasPrefix("[공지]") {
            return false
        }
        return true
    }

    private func visibleRatio(of frame: CGRect, in screen: CGRect) -> CGFloat {
        guard !frame.isEmpty else { return 0 }
        let intersection = frame.intersection(screen)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        return (intersection.width * intersection.height) / (frame.width * frame.height)
    }

    private func auditFloatingButtons(app: XCUIApplication, pageName: String, screen: CGRect) -> [String] {
        let floatingIdentifiers: [String] = []
        var issues: [String] = []

        for identifier in floatingIdentifiers {
            let floating = app.buttons[identifier]
            guard floating.exists else { continue }
            let frame = floating.frame
            if frame.maxY > screen.maxY - 80 {
                issues.append("\(pageName): floating button \(identifier) is too close to the tab bar frame=\(frame)")
            }

            let overlaps = app.staticTexts.allElementsBoundByIndex
                .filter { $0.exists && !$0.frame.isEmpty && $0.frame.intersects(frame.insetBy(dx: -4, dy: -4)) }
                .map(\.debugLabel)

            if !overlaps.isEmpty {
                let overlapText = overlaps.joined(separator: ", ")
                issues.append("\(pageName): floating button \(identifier) overlaps text \(overlapText) frame=\(frame)")
            }
        }
        return issues
    }
}

private struct Page {
    let name: String
    let tabIdentifier: String
    let expectedElementIdentifier: String?
}

private extension CGRect {
    var isFinite: Bool {
        origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite
    }
}

private extension XCUIElement {
    func tapIfExists() {
        if exists, isHittable {
            tap()
        }
    }

    var debugLabel: String {
        let id = identifier.isEmpty ? "-" : identifier
        let label = label.isEmpty ? "-" : label
        return "\(elementTypeDescription)(id: \(id), label: \(label))"
    }

    var elementTypeDescription: String {
        switch elementType {
        case .button:
            "button"
        case .staticText:
            "text"
        case .switch:
            "switch"
        case .cell:
            "cell"
        case .image:
            "image"
        default:
            "\(elementType.rawValue)"
        }
    }
}
