//
//  InquiryPushTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class InquiryPushTests: XCTestCase {
    func testIsInquiryPayload() {
        XCTAssertTrue(InquiryPush.isInquiryPayload([
            "type": "inquiry",
            "threadId": "00000000-0000-0000-0000-000000000001"
        ]))
        XCTAssertFalse(InquiryPush.isInquiryPayload(["id": "reading_room_1", "available": "3"]))
        XCTAssertFalse(InquiryPush.isInquiryPayload([:]))
        XCTAssertFalse(InquiryPush.isInquiryPayload(["type": "other"]))
        XCTAssertFalse(InquiryPush.isInquiryPayload(["type": 1]))
    }

    func testConstantsAndDeepLink() throws {
        XCTAssertEqual(InquiryPush.providerFCM, "FCM")
        XCTAssertEqual(InquiryPush.platformIOS, "IOS")
        let url = try XCTUnwrap(URL(string: InquiryPush.chatDeepLink))
        XCTAssertEqual(url.host, "inquiry")
        XCTAssertEqual(url.scheme, "hyuabot")
    }
}
