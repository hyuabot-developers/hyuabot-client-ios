//
//  HYUSheetViewTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

@MainActor
final class HYUSheetViewTests: XCTestCase {
    func testTitleUsesTwentyPointBold() {
        let view = HYUSheetView(title: "Title", titleIdentifier: "test.sheet.title")
        let label = findLabel(in: view, identifier: "test.sheet.title")
        XCTAssertEqual(label?.font.pointSize, 20)
    }

    func testContentHeightIncludesHeader() {
        let view = HYUSheetView(title: "Title", titleIdentifier: "test.sheet.title")
        view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        let fixedHeight = UIView()
        fixedHeight.heightAnchor.constraint(equalToConstant: 100).isActive = true
        view.contentStack.addArrangedSubview(fixedHeight)
        view.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(view.contentHeight, 52 + 6 + 4 + 100 + 34 - 0.5)
    }

    func testCardIsRounded() {
        XCTAssertEqual(HYUSheetView.card().layer.cornerRadius, 16)
    }

    func testActionButtonHeight() {
        let button = HYUSheetView.actionButton(title: "Action", systemImage: "arrow.right", identifier: "test.action")
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        container.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor)
        ])
        container.layoutIfNeeded()
        XCTAssertEqual(button.bounds.height, 48, accuracy: 0.5)
    }

    private func findLabel(in view: UIView, identifier: String) -> UILabel? {
        if let label = view as? UILabel, label.accessibilityIdentifier == identifier {
            return label
        }
        for child in view.subviews {
            if let label = findLabel(in: child, identifier: identifier) {
                return label
            }
        }
        return nil
    }
}
