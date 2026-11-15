//
//  CoachMarkViewTests.swift
//  hyuabot
//

@testable import hyuabot
import UIKit
import XCTest

@MainActor
final class CoachMarkViewTests: XCTestCase {
    private struct TestStack {
        let window: UIWindow
        let nav: UINavigationController
        let host: UIViewController
        let target: UIView
    }

    final class Counter {
        var skip = 0
        var complete = 0
    }

    private func makeStack() -> TestStack {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        let host = UIViewController()
        host.view.backgroundColor = .white
        nav.pushViewController(host, animated: false)
        window.layoutIfNeeded()
        let target = UIView(frame: CGRect(x: 20, y: 300, width: 120, height: 44))
        host.view.addSubview(target)
        addTeardownBlock { @MainActor in
            window.rootViewController?.dismiss(animated: false)
            window.isHidden = true
        }
        return TestStack(window: window, nav: nav, host: host, target: target)
    }

    func items(_ target: UIView, count: Int) -> [CoachMarkItem] {
        (0 ..< count).map {
            CoachMarkItem(id: "test.\($0)", targetView: target, title: "T", message: "M")
        }
    }

    func waitUntil(_ timeout: TimeInterval = 2, _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    func testFirstBackTapReachesNavigationBarAndSkipsOnce() throws {
        let stack = makeStack()
        let pageId = "test.coachmark.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults.standard.removeObject(forKey: "coachMark.\(pageId).v999") }
        let counter = Counter()
        XCTAssertTrue(stack.host.presentCoachMarks(
            pageId: pageId,
            items: items(stack.target, count: 2),
            version: 999,
            onSkip: { counter.skip += 1 },
            onComplete: { counter.complete += 1 }
        ))
        let overlay = try XCTUnwrap(stack.window.subviews.compactMap { $0 as? CoachMarkView }.first)
        XCTAssertTrue(overlay.passthroughView === stack.nav.navigationBar)
        let point = stack.nav.navigationBar.convert(
            CGPoint(x: 30, y: stack.nav.navigationBar.bounds.midY),
            to: stack.window
        )
        let barPoint = stack.window.convert(point, to: overlay)
        let outside = CGPoint(x: 195, y: 600)

        XCTAssertTrue(overlay.handlePassthrough(at: barPoint, eventType: nil))
        XCTAssertTrue(overlay.handlePassthrough(at: barPoint, eventType: .motion))
        XCTAssertNil(overlay.hitTest(barPoint, with: nil))
        let hit = stack.window.hitTest(point, with: nil)
        XCTAssertTrue(hit?.isDescendant(of: stack.nav.navigationBar) == true)
        XCTAssertFalse(overlay.handlePassthrough(at: outside, eventType: .touches))
        XCTAssertNotNil(overlay.hitTest(outside, with: nil))
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        XCTAssertEqual(counter.skip, 0)
        XCTAssertEqual(counter.complete, 0)
        XCTAssertNotNil(overlay.superview)

        XCTAssertTrue(overlay.handlePassthrough(at: barPoint, eventType: .touches))
        XCTAssertTrue(overlay.handlePassthrough(at: barPoint, eventType: .touches))
        stack.nav.popViewController(animated: false)
        waitUntil { overlay.superview == nil }
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        XCTAssertEqual(counter.skip, 1)
        XCTAssertEqual(counter.complete, 0)
        XCTAssertFalse(stack.window.subviews.contains { $0 is CoachMarkView })
        XCTAssertFalse(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
        XCTAssertTrue(stack.nav.topViewController !== stack.host)
    }

    func testSkipDismissesWholeSequenceInOneTap() throws {
        let stack = makeStack()
        let pageId = "test.coachmark.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults.standard.removeObject(forKey: "coachMark.\(pageId).v999") }
        let counter = Counter()
        XCTAssertTrue(stack.host.presentCoachMarks(
            pageId: pageId,
            items: items(stack.target, count: 3),
            version: 999,
            onSkip: { counter.skip += 1 },
            onComplete: { counter.complete += 1 }
        ))
        let overlay = try XCTUnwrap(stack.window.subviews.compactMap { $0 as? CoachMarkView }.first)
        overlay.skip()
        waitUntil { overlay.superview == nil }
        XCTAssertFalse(stack.window.subviews.contains { $0 is CoachMarkView })
        XCTAssertEqual(counter.skip, 1)
        XCTAssertEqual(counter.complete, 0)
        XCTAssertFalse(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
    }

    func testPresentCoachMarksRejectedUnderSheet() throws {
        let stack = makeStack()
        let pageId = "test.coachmark.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults.standard.removeObject(forKey: "coachMark.\(pageId).v999") }
        XCTAssertTrue(stack.host.isTopmostForCoachMarks)
        stack.nav.present(UIViewController(), animated: false)
        waitUntil { stack.nav.presentedViewController != nil }
        XCTAssertFalse(stack.host.isTopmostForCoachMarks)
        let sheet = try XCTUnwrap(stack.nav.presentedViewController)
        waitUntil { sheet.viewIfLoaded?.window != nil }
        XCTAssertTrue(sheet.isTopmostForCoachMarks)
        XCTAssertFalse(stack.host.presentCoachMarks(
            pageId: pageId,
            items: items(stack.target, count: 1),
            version: 999
        ))
        XCTAssertFalse(stack.window.subviews.contains { $0 is CoachMarkView })
        XCTAssertTrue(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
    }

    func testCancelRemovesOverlayWithoutCallbacks() throws {
        let stack = makeStack()
        let pageId = "test.coachmark.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults.standard.removeObject(forKey: "coachMark.\(pageId).v999") }
        let counter = Counter()
        XCTAssertTrue(stack.host.presentCoachMarks(
            pageId: pageId,
            items: items(stack.target, count: 2),
            version: 999,
            onSkip: { counter.skip += 1 },
            onComplete: { counter.complete += 1 }
        ))
        let overlay = try XCTUnwrap(stack.window.subviews.compactMap { $0 as? CoachMarkView }.first)
        stack.host.dismissActiveCoachMarks()
        XCTAssertNil(overlay.superview)
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        XCTAssertEqual(counter.skip, 0)
        XCTAssertEqual(counter.complete, 0)
        XCTAssertTrue(CoachMarkManager.shared.shouldShowPage(pageId, version: 999))
    }
}
