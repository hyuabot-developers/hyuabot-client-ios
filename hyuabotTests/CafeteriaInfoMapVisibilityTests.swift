//
//  CafeteriaInfoMapVisibilityTests.swift
//  hyuabotTests
//

import MapKit
import XCTest
@testable import hyuabot

@MainActor
final class CafeteriaInfoMapVisibilityTests: XCTestCase {
    private func makeViewController() -> CafeteriaInfoVC {
        let vc = CafeteriaInfoVC(cafeteriaID: 1)
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 402, height: 700)
        vc.view.layoutIfNeeded()
        return vc
    }

    func testMapCoordinateRejectsZeroAndInvalidCoordinates() {
        XCTAssertNil(CafeteriaInfoVC.mapCoordinate(latitude: 0, longitude: 0))
        XCTAssertNil(CafeteriaInfoVC.mapCoordinate(latitude: 91, longitude: 0))
        XCTAssertNotNil(CafeteriaInfoVC.mapCoordinate(latitude: 37.2967, longitude: 126.8351))
    }

    func testInitialStatePlacesRunningTimeWhereMapWouldStart() {
        let vc = makeViewController()

        XCTAssertTrue(vc.mapCardView.isHidden)
        XCTAssertLessThan(abs(vc.runningTimeTitleLabel.frame.minY - vc.mapCardView.frame.minY), 1)
    }

    func testNilCoordinateKeepsMapHiddenAndClearsAnnotations() {
        let vc = makeViewController()
        vc.updateMapCard(coordinate: nil, title: nil)

        XCTAssertTrue(vc.mapCardView.isHidden)
        XCTAssertEqual(vc.cafeteriaMapView.annotations.count, 0)
        XCTAssertLessThan(abs(vc.runningTimeTitleLabel.frame.minY - vc.mapCardView.frame.minY), 1)
    }

    func testValidCoordinateShowsMapAndAnnotationBelowRunningTime() {
        let vc = makeViewController()
        let coordinate = CLLocationCoordinate2D(latitude: 37.2967, longitude: 126.8351)
        vc.updateMapCard(coordinate: coordinate, title: "x")

        XCTAssertFalse(vc.mapCardView.isHidden)
        XCTAssertEqual(vc.cafeteriaMapView.annotations.count, 1)
        XCTAssertGreaterThanOrEqual(vc.runningTimeTitleLabel.frame.minY, vc.mapCardView.frame.maxY + 11)
    }

    func testReturningToNilHidesMapAndRestoresCompactLayout() {
        let vc = makeViewController()
        vc.updateMapCard(coordinate: CLLocationCoordinate2D(latitude: 37.2967, longitude: 126.8351), title: "x")
        vc.updateMapCard(coordinate: nil, title: nil)

        XCTAssertTrue(vc.mapCardView.isHidden)
        XCTAssertEqual(vc.cafeteriaMapView.annotations.count, 0)
        XCTAssertLessThan(abs(vc.runningTimeTitleLabel.frame.minY - vc.mapCardView.frame.minY), 1)
    }
}
