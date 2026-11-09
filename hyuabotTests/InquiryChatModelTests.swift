//
//  InquiryChatModelTests.swift
//  hyuabotTests
//

import XCTest
@testable import hyuabot

final class InquiryChatModelTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .gmt
        return value
    }

    private var locale: Locale { Locale(identifier: "ko_KR") }
    private var now: Date {
        InquiryChatModel.messageDate(from: "2026-11-09T10:00:00+09:00") ?? Date(timeIntervalSince1970: 0)
    }

    func testRowsGroupDaysAndFormatSenders() {
        let messages = [
            message(1, "USER", "u", "2026-11-07T14:02:00+09:00[Asia/Seoul]", readAt: "read"),
            message(2, "ADMIN", "a", "2026-11-07T14:20:00+09:00"),
            message(3, "SYSTEM", "s", "2026-11-09T09:00:00+09:00"),
            message(4, "USER", "u", "2026-11-09T09:12:00+09:00"),
            message(5, "ADMIN", "a", "2026-11-09T09:30:00+09:00"),
            message(6, "ADMIN", "a", "2026-11-09T09:31:00+09:00")
        ]
        let rows = InquiryChatModel.rows(from: messages, now: now, calendar: calendar, locale: locale)
        XCTAssertEqual(rows.map(\.kind), [
            .date("11월 7일 (토)"), .user(body: "u", time: "오후 2:02", isRead: true),
            .admin(body: "a", time: "오후 2:20", showsSenderLabel: true), .date("오늘"), .system("s"),
            .user(body: "u", time: "오전 9:12", isRead: false), .admin(body: "a", time: "오전 9:30", showsSenderLabel: true),
            .admin(body: "a", time: "오전 9:31", showsSenderLabel: false)
        ])
        XCTAssertEqual(rows.map(\.topSpacing), [0, 16, 16, 24, 16, 16, 16, 8])
    }

    func testConsecutiveUsersUseCompactSpacing() {
        let rows = InquiryChatModel.rows(from: [
            message(1, "USER", "one", "2026-11-09T09:00:00+09:00"),
            message(2, "USER", "two", "2026-11-09T09:01:00+09:00")
        ], now: now, calendar: calendar, locale: locale)
        XCTAssertEqual(rows.map(\.topSpacing), [0, 16, 8])
    }

    func testContentVisibility() {
        let empty = InquiryChatModel.content(messages: [], loadFailed: false, selected: nil)
        XCTAssertTrue(empty.showsWelcome)
        XCTAssertTrue(empty.showsQuickList)
        XCTAssertFalse(empty.showsChips)

        let failed = InquiryChatModel.content(messages: [], loadFailed: true, selected: nil)
        XCTAssertTrue(failed.showsWelcome)
        XCTAssertTrue(failed.showsQuickList)
        XCTAssertTrue(failed.showsError)

        let selected = InquiryChatModel.content(messages: [], loadFailed: false, selected: .lostItem)
        XCTAssertFalse(selected.showsQuickList)
        XCTAssertTrue(selected.showsChips)
        XCTAssertEqual(selected.answer, .lostItem)

        let messages = [message(1, "USER", "hi", "2026-11-09T09:00:00+09:00")]
        let nonEmpty = InquiryChatModel.content(messages: messages, loadFailed: false, selected: nil)
        XCTAssertFalse(nonEmpty.showsWelcome)
        XCTAssertFalse(nonEmpty.showsQuickList)
        XCTAssertTrue(nonEmpty.showsChips)
    }

    func testQuickReplies() {
        XCTAssertEqual(InquiryQuickReply.allCases, [.lostItem, .timetable])
        XCTAssertEqual(InquiryQuickReply.lostItem.iconName, "bag")
        XCTAssertEqual(InquiryQuickReply.timetable.iconName, "clock")
    }

    private func message(_ id: Int, _ sender: String, _ body: String, _ createdAt: String, readAt: String? = nil) -> InquiryMessageDTO {
        InquiryMessageDTO(id: id, senderType: sender, body: body, readAt: readAt, createdAt: createdAt)
    }
}
