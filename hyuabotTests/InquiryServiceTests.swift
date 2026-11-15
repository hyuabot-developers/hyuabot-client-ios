//
//  InquiryServiceTests.swift
//  hyuabot
//

@testable import hyuabot
import XCTest

final class InquiryServiceTests: XCTestCase {
    func testStreamPathUsesLongTimeout() {
        XCTAssertEqual(InquiryService.requestTimeout(forPath: InquiryService.streamPath), 600)
        XCTAssertGreaterThanOrEqual(InquiryService.requestTimeout(forPath: InquiryService.streamPath), 300)
    }

    func testOtherPathsUseDefaultTimeout() {
        XCTAssertEqual(InquiryService.requestTimeout(forPath: "/api/v1/inquiry/threads"), 10)
        XCTAssertEqual(InquiryService.requestTimeout(forPath: "/api/v1/inquiry/messages"), 10)
        XCTAssertEqual(InquiryService.requestTimeout(forPath: ""), 10)
        XCTAssertEqual(InquiryService.defaultRequestTimeout, 10)
    }
}
