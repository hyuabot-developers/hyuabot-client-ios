@testable import hyuabot
import UIKit
import XCTest

@MainActor
final class HyuFontTests: XCTestCase {
    func testCaption1FontIsCappedAtAccessibilityExtraExtraExtraLarge() {
        let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let font = HyuFont.font(.caption1, compatibleWith: traits)

        XCTAssertLessThanOrEqual(font.pointSize, 22)
    }
}
