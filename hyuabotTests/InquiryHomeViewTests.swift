//
//  InquiryHomeViewTests.swift
//  hyuabotTests
//

import UIKit
import XCTest
@testable import hyuabot

@MainActor
final class InquiryHomeViewTests: XCTestCase {
    private func find(_ id: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == id { return view }
        for child in view.subviews {
            if let match = find(id, in: child) { return match }
        }
        return nil
    }

    func testQuickReplyRowsSelectAndMeetMinimumHeight() {
        let list = InquiryQuickReplyListView()
        var selected: InquiryQuickReply?
        list.onSelect = { selected = $0 }
        let lost = find("inquiry.quick.lostItem", in: list) as? UIControl
        XCTAssertNotNil(find("inquiry.quick.timetable", in: list))
        XCTAssertGreaterThanOrEqual(lost?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height ?? 0, 64)
        lost?.sendActions(for: .touchUpInside)
        XCTAssertEqual(selected, .lostItem)
    }

    func testErrorCardRetryAction() {
        let card = InquiryErrorCardView()
        var retried = false
        card.onRetry = { retried = true }
        (find("inquiry.retry", in: card) as? UIButton)?.sendActions(for: .touchUpInside)
        XCTAssertTrue(retried)
    }

    func testConversationQuickReplyRowsHugContent() {
        let conversation = InquiryConversationView()
        conversation.frame = CGRect(x: 0, y: 0, width: 402, height: 700)
        conversation.render(InquiryConversationContent(
            showsWelcome: true,
            showsQuickList: true,
            chatRows: [],
            answer: nil,
            showsError: false,
            showsChips: true
        ))
        conversation.layoutIfNeeded()

        let lostItem = find("inquiry.quick.lostItem", in: conversation)
        let timetable = find("inquiry.quick.timetable", in: conversation)
        let combinedHeight = (lostItem?.bounds.height ?? 0) + (timetable?.bounds.height ?? 0)
        XCTAssertGreaterThanOrEqual(combinedHeight, 120)
        XCTAssertLessThan(combinedHeight, 200)
    }

    func testConversationContentHeightShrinksWhenQuickListIsHidden() {
        let conversation = InquiryConversationView()
        conversation.frame = CGRect(x: 0, y: 0, width: 402, height: 700)
        conversation.render(InquiryConversationContent(
            showsWelcome: true,
            showsQuickList: true,
            chatRows: [],
            answer: nil,
            showsError: false,
            showsChips: true
        ))
        conversation.layoutIfNeeded()

        conversation.render(InquiryConversationContent(
            showsWelcome: true,
            showsQuickList: false,
            chatRows: [],
            answer: .lostItem,
            showsError: false,
            showsChips: true
        ))
        conversation.layoutIfNeeded()

        let scrollView = find("inquiry.scroll", in: conversation) as? UIScrollView
        let contentView = scrollView?.subviews.first
        XCTAssertNotNil(scrollView)
        XCTAssertLessThanOrEqual(scrollView?.contentSize.height ?? .greatestFiniteMagnitude, 700)
        XCTAssertLessThanOrEqual(contentView?.bounds.height ?? .greatestFiniteMagnitude, 700)
        XCTAssertFalse(contentView?.hasAmbiguousLayout ?? true)
    }

    func testComposerAppliesHorizontalMargins() {
        let composer = InquiryComposerView()
        composer.frame = CGRect(x: 0, y: 0, width: 402, height: 120)
        composer.layoutIfNeeded()

        let inputField = find("inquiry.input", in: composer)
        let sendButton = find("inquiry.send_button", in: composer)
        XCTAssertEqual(inputField?.frame.minX ?? -1, 16, accuracy: 1)
        XCTAssertEqual(sendButton?.frame.maxX ?? -1, 390, accuracy: 1)
    }

    func testComposerSendingAndChipVisibility() {
        let composer = InquiryComposerView()
        var sent: String?
        composer.onSend = { sent = $0 }
        let sendButton = find("inquiry.send_button", in: composer) as? UIButton
        XCTAssertEqual(sendButton?.isEnabled, false)
        XCTAssertEqual(sendButton?.layer.cornerRadius, 22)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let disabledBackground = SettingsStyle.Color.switchOff.resolvedColor(with: traits)
            let disabledForeground = SettingsStyle.Color.card.resolvedColor(with: traits)
            XCTAssertEqual(sendButton?.backgroundColor?.resolvedColor(with: traits), disabledBackground)
            XCTAssertEqual(sendButton?.tintColor.resolvedColor(with: traits), disabledForeground)
        }
        let field = find("inquiry.input", in: composer) as? UITextField
        field?.text = "hi"
        field?.sendActions(for: .editingChanged)
        XCTAssertEqual(sendButton?.isEnabled, true)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let enabledBackground = SettingsStyle.Color.accent.resolvedColor(with: traits)
            let enabledForeground = SettingsStyle.Color.onAccent.resolvedColor(with: traits)
            XCTAssertEqual(sendButton?.backgroundColor?.resolvedColor(with: traits), enabledBackground)
            XCTAssertEqual(sendButton?.tintColor.resolvedColor(with: traits), enabledForeground)
        }
        sendButton?.sendActions(for: .touchUpInside)
        XCTAssertEqual(sent, "hi")

        composer.setChips(visible: false, selected: nil)
        let lostChip = find("inquiry.chip.lostItem", in: composer)
        var ancestor = lostChip?.superview
        var hiddenAncestor = false
        while let current = ancestor {
            hiddenAncestor = hiddenAncestor || current.isHidden
            ancestor = current.superview
        }
        XCTAssertTrue(hiddenAncestor)
        composer.setChips(visible: true, selected: .timetable)
        let timetable = find("inquiry.chip.timetable", in: composer) as? UIButton
        XCTAssertTrue(timetable?.accessibilityTraits.contains(.selected) == true)
        XCTAssertEqual(timetable?.configuration?.cornerStyle, .capsule)
    }
}
