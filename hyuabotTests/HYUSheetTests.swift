//
//  HYUSheetTests.swift
//  hyuabot
//

import XCTest
@testable import hyuabot

final class HYUSheetTests: XCTestCase {
    func testConfigureSetsSheetPresentationStyle() {
        let controller = UIViewController()
        controller.modalPresentationStyle = .pageSheet
        let detents: [UISheetPresentationController.Detent] = [.medium(), .large()]

        HYUSheet.configure(controller, detents: detents)

        let sheet = controller.sheetPresentationController
        XCTAssertNotNil(sheet)
        XCTAssertTrue(sheet?.prefersGrabberVisible == true)
        XCTAssertEqual(sheet?.preferredCornerRadius, 24)
        XCTAssertEqual(sheet?.detents.count, detents.count)
    }

    func testCloseButtonHas44PointHitAreaAnd30PointCircle() {
        let button = HYUSheetCloseButton()
        XCTAssertEqual(button.intrinsicContentSize, CGSize(width: 44, height: 44))

        button.frame = CGRect(origin: .zero, size: button.intrinsicContentSize)
        button.layoutIfNeeded()

        XCTAssertEqual(button.circleView.bounds.size, CGSize(width: 30, height: 30))
        XCTAssertEqual(button.circleView.layer.cornerRadius, 15)
    }

    func testSetTitleSetsLabelText() {
        let label = HYUSheet.makeTitleLabel()

        HYUSheet.setTitle("Sheet title", on: label)

        XCTAssertEqual(label.text, "Sheet title")
    }
}
