//
//  StateViewSnapshotTests.swift
//  hyuabotTests
//

@testable import hyuabot
import SnapshotTesting
import UIKit
import XCTest

@MainActor
final class StateViewSnapshotTests: XCTestCase {
    private let size = CGSize(width: 390, height: 260)
    // AX5 text and the 64pt vertical padding need a taller canvas to show every element.
    private let axSize = CGSize(width: 390, height: 720)

    func testEmptyLightSnapshot() { assertState(.empty(message: "표시할 항목이 없습니다. 다른 조건으로 검색해 보세요."), traits: lightTraits, name: "empty-light") }
    func testEndedLightSnapshot() { assertState(.ended(onShowTimetable: {}), traits: lightTraits, name: "ended-light") }
    func testSuspendedLightSnapshot() { assertState(.suspended(date: Date(timeIntervalSince1970: 1_700_000_000), onShowTimetable: {}), traits: lightTraits, name: "suspended-light") }
    func testErrorLightSnapshot() { assertState(.error(onRetry: {}), traits: lightTraits, name: "error-light") }
    func testPermissionDeniedLightSnapshot() { assertState(.permissionDenied(onOpenSettings: {}), traits: lightTraits, name: "permission-denied-light") }

    func testEmptyDarkSnapshot() { assertState(.empty(message: "표시할 항목이 없습니다."), traits: darkTraits, name: "empty-dark") }
    func testErrorDarkSnapshot() { assertState(.error(onRetry: {}), traits: darkTraits, name: "error-dark") }
    func testEndedDarkSnapshot() { assertState(.ended(onShowTimetable: {}), traits: darkTraits, name: "ended-dark") }
    func testSuspendedDarkSnapshot() { assertState(.suspended(date: Date(timeIntervalSince1970: 1_700_000_000), onShowTimetable: {}), traits: darkTraits, name: "suspended-dark") }
    func testPermissionDeniedDarkSnapshot() { assertState(.permissionDenied(onOpenSettings: {}), traits: darkTraits, name: "permission-denied-dark") }

    func testEmptyAccessibilitySnapshot() {
        assertState(.empty(message: "표시할 항목이 없습니다."), traits: axTraits, name: "empty-ax5")
    }

    func testErrorAccessibilitySnapshot() {
        assertState(.error(onRetry: {}), traits: axTraits, name: "error-ax5")
    }

    func testEndedAccessibilitySnapshot() {
        assertState(.ended(onShowTimetable: {}), traits: axTraits, name: "ended-ax5")
    }

    func testSuspendedAccessibilitySnapshot() {
        assertState(
            .suspended(date: Date(timeIntervalSince1970: 1_700_000_000), onShowTimetable: {}),
            traits: axTraits,
            name: "suspended-ax5"
        )
    }

    func testPermissionDeniedAccessibilitySnapshot() {
        assertState(.permissionDenied(onOpenSettings: {}), traits: axTraits, name: "permission-denied-ax5")
    }

    private func assertState(_ content: StateContent, traits: UITraitCollection, name: String) {
        let view = StateView(sourceScreen: .map)
        view.apply(content)
        let canvas = traits.preferredContentSizeCategory.isAccessibilityCategory ? axSize : size
        view.frame = CGRect(origin: .zero, size: canvas)
        view.overrideUserInterfaceStyle = traits.userInterfaceStyle
        view.backgroundColor = .systemBackground
        view.layoutIfNeeded()

        assertSnapshot(
            of: view,
            as: .image(size: canvas, traits: traits),
            named: name,
            record: .missing,
            timeout: 5
        )
    }

    private var lightTraits: UITraitCollection {
        UITraitCollection(mutations: { traits in
            traits.displayScale = 3
            traits.userInterfaceStyle = .light
            traits.preferredContentSizeCategory = .large
        })
    }

    private var darkTraits: UITraitCollection {
        UITraitCollection(mutations: { traits in
            traits.displayScale = 3
            traits.userInterfaceStyle = .dark
            traits.preferredContentSizeCategory = .large
        })
    }

    private var axTraits: UITraitCollection {
        UITraitCollection(mutations: { traits in
            traits.displayScale = 3
            traits.userInterfaceStyle = .light
            traits.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        })
    }
}
