//
//  InquiryComponentTests.swift
//  hyuabotTests
//

import XCTest
@testable import hyuabot

@MainActor
final class InquiryComponentTests: XCTestCase {
    private func fit(_ view: UIView, width: CGFloat = 358) -> CGRect {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 1000))
        host.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.setNeedsLayout()
        host.layoutIfNeeded()
        return view.frame
    }

    private func hostFit(_ view: UIView) -> CGRect {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 358, height: 1000))
        host.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: host.topAnchor),
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor)
        ])
        host.setNeedsLayout()
        host.layoutIfNeeded()
        host.setNeedsLayout()
        host.layoutIfNeeded()
        return view.frame
    }

    func testBubblePathUsesSmallCornerOnLeadingTailSide() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 42)
        let leading = InquiryBubblePath.path(in: rect, side: .leading, radius: 18)
        let trailing = InquiryBubblePath.path(in: rect, side: .trailing, radius: 18)
        XCTAssertEqual(leading.bounds.minX, rect.minX, accuracy: 0.5)
        XCTAssertEqual(leading.bounds.maxX, rect.maxX, accuracy: 0.5)
        XCTAssertEqual(leading.bounds.minY, rect.minY, accuracy: 0.5)
        XCTAssertEqual(leading.bounds.maxY, rect.maxY, accuracy: 0.5)
        XCTAssertTrue(leading.contains(CGPoint(x: 2, y: 40)))
        XCTAssertFalse(trailing.contains(CGPoint(x: 2, y: 40)))
    }

    func testActionRowFitsButtonsAtFortyFourPoints() {
        let row = InquiryUI.actionRow([
            InquiryUI.actionButton(title: "Details", systemImage: "info.circle", filled: false),
            InquiryUI.actionButton(title: "Refresh", systemImage: "arrow.clockwise", filled: true)
        ])
        let frame = fit(row)
        XCTAssertEqual(frame.height, 44, accuracy: 0.5)
        XCTAssertEqual(row.arrangedSubviews[0].frame.height, 44, accuracy: 0.5)
        XCTAssertEqual(row.arrangedSubviews[1].frame.height, 44, accuracy: 0.5)
    }

    func testTextBubbleWrapsWithinMaximumWidth() {
        let bubble = InquiryTextBubbleView(
            side: .trailing,
            fillColor: SettingsStyle.Color.card,
            textColor: SettingsStyle.Color.text,
            maxWidth: 270
        )
        bubble.setText(String(repeating: "Inquiry response ", count: 12))
        let frame = hostFit(bubble)
        XCTAssertLessThanOrEqual(frame.width, 270.5)
        XCTAssertGreaterThanOrEqual(frame.width, 260)
        XCTAssertGreaterThan(frame.height, 42)
        XCTAssertLessThanOrEqual(bubble.label.frame.width, 242.5)
    }

    func testAnswerCardUsesPreferredWidthAndWrapsDetail() {
        let card = InquiryAnswerCardView(title: "Answer", detail: String(repeating: "A detailed answer with more information. ", count: 8))
        let frame = hostFit(card)
        XCTAssertLessThanOrEqual(frame.width, 310.5)
        XCTAssertGreaterThanOrEqual(frame.width, 300)
        XCTAssertGreaterThan(frame.height, 16 + 22 + 4 + 21 + 16 - 1)
    }
}
