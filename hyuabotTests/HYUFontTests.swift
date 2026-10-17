//
//  HYUFontTests.swift
//  hyuabot
//

@testable import hyuabot
import UIKit
import XCTest

@MainActor
final class HYUFontTests: XCTestCase {
    func testCaption1FontIsCappedAtAccessibilityExtraExtraExtraLarge() {
        let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let font = HYUFont.font(.caption1, compatibleWith: traits)

        XCTAssertLessThanOrEqual(font.pointSize, 22)
    }
}
