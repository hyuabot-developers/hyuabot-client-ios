//
//  InquiryConversationViewTests.swift
//  hyuabotTests
//

import UIKit
import XCTest
@testable import hyuabot

@MainActor
final class InquiryConversationViewTests: XCTestCase {
    func testWelcomeAndQuickListRender() {
        let view = makeView()
        view.render(content(showsWelcome: true, showsQuickList: true))
        XCTAssertNotNil(find("inquiry.quick.lostItem", in: view))
        XCTAssertNil(find("inquiry.retry", in: view))
    }

    func testTimetableAnswerForwardsOpenAction() {
        let view = makeView()
        var opened = false
        view.onOpenTimetable = { opened = true }
        view.render(content(answer: .timetable, showsChips: true))
        XCTAssertNotNil(find("inquiry.timetable.open", in: view))
        XCTAssertNotNil(find("inquiry.answer.question", in: view))
        (find("inquiry.timetable.open", in: view) as? UIButton)?.sendActions(for: .touchUpInside)
        XCTAssertTrue(opened)
    }

    func testErrorForwardsRetryAction() {
        let view = makeView()
        var retried = false
        view.onRetry = { retried = true }
        view.render(content(showsError: true))
        (find("inquiry.retry", in: view) as? UIButton)?.sendActions(for: .touchUpInside)
        XCTAssertTrue(retried)
    }

    func testChatRowsRender() {
        let view = makeView()
        view.render(content(chatRows: [
            InquiryChatRow(kind: .date("Today"), topSpacing: 0),
            InquiryChatRow(kind: .user(body: "Hi", time: "10:00", isRead: true), topSpacing: 16),
            InquiryChatRow(kind: .admin(body: "Hello", time: "10:01", showsSenderLabel: true), topSpacing: 16)
        ]))
        XCTAssertNotNil(find("inquiry.message.user", in: view))
        XCTAssertNotNil(find("inquiry.message.admin", in: view))
    }

    func testRenderingTwiceDoesNotDuplicateChatRows() {
        let view = makeView()
        let content = content(chatRows: [InquiryChatRow(kind: .user(body: "Hi", time: "10:00", isRead: false), topSpacing: 0)])
        view.render(content)
        view.render(content)
        XCTAssertEqual(findAll("inquiry.message.user", in: view).count, 1)
    }

    func testHomeContentHugsBottomWithoutStretchingQuickReplies() {
        let view = makeView(width: 402)
        view.render(content(showsWelcome: true, showsQuickList: true))
        view.layoutIfNeeded()
        let rows = [find("inquiry.quick.lostItem", in: view), find("inquiry.quick.timetable", in: view)].compactMap { $0 }
        XCTAssertEqual(rows.reduce(0) { $0 + $1.frame.height }, 128, accuracy: 4)
        let conversationStack = findConversationStack(in: view)
        let lowestView = conversationStack?.arrangedSubviews.last
        guard let lowestView else { return XCTFail("Expected a lowest arranged view") }
        let bottom = lowestView.convert(lowestView.bounds, to: view).maxY
        XCTAssertLessThanOrEqual(abs(view.bounds.maxY - bottom - 16), 1)
    }

    func testLongConversationExceedsFrameHeight() {
        let view = makeView(width: 402)
        let rows = (0..<30).map {
            InquiryChatRow(kind: .user(body: "A long message for scrolling. \($0)", time: "10:00", isRead: true), topSpacing: 16)
        }
        view.render(content(chatRows: rows))
        view.layoutIfNeeded()
        XCTAssertGreaterThan(findScrollView(in: view)?.contentSize.height ?? 0, view.bounds.height)
    }

    func testTimetableCalloutIconAlignsWithFirstTextLine() {
        let view = makeView(width: 330)
        view.render(content(answer: .timetable))
        view.layoutIfNeeded()
        guard let icon = find("inquiry.timetable.callout.icon", in: view),
              let label = find("inquiry.timetable.callout.label", in: view) as? UILabel else {
            return XCTFail("Expected the callout icon and label")
        }
        let iconMidY = icon.convert(icon.bounds, to: view).midY
        let labelFrame = label.convert(label.bounds, to: view)
        let firstLineMidY = labelFrame.minY + 21 / 2 // callout line height is 21pt
        XCTAssertLessThanOrEqual(abs(iconMidY - firstLineMidY), 1)
    }

    private func makeView(width: CGFloat = 390) -> InquiryConversationView {
        let view = InquiryConversationView()
        view.frame = CGRect(x: 0, y: 0, width: width, height: 700)
        view.layoutIfNeeded()
        return view
    }

    private func findScrollView(in view: UIView) -> UIScrollView? {
        if let scrollView = view as? UIScrollView { return scrollView }
        for child in view.subviews {
            if let match = findScrollView(in: child) { return match }
        }
        return nil
    }

    private func findConversationStack(in view: UIView) -> UIStackView? {
        if let stack = view as? UIStackView,
           stack.arrangedSubviews.contains(where: { $0 is InquiryWelcomeView }) { return stack }
        for child in view.subviews {
            if let match = findConversationStack(in: child) { return match }
        }
        return nil
    }

    private func content(
        showsWelcome: Bool = false,
        showsQuickList: Bool = false,
        chatRows: [InquiryChatRow] = [],
        answer: InquiryQuickReply? = nil,
        showsError: Bool = false,
        showsChips: Bool = false
    ) -> InquiryConversationContent {
        InquiryConversationContent(
            showsWelcome: showsWelcome, showsQuickList: showsQuickList, chatRows: chatRows,
            answer: answer, showsError: showsError, showsChips: showsChips
        )
    }

    private func find(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        for child in view.subviews {
            if let match = find(identifier, in: child) { return match }
        }
        return nil
    }

    private func findAll(_ identifier: String, in view: UIView) -> [UIView] {
        var matches = view.accessibilityIdentifier == identifier ? [view] : []
        for child in view.subviews { matches += findAll(identifier, in: child) }
        return matches
    }
}
