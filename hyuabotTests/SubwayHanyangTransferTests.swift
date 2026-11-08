//
//  SubwayHanyangTransferTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class SubwayHanyangTransferTests: XCTestCase {
    private struct FakeEntry {
        let minutes: Int
        let terminal: String
        let realtime: Bool
    }

    func testDirectTrain() {
        let routes = makeRoutes(arrivingAtOido: [FakeEntry(minutes: 5, terminal: "K209", realtime: true)])

        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes[0].take.terminal, "K209")
        XCTAssertNil(routes[0].transfer)
        XCTAssertNil(routes[0].waitMinutes)
    }

    func testHanyangTerminalIsDirectAndLaterTerminalsAreDropped() {
        let candidates = [
            FakeEntry(minutes: 5, terminal: "K251", realtime: true),
            FakeEntry(minutes: 6, terminal: "K255", realtime: true),
            FakeEntry(minutes: 7, terminal: "K4xx", realtime: true)
        ]

        XCTAssertEqual(makeRoutes(arrivingAtOido: candidates).map(\.take.terminal), ["K251"])
    }

    func testOidoCandidateUsesFirstDepartureWithTransferBuffer() {
        let candidate = FakeEntry(minutes: 6, terminal: "K258", realtime: true)
        let departures = [4, 8, 20].map { FakeEntry(minutes: $0, terminal: "K409", realtime: true) }

        let routes = makeRoutes(arrivingAtOido: [candidate], line4Departures: departures)

        XCTAssertEqual(routes.count, 1)
        XCTAssertEqual(routes[0].transfer?.minutes, 8)
        XCTAssertEqual(routes[0].waitMinutes, 2)
    }

    func testOidoCandidateWithoutEligibleDepartureIsDropped() {
        let candidate = FakeEntry(minutes: 6, terminal: "K258", realtime: true)
        let departures = [FakeEntry(minutes: 7, terminal: "K409", realtime: true)]

        XCTAssertTrue(makeRoutes(arrivingAtOido: [candidate], line4Departures: departures).isEmpty)
    }

    func testNonRealtimeCandidatesAreDropped() {
        let candidate = FakeEntry(minutes: 5, terminal: "K251", realtime: false)

        XCTAssertTrue(makeRoutes(arrivingAtOido: [candidate]).isEmpty)
    }

    func testRoutesAreSortedByTakeMinutes() {
        let candidates = [
            FakeEntry(minutes: 10, terminal: "K251", realtime: true),
            FakeEntry(minutes: 5, terminal: "K251", realtime: true),
            FakeEntry(minutes: 8, terminal: "K258", realtime: true)
        ]
        let departures = [FakeEntry(minutes: 10, terminal: "K409", realtime: true)]

        XCTAssertEqual(makeRoutes(arrivingAtOido: candidates, line4Departures: departures).map(\.take.minutes), [5, 8, 10])
    }

    func testEmptyInputsProduceNoRoutes() {
        XCTAssertTrue(makeRoutes(arrivingAtOido: []).isEmpty)
    }

    private func makeRoutes(
        arrivingAtOido: [FakeEntry],
        line4Departures: [FakeEntry] = []
    ) -> [SubwayHanyangTransfer.Route<FakeEntry>] {
        SubwayHanyangTransfer.routes(
            arrivingAtOido: arrivingAtOido,
            line4Departures: line4Departures,
            minutes: { $0.minutes },
            terminalID: { $0.terminal },
            isRealtime: { $0.realtime }
        )
    }
}
