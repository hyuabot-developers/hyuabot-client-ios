//
//  HYUHeaderButtonTests.swift
//  hyuabot
//

import XCTest
@testable import hyuabot

@MainActor
final class HYUHeaderButtonTests: XCTestCase {
    func testCapsuleUses36PointShapeInside44PointTarget() {
        let button = HYUHeaderButton(style: .capsule, symbolName: "gearshape.fill", title: "Settings")
        XCTAssertEqual(button.intrinsicContentSize.height, 44)
        XCTAssertGreaterThan(button.intrinsicContentSize.width, 44)

        button.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
        button.layoutIfNeeded()
        XCTAssertEqual(button.capsuleView.bounds.width, 200)
        XCTAssertEqual(button.capsuleView.bounds.height, 36)
        XCTAssertEqual(button.capsuleView.layer.cornerRadius, 18)
    }

    func testCircleIsCentered36PointShapeInside44PointTarget() {
        let button = HYUHeaderButton(style: .circle, symbolName: "gearshape.fill", title: nil)
        XCTAssertEqual(button.intrinsicContentSize, CGSize(width: 44, height: 44))

        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.layoutIfNeeded()
        XCTAssertEqual(button.capsuleView.bounds.width, 36)
        XCTAssertEqual(button.capsuleView.bounds.height, 36)
        XCTAssertEqual(button.capsuleView.center, CGPoint(x: 22, y: 22))
        XCTAssertEqual(button.capsuleView.layer.cornerRadius, 18)
    }

    func testTouchUpInsideReachesTarget() {
        let button = HYUHeaderButton(style: .capsule, symbolName: nil, title: "Settings")
        let target = Target()
        button.addTarget(target, action: #selector(Target.tapped), for: .touchUpInside)
        button.sendActions(for: .touchUpInside)
        XCTAssertTrue(target.didTap)
    }

    func testAccessibilityLabelMatchesTitle() {
        let button = HYUHeaderButton(style: .capsule, symbolName: nil, title: "Settings")
        XCTAssertEqual(button.accessibilityLabel, "Settings")
    }

    private final class Target: NSObject {
        var didTap = false

        @objc
        func tapped() {
            didTap = true
        }
    }
}
