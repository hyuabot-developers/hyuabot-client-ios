//
//  BusRealtimeLogRequestTests.swift
//  hyuabot
//

@_spi(Unsafe)
import Api
@_spi(Unsafe)
import ApolloAPI
@testable import hyuabot
import XCTest

final class BusRealtimeLogRequestTests: XCTestCase {
    private func input() -> BusRouteStopInput {
        BusRouteStopInput(route: 216_000_061, stop: 216_000_379, limit: .some(3), dates: .some([]))
    }

    func testLogAfterFormatsHoursAndMinutes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        let evening = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 14, hour: 20, minute: 40, second: 59)))
        let midnight = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 15, hour: 0, minute: 5)))
        XCTAssertEqual(BusRealtimeLogRequest.logAfter(now: evening, calendar: calendar), "20:40")
        XCTAssertEqual(BusRealtimeLogRequest.logAfter(now: midnight, calendar: calendar), "00:05")
    }

    @MainActor
    func testWindowInputSetsCapAndTimeAndPreservesOtherFields() {
        let changed = BusRealtimeLogRequest.inputs([input()], logAfter: "20:40")[0]
        XCTAssertEqual(changed.limit, .some(3))
        XCTAssertEqual(changed.logLimit, .some(15))
        XCTAssertEqual(changed.logAfter, .some("20:40"))
        XCTAssertEqual(changed.route, 216_000_061)
        XCTAssertEqual(changed.stop, 216_000_379)
    }

    @MainActor
    func testLegacyInputRemovesWindowAndKeepsArrivalLimit() {
        let changed = BusRealtimeLogRequest.inputs([input()], logAfter: nil)[0]
        XCTAssertEqual(changed.limit, .some(3))
        XCTAssertEqual(changed.logLimit, .none)
        XCTAssertEqual(changed.logAfter, .none)
    }

    @MainActor
    func testInputsWithoutLogWindowRestoreLegacyInput() {
        var withWindow = input()
        withWindow.logLimit = .some(15)
        withWindow.logAfter = .some("20:40")
        XCTAssertEqual(
            BusRealtimeLogRequest.inputs([withWindow], logAfter: nil),
            BusRealtimeLogRequest.inputs([input()], logAfter: nil)
        )
    }

    func testLogLimitStaysSmall() {
        XCTAssertLessThanOrEqual(BusRealtimeLogRequest.logLimit, 15)
        XCTAssertGreaterThanOrEqual(BusRealtimeLogRequest.logLimit, 10)
    }

    func testRejectsOnlyUnknownWindowFieldsOnBusRouteStopInput() {
        let rejection = [
            "The variables input contains a field name 'logLimit' that is not",
            "defined for input object type 'BusRouteStopInput'"
        ].joined(separator: " ")
        XCTAssertTrue(BusRealtimeLogRequest.rejectsLogWindow([rejection]))
        XCTAssertTrue(BusRealtimeLogRequest.rejectsLogWindow([rejection.replacingOccurrences(of: "'logLimit'", with: "'logAfter'")]))
        XCTAssertTrue(BusRealtimeLogRequest.rejectsLogWindow(["other", rejection]))
        XCTAssertFalse(BusRealtimeLogRequest.rejectsLogWindow([]))
        XCTAssertFalse(BusRealtimeLogRequest.rejectsLogWindow(["Unknown field 'logAfter' for OtherInput"]))
        XCTAssertFalse(BusRealtimeLogRequest.rejectsLogWindow([
            "The request timed out.",
            "Received a 500 error.",
            "INTERNAL_ERROR for 3f2a"
        ]))
    }

    func testExtractsGraphQLErrorMessagesFromResponseBody() throws {
        let rejection = [
            "The variables input contains a field name 'logLimit' that is not",
            "defined for input object type 'BusRouteStopInput'"
        ].joined(separator: " ")
        let body = try JSONSerialization.data(withJSONObject: ["errors": [[
            "message": rejection,
            "extensions": ["classification": "ValidationError", "errorType": "BAD_REQUEST"]
        ]]])
        XCTAssertEqual(BusRealtimeLogRequest.graphQLErrorMessages(inResponseBody: body), [rejection])
        XCTAssertTrue(BusRealtimeLogRequest.graphQLErrorMessages(inResponseBody: Data("not json".utf8)).isEmpty)
        XCTAssertTrue(BusRealtimeLogRequest.graphQLErrorMessages(inResponseBody: Data(#"{"data":null}"#.utf8)).isEmpty)
    }

    func testGraphQLErrorMessagesIgnoresNonHTTPErrors() {
        XCTAssertTrue(BusRealtimeLogRequest.graphQLErrorMessages(in: URLError(.timedOut)).isEmpty)
    }

    @MainActor
    func testSuccessfulWindowedRequestUsesWindowOnce() async {
        var requests: [[BusRouteStopInput]] = []
        let result = await BusRealtimeLogRequest.fetch(input: [input()], logAfter: "20:40", supportsLogWindow: true) { request in
            requests.append(request)
            return .init(data: "rendered", errorMessages: [])
        }
        XCTAssertEqual(result.data, "rendered")
        XCTAssertTrue(result.supportsLogWindow)
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0][0].logLimit, .some(15))
    }

    @MainActor
    func testExplicitRejectionRetriesLegacyAndDisablesWindow() async {
        var requests: [[BusRouteStopInput]] = []
        let result = await BusRealtimeLogRequest.fetch(input: [input()], logAfter: "20:40", supportsLogWindow: true) { request in
            requests.append(request)
            if request[0].logLimit == .some(15) {
                return .init(data: nil as String?, errorMessages: ["field 'logLimit' is not defined for BusRouteStopInput"])
            }
            return .init(data: "legacy", errorMessages: [])
        }
        XCTAssertEqual(result.data, "legacy")
        XCTAssertFalse(result.supportsLogWindow)
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[1][0].logLimit, .none)
    }

    @MainActor
    func testTransientFailureRetriesLegacyButKeepsWindowEnabled() async {
        var requests: [[BusRouteStopInput]] = []
        let result = await BusRealtimeLogRequest.fetch(input: [input()], logAfter: "20:40", supportsLogWindow: true) { request in
            requests.append(request)
            return request[0].logLimit == .some(15)
                ? .init(data: nil as String?, errorMessages: ["HTTP 503"])
                : .init(data: "legacy", errorMessages: [])
        }
        XCTAssertEqual(result.data, "legacy")
        XCTAssertTrue(result.supportsLogWindow)
        XCTAssertEqual(requests.count, 2)
    }

    @MainActor
    func testDisabledWindowUsesLegacyInputOnly() async {
        var requests: [[BusRouteStopInput]] = []
        let result = await BusRealtimeLogRequest.fetch(input: [input()], logAfter: "20:40", supportsLogWindow: false) { request in
            requests.append(request)
            return .init(data: "legacy", errorMessages: [])
        }
        XCTAssertEqual(result.data, "legacy")
        XCTAssertFalse(result.supportsLogWindow)
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0][0].logAfter, .none)
    }

    @MainActor
    func testBothFailuresReturnNoDataAndRetainCapabilityUnlessExplicitlyRejected() async {
        let timeout = await BusRealtimeLogRequest.fetch(input: [input()], logAfter: "20:40", supportsLogWindow: true) { _ in
            .init(data: nil as String?, errorMessages: ["timeout"])
        }
        XCTAssertNil(timeout.data)
        XCTAssertTrue(timeout.supportsLogWindow)
        let rejected = await BusRealtimeLogRequest.fetch(input: [input()], logAfter: "20:40", supportsLogWindow: true) { request in
            let message = request[0].logLimit == .some(15) ? "'logLimit' BusRouteStopInput" : "timeout"
            return .init(data: nil as String?, errorMessages: [message])
        }
        XCTAssertNil(rejected.data)
        XCTAssertFalse(rejected.supportsLogWindow)
    }
}

final class BusDisplayLogicRealtimeLogsTests: XCTestCase {
    private func date(_ day: Int, _ hour: Int, _ minute: Int) throws -> Foundation.Date {
        let components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
        return try XCTUnwrap(Calendar.current.date(from: components))
    }

    func testRealtimeTabLogsKeepEveningLogsBeforePostMidnightLastBus() throws {
        let now = try date(14, 20, 40)
        let lastLive = try date(14, 20, 50)
        let eveningFirst = try [date(14, 21, 27), date(14, 22, 7), date(14, 22, 47), date(14, 23, 25), date(15, 0, 0)]
        let shuffled = [eveningFirst[3], eveningFirst[0], eveningFirst[4], eveningFirst[2], eveningFirst[1]]
        func merge(_ candidates: [Foundation.Date]) -> [Foundation.Date] {
            BusLogMerging.realtimeTabLogs(
                candidates: candidates, serviceDate: { $0 }, dispatchMinutes: 30,
                lastLiveArrival: lastLive, now: now
            )
        }
        XCTAssertEqual(merge(eveningFirst), eveningFirst)
        XCTAssertEqual(merge(shuffled), eveningFirst)
    }

    func testRealtimeTabLogsSkipLogTooCloseToLastLiveArrival() throws {
        let now = try date(14, 21, 10)
        let lastLive = try date(14, 21, 20)
        let candidates = try [date(14, 21, 27), date(14, 22, 7), date(14, 22, 47), date(14, 23, 25), date(15, 0, 0)]
        let expected = try [date(14, 22, 7), date(14, 22, 47), date(14, 23, 25), date(15, 0, 0)]
        XCTAssertEqual(
            BusLogMerging.realtimeTabLogs(
                candidates: candidates, serviceDate: { $0 }, dispatchMinutes: 30,
                lastLiveArrival: lastLive, now: now
            ),
            expected
        )
    }
}
