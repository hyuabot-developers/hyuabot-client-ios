//
//  ShuttleInitialStopResolverTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class ShuttleInitialStopResolverTests: XCTestCase {
    func testReturnsHighestPriorityMatchingRule() {
        let rules = [
            rule(sequence: 2, stopName: "station", priority: 10),
            rule(sequence: 1, stopName: "dormitory_o", priority: 20)
        ]

        XCTAssertEqual(
            ShuttleInitialStopResolver.resolve(latitude: 37.5, longitude: 126.5, rules: rules),
            "dormitory_o"
        )
    }

    func testUsesSequenceAsTieBreaker() {
        let rules = [
            rule(sequence: 2, stopName: "station", priority: 10),
            rule(sequence: 1, stopName: "terminal", priority: 10)
        ]

        XCTAssertEqual(
            ShuttleInitialStopResolver.resolve(latitude: 37.5, longitude: 126.5, rules: rules),
            "terminal"
        )
    }

    func testTreatsPolygonBoundaryAsInside() {
        XCTAssertTrue(
            ShuttleInitialStopResolver.contains(
                ShuttleGeoCoordinate(latitude: 37.0, longitude: 126.5),
                polygon: square()
            )
        )
    }

    func testReturnsNilOutsideRulesAndForInvalidInput() {
        XCTAssertNil(
            ShuttleInitialStopResolver.resolve(
                latitude: 38.0,
                longitude: 128.0,
                rules: [rule(sequence: 1, stopName: "station", priority: 10)]
            )
        )
        XCTAssertNil(
            ShuttleInitialStopResolver.resolve(
                latitude: .nan,
                longitude: 126.5,
                rules: [rule(sequence: 1, stopName: "station", priority: 10)]
            )
        )
        XCTAssertNil(
            ShuttleInitialStopResolver.resolve(
                latitude: 37.5,
                longitude: 126.5,
                rules: [
                    ShuttleInitialStopRuleCandidate(
                        sequence: 1,
                        stopName: "station",
                        priority: 10,
                        polygon: Array(square().prefix(2))
                    )
                ]
            )
        )
    }

    private func rule(
        sequence: Int,
        stopName: String,
        priority: Int
    ) -> ShuttleInitialStopRuleCandidate {
        ShuttleInitialStopRuleCandidate(
            sequence: sequence,
            stopName: stopName,
            priority: priority,
            polygon: square()
        )
    }

    private func square() -> [ShuttleGeoCoordinate] {
        [
            ShuttleGeoCoordinate(latitude: 37.0, longitude: 126.0),
            ShuttleGeoCoordinate(latitude: 37.0, longitude: 127.0),
            ShuttleGeoCoordinate(latitude: 38.0, longitude: 127.0),
            ShuttleGeoCoordinate(latitude: 38.0, longitude: 126.0)
        ]
    }
}
