//
//  CafeteriaCoachMarkFlowTests.swift
//  hyuabot
//

import UIKit
import XCTest
@testable import hyuabot

@MainActor
final class CafeteriaCoachMarkFlowTests: XCTestCase {
    private struct HostContext {
        let window: UIWindow
        let nav: UINavigationController
        let host: UIViewController
        let target: UIView
    }

    private final class Counter {
        var finished = 0
    }

    private var pageId = ""

    override func setUp() {
        super.setUp()
        pageId = "test.cafeteria.\(UUID().uuidString)"
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "coachMark.\(pageId).v999")
        super.tearDown()
    }

    private func makeHost() -> HostContext {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        let host = UIViewController()
        nav.pushViewController(host, animated: false)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        let target = UIView(frame: CGRect(x: 20, y: 200, width: 100, height: 50))
        host.view.addSubview(target)
        window.layoutIfNeeded()
        addTeardownBlock {
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        return HostContext(window: window, nav: nav, host: host, target: target)
    }

    private func items(_ view: UIView, count: Int) -> [CoachMarkItem] {
        (0..<count).map { index in
            CoachMarkItem(id: "cafeteria.test.\(index)", targetView: view, title: "Title", message: "Message")
        }
    }

    private func flow() -> CafeteriaCoachMarkFlow {
        CafeteriaCoachMarkFlow(pageId: pageId, version: 999)
    }

    private func overlays(in window: UIWindow) -> [CoachMarkView] {
        window.subviews.compactMap { $0 as? CoachMarkView }
    }

    private func waitUntil(_ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(2)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    private func spin(_ duration: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(duration))
    }

    func testSkippingFirstStageMarksPageAndNeverStartsInfoStage() throws {
        let context = makeHost()
        let flow = flow()
        let box = Counter()
        XCTAssertTrue(flow.presentFirstStage(on: context.host, items: items(context.target, count: 2)) { box.finished += 1 })
        let overlay = try XCTUnwrap(overlays(in: context.window).first)
        overlay.skip()
        waitUntil { overlay.superview == nil }
        spin(0.3)
        XCTAssertEqual(box.finished, 0)
        XCTAssertFalse(flow.isInfoPending)
        XCTAssertFalse(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
        XCTAssertFalse(flow.presentFirstStage(on: context.host, items: items(context.target, count: 2)) {})
        XCTAssertFalse(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        XCTAssertTrue(overlays(in: context.window).isEmpty)
    }

    func testPendingInfoIsKeptWhileBlockedBySheetAndClearedAfterItFinishes() throws {
        let context = makeHost()
        let flow = flow()
        flow.markInfoPending()
        context.nav.present(UIViewController(), animated: false)
        waitUntil { context.nav.presentedViewController != nil }
        XCTAssertFalse(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        XCTAssertTrue(flow.isInfoPending)
        XCTAssertTrue(overlays(in: context.window).isEmpty)
        context.nav.dismiss(animated: false)
        waitUntil { context.nav.presentedViewController == nil }
        XCTAssertTrue(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        let overlay = try XCTUnwrap(overlays(in: context.window).first)
        XCTAssertTrue(flow.isInfoPending)
        overlay.skip()
        waitUntil { overlay.superview == nil }
        spin(0.3)
        XCTAssertFalse(flow.isInfoPending)
        XCTAssertFalse(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
    }

    func testCancelingInfoStageKeepsItPendingWithoutMarkingPage() throws {
        let context = makeHost()
        let flow = flow()
        flow.markInfoPending()
        XCTAssertTrue(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        let overlay = try XCTUnwrap(overlays(in: context.window).first)
        context.host.dismissActiveCoachMarks()
        XCTAssertNil(overlay.superview)
        spin(0.5)
        XCTAssertTrue(flow.isInfoPending)
        XCTAssertTrue(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
        XCTAssertTrue(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
    }

    func testFirstStageIsNotRestartedWhileInfoIsPending() throws {
        let context = makeHost()
        let flow = flow()
        let box = Counter()
        XCTAssertTrue(flow.presentFirstStage(on: context.host, items: items(context.target, count: 1)) { box.finished += 1 })
        let first = try XCTUnwrap(overlays(in: context.window).first)
        first.advance()
        waitUntil { first.superview == nil }
        spin(0.3)
        XCTAssertEqual(box.finished, 1)
        XCTAssertTrue(flow.isInfoPending)
        XCTAssertTrue(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))

        XCTAssertTrue(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        context.host.dismissActiveCoachMarks()
        spin(0.3)
        XCTAssertTrue(flow.isInfoPending)
        XCTAssertTrue(overlays(in: context.window).isEmpty)

        XCTAssertFalse(flow.presentFirstStage(on: context.host, items: items(context.target, count: 2)) { box.finished += 1 })
        XCTAssertTrue(overlays(in: context.window).isEmpty)
        XCTAssertTrue(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        let info = try XCTUnwrap(overlays(in: context.window).first)
        XCTAssertEqual(overlays(in: context.window).count, 1)
        XCTAssertTrue(flow.isInfoPending)
        info.skip()
        waitUntil { info.superview == nil }
        spin(0.3)
        XCTAssertFalse(flow.isInfoPending)
        XCTAssertFalse(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
        XCTAssertEqual(box.finished, 1)
        XCTAssertFalse(flow.presentFirstStage(on: context.host, items: items(context.target, count: 2)) { box.finished += 1 })
        XCTAssertFalse(flow.presentPendingInfo(on: context.host, items: items(context.target, count: 1)))
        XCTAssertTrue(overlays(in: context.window).isEmpty)
    }
}
