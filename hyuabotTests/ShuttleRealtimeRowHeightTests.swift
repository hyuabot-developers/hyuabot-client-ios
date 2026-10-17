//
//  ShuttleRealtimeRowHeightTests.swift
//  hyuabotTests
//

import UIKit
import XCTest
@testable import hyuabot

@MainActor
final class ShuttleRealtimeRowHeightTests: XCTestCase {
    func testSkeletonRowFallsBackToInformationRowHeight() {
        let height = ShuttleRealtimeTabVC.emptyRowHeight(
            isShuttleRealtimeTable: true,
            showsInitialSkeleton: true,
            isTransferExpansionRow: false,
            hasDestinationEntries: false
        )
        XCTAssertNil(height)
    }

    func testLoadedEmptyRowUsesAutomaticDimension() {
        let height = ShuttleRealtimeTabVC.emptyRowHeight(
            isShuttleRealtimeTable: true,
            showsInitialSkeleton: false,
            isTransferExpansionRow: false,
            hasDestinationEntries: false
        )
        XCTAssertEqual(height, UITableView.automaticDimension)
    }

    func testPopulatedRowFallsBackToExistingLogic() {
        let height = ShuttleRealtimeTabVC.emptyRowHeight(
            isShuttleRealtimeTable: true,
            showsInitialSkeleton: false,
            isTransferExpansionRow: false,
            hasDestinationEntries: true
        )
        XCTAssertNil(height)
    }

    func testTransferExpansionRowFallsBackToExistingLogic() {
        let height = ShuttleRealtimeTabVC.emptyRowHeight(
            isShuttleRealtimeTable: true,
            showsInitialSkeleton: false,
            isTransferExpansionRow: true,
            hasDestinationEntries: false
        )
        XCTAssertNil(height)
    }

    func testNonShuttleTableFallsBackToExistingLogic() {
        let height = ShuttleRealtimeTabVC.emptyRowHeight(
            isShuttleRealtimeTable: false,
            showsInitialSkeleton: false,
            isTransferExpansionRow: false,
            hasDestinationEntries: false
        )
        XCTAssertNil(height)
    }
}
