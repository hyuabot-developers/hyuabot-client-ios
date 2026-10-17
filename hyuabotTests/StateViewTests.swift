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

    /// WCAG AA requires 4.5:1 for body text. The description label uses HYUColor.Text.secondary,
    /// and StateView sits on the system background, so check the light-mode pair from resolved components.
    func testLightModeDescriptionColorMeetsContrastAgainstBackground() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let text = HYUColor.Text.secondary.resolvedColor(with: light)
        let background = UIColor.systemBackground.resolvedColor(with: light)
        let ratio = contrastRatio(text, background)
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "Light description contrast is \(ratio), below WCAG AA 4.5:1")
    }

    /// Dark mode must keep the system secondary label so the change does not regress it.
    func testDarkModeDescriptionColorKeepsSystemSecondaryLabel() {
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let text = HYUColor.Text.secondary.resolvedColor(with: dark)
        let expected = UIColor.secondaryLabel.resolvedColor(with: dark)
        XCTAssertEqual(components(text), components(expected))
    }

    private func components(_ color: UIColor) -> [CGFloat] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue, alpha]
    }

    /// WCAG 2.x contrast ratio: (L1 + 0.05) / (L2 + 0.05), using sRGB relative luminance.
    private func contrastRatio(_ first: UIColor, _ second: UIColor) -> CGFloat {
        let luminanceA = relativeLuminance(first)
        let luminanceB = relativeLuminance(second)
        return (max(luminanceA, luminanceB) + 0.05) / (min(luminanceA, luminanceB) + 0.05)
    }

    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        let rgb = components(color).prefix(3).map { channel -> CGFloat in
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
    }
}
