//
//  StateViewTests.swift
//  hyuabotTests
//

@testable import hyuabot
import UIKit
import XCTest

@MainActor
final class StateViewTests: XCTestCase {
    private let traits = UITraitCollection(preferredContentSizeCategory: .large)

    func testEmptyWithoutActionHasNoButtonOrImage() {
        let configuration = StateView.makeConfiguration(for: .empty(message: "No stops"), traits: traits)

        XCTAssertNil(configuration.image)
        XCTAssertNil(configuration.button.title)
        XCTAssertNil(configuration.buttonProperties.primaryAction)
        XCTAssertEqual(configuration.attributedText?.string, "\(String(localized: "state.empty.title"))\nNo stops")
    }

    func testEmptyWithCallerActionShowsButtonAndRunsHandler() {
        var didTap = false
        let content = StateContent.empty(
            message: "No results",
            action: StateAction(title: "Reset filter", handler: { didTap = true })
        )

        let configuration = StateView.makeConfiguration(for: content, traits: traits)

        XCTAssertEqual(configuration.button.title, "Reset filter")
        configuration.buttonProperties.primaryAction?.performWithSender(nil, target: nil)
        XCTAssertTrue(didTap)
    }

    func testErrorShowsWarningIconAndRetryButtonRunsCallback() throws {
        var retried = false
        let configuration = StateView.makeConfiguration(
            for: .error(onRetry: { retried = true }),
            traits: traits
        )

        XCTAssertNotNil(configuration.image)
        XCTAssertEqual(configuration.button.title, String(localized: "state.action.retry"))
        XCTAssertEqual(configuration.attributedText?.string, String(localized: "state.error.title"))
        try XCTUnwrap(configuration.buttonProperties.primaryAction).performWithSender(nil, target: nil)
        XCTAssertTrue(retried)
    }

    func testOnlyErrorShowsIcon() {
        let nonError: [StateContent] = [
            .empty(message: "x"),
            .ended(onShowTimetable: {}),
            .suspended(date: Date(timeIntervalSince1970: 0), onShowTimetable: {}),
            .permissionDenied(onOpenSettings: {}),
        ]
        for content in nonError {
            XCTAssertNil(StateView.makeConfiguration(for: content, traits: traits).image, "\(content.kind)")
        }
    }

    func testEndedHasNoBodyAndTimetableButton() {
        let configuration = StateView.makeConfiguration(for: .ended(onShowTimetable: {}), traits: traits)

        XCTAssertEqual(configuration.attributedText?.string, String(localized: "state.ended.title"))
        XCTAssertEqual(configuration.button.title, String(localized: "state.action.full_timetable"))
    }

    func testSuspendedShowsFormattedDateAsBody() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let content = StateContent.suspended(date: date, onShowTimetable: {})

        let configuration = StateView.makeConfiguration(for: content, traits: traits)
        let text = configuration.attributedText?.string ?? ""

        XCTAssertTrue(text.hasPrefix(String(localized: "state.suspended.title") + "\n"))
        XCTAssertGreaterThan(text.count, String(localized: "state.suspended.title").count + 1)
    }

    func testPermissionDeniedHasSettingsButton() {
        let configuration = StateView.makeConfiguration(for: .permissionDenied(onOpenSettings: {}), traits: traits)

        XCTAssertEqual(configuration.attributedText?.string, String(localized: "state.permission_denied.title"))
        XCTAssertEqual(configuration.button.title, String(localized: "state.action.open_settings"))
    }

    func testLogsOncePerKindWhileInWindow() {
        var logged: [StateKind] = []
        let view = StateView(sourceScreen: .busRealtime)
        view.logShown = { kind, _ in logged.append(kind) }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        view.apply(.empty(message: "x"))
        XCTAssertEqual(logged, [], "not logged before it is in a window")

        window.addSubview(view)
        XCTAssertEqual(logged, [.empty])

        view.apply(.empty(message: "y"))
        XCTAssertEqual(logged, [.empty], "same kind applied again must not log")

        view.apply(.error(onRetry: {}))
        XCTAssertEqual(logged, [.empty, .error])
    }

    func testLogsAgainWhenReAddedToWindow() {
        var count = 0
        let view = StateView(sourceScreen: .map)
        view.logShown = { _, _ in count += 1 }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        view.apply(.empty(message: "x"))

        window.addSubview(view)
        view.removeFromSuperview()
        window.addSubview(view)

        XCTAssertEqual(count, 2)
    }

    func testEmptyCellReuseIdentifiersAreUnchanged() {
        XCTAssertEqual(ShuttleRealtimeEmptyCellView.reuseIdentifier, "ShuttleRealtimeEmptyCellView")
        XCTAssertEqual(BusRealtimeEmptyCellView.reuseIdentifier, "BusRealtimeEmptyCellView")
        XCTAssertEqual(SubwayRealtimeEmptyCellView.reuseIdentifier, "SubwayRealtimeEmptyCellView")
        XCTAssertEqual(BusTimetableEmptyCellView.reuseIdentifier, "BusTimetableEmptyCellView")
        XCTAssertEqual(ShuttleTimetableEmptyCellView.reuseIdentifier, "ShuttleTimetableEmptyCellView")
        XCTAssertEqual(ContactSearchEmptyCellView.reuseIdentifier, "ContactSearchEmptyCellView")
        XCTAssertEqual(SearchEmptyCellView.reuseIdentifier, "SearchEmptyCellView")
    }
}
