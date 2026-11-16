//
//  BusLocationGroupTests.swift
//  hyuabot
//

import CoreLocation
import XCTest
@testable import hyuabot

final class BusLocationGroupTests: XCTestCase {
    func testEveryAnchorResolvesToItsOwnGroup() {
        for group in BusLocationGroup.allCases {
            for anchor in group.anchors {
                XCTAssertEqual(BusLocationGroup.resolve(latitude: anchor.latitude, longitude: anchor.longitude), group)
            }
        }
    }

    func testAllGroupsHaveAnchors() {
        XCTAssertEqual(BusLocationGroup.allCases.count, 14)
        for group in BusLocationGroup.allCases {
            XCTAssertFalse(group.anchors.isEmpty)
        }
    }

    func testFarAwayPositionResolvesToNil() {
        XCTAssertNil(BusLocationGroup.resolve(latitude: 37.5665, longitude: 126.9780))
    }

    func testRadiusBoundary() {
        XCTAssertEqual(BusLocationGroup.resolve(latitude: 37.43955, longitude: 126.8843167), .gwangmyeong)
        XCTAssertNil(BusLocationGroup.resolve(latitude: 37.44455, longitude: 126.8843167))
    }

    func testCampusPointsResolveToNearestGroup() {
        XCTAssertEqual(BusLocationGroup.resolve(latitude: 37.2939833, longitude: 126.83535), .dormitory)
        XCTAssertEqual(BusLocationGroup.resolve(latitude: 37.2952667, longitude: 126.8384667), .kitech)
        XCTAssertEqual(BusLocationGroup.resolve(latitude: 37.3007667, longitude: 126.8372333), .campus)
    }

    func testOverlappingRadiiResolveToNearestAnchor() {
        // Points between two groups (both within the match radius) resolve to the group whose anchor is nearest.
        let all = BusLocationGroup.allCases.flatMap { group in group.anchors.map { (group: group, anchor: $0) } }
        for own in all {
            for other in all where other.group != own.group {
                let lat = own.anchor.latitude * 0.7 + other.anchor.latitude * 0.3
                let lon = own.anchor.longitude * 0.7 + other.anchor.longitude * 0.3
                let here = CLLocation(latitude: lat, longitude: lon)
                let distances = all.map { item in
                    let anchor = CLLocation(latitude: item.anchor.latitude, longitude: item.anchor.longitude)
                    return (group: item.group, meters: here.distance(from: anchor))
                }
                guard let nearest = distances.min(by: { $0.meters < $1.meters }),
                      nearest.meters <= BusLocationGroup.matchRadiusMeters else { continue }
                XCTAssertEqual(BusLocationGroup.resolve(latitude: lat, longitude: lon), nearest.group, "\(own.group) vs \(other.group)")
            }
        }
    }

    func testBetweenCloseGroupsPicksNearerSide() {
        // dormitory and kitech anchors are ~280 m apart: points on each side must snap to the nearer one.
        XCTAssertEqual(BusLocationGroup.resolve(latitude: 37.2943, longitude: 126.8358), .dormitory)
        XCTAssertEqual(BusLocationGroup.resolve(latitude: 37.2950, longitude: 126.8380), .kitech)
    }
}
