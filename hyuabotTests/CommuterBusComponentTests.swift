//
//  CommuterBusComponentTests.swift
//  hyuabot
//
//  Created by Codex on 11/8/26.
//

@testable import hyuabot
import XCTest

@MainActor
final class CommuterBusComponentTests: XCTestCase {
    func testStandardScreenRendersSelectedRouteAndBus() throws {
        let vc = makeScreen(.standard)
        let timeline = try XCTUnwrap(findView(withIdentifier: "commuter.timeline", in: vc.view))
        XCTAssertFalse(timeline.isHidden)
        XCTAssertNotNil(findView(withIdentifier: "commuter.bus", in: vc.view))
        let route = try XCTUnwrap(findView(withIdentifier: "commuter.route.4", in: vc.view) as? UIControl)
        XCTAssertTrue(route.accessibilityTraits.contains(.selected))
        let direction = try XCTUnwrap(findView(withIdentifier: "commuter.direction.toCampus", in: vc.view) as? UIControl)
        XCTAssertTrue(direction.accessibilityTraits.contains(.selected))
        XCTAssertNil(findView(withIdentifier: "commuter.notice.off", in: vc.view))
        XCTAssertEqual(vc.title, String(localized: "campus.commuter.title"))
        XCTAssertEqual(vc.view.accessibilityIdentifier, "commuter.root")
    }

    func testLoadingShowsSkeletonInsteadOfTimeline() throws {
        let vc = makeScreen(.loading)
        XCTAssertFalse(try XCTUnwrap(findView(withIdentifier: "commuter.skeleton", in: vc.view)).isHidden)
        XCTAssertTrue(try XCTUnwrap(findView(withIdentifier: "commuter.timeline", in: vc.view)).isHidden)
    }

    func testWeekendShowsOffNoticeAndStatusChip() throws {
        let vc = makeScreen(.weekend)
        XCTAssertNotNil(findView(withIdentifier: "commuter.notice.off", in: vc.view))
        let chip = try XCTUnwrap(findView(withIdentifier: "commuter.chip", in: vc.view))
        XCTAssertEqual((chip.subviews.compactMap { $0 as? UILabel }.first)?.text, String(localized: "commuter.status.off"))
    }

    func testFromCampusShowsPartialNotice() {
        let vc = makeScreen(.from)
        XCTAssertNotNil(findView(withIdentifier: "commuter.notice.partial", in: vc.view))
    }

    func testNoLocationFoldExpandsAndDirectionSelectionUpdatesRoute() throws {
        let vc = makeScreen(.noLocation)
        let fold = try XCTUnwrap(findView(withIdentifier: "commuter.fold", in: vc.view) as? UIControl)
        fold.sendActions(for: .touchUpInside)
        vc.view.layoutIfNeeded()
        XCTAssertNil(findView(withIdentifier: "commuter.fold", in: vc.view))

        let fromCampus = try XCTUnwrap(findView(withIdentifier: "commuter.direction.fromCampus", in: vc.view) as? UIControl)
        fromCampus.sendActions(for: .touchUpInside)
        vc.view.layoutIfNeeded()
        let routeD = try XCTUnwrap(findView(withIdentifier: "commuter.route.D", in: vc.view) as? UIControl)
        XCTAssertTrue(routeD.accessibilityTraits.contains(.selected))
        XCTAssertNotNil(findView(withIdentifier: "commuter.reset_nearest", in: vc.view))
    }

    func testApplyDrivenScreenKeepsFixedClockAndDoesNotReload() {
        let vc = makeScreen(.standard)
        vc.refreshClock(now: CommuterBusLogic.day(year: 2026, month: 11, day: 10))
        vc.beginAppearanceTransition(true, animated: false)
        vc.endAppearanceTransition()
        vc.view.layoutIfNeeded()
        XCTAssertNotNil(findView(withIdentifier: "commuter.bus", in: vc.view))
        XCTAssertNil(findView(withIdentifier: "commuter.notice.off", in: vc.view))
    }

    private func makeScreen(_ mode: CommuterDebugFixture.Mode) -> CommuterBusVC {
        let vc = CommuterBusVC(autoLoad: false)
        vc.loadViewIfNeeded()
        let scenario = CommuterDebugFixture.scenario(mode)
        vc.apply(routes: scenario.routes, context: scenario.context, isLoading: scenario.isLoading)
        vc.view.layoutIfNeeded()
        return vc
    }

    private func findView(withIdentifier identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        for subview in view.subviews {
            if let result = findView(withIdentifier: identifier, in: subview) { return result }
        }
        return nil
    }
}
