//
//  BusComponentTests.swift
//  hyuabotTests
//
import UIKit
import XCTest
@testable import hyuabot

final class BusComponentTests: XCTestCase {
    func testArrivalRowLayoutAndLowFloorChip() {
        let row = BusArrivalRowView()
        row.configure(realtimeModel(isLowFloor: true), showsRouteBadge: false, showsSeparator: false)
        row.setNeedsLayout()
        row.layoutIfNeeded()
        let size = row.systemLayoutSizeFitting(CGSize(width: 343, height: UIView.layoutFittingCompressedSize.height))
        XCTAssertGreaterThanOrEqual(size.height, 64)
        XCTAssertTrue(allLabels(in: row).contains { $0.text == String(localized: "bus.realtime.low.floor") })

        let regularRow = BusArrivalRowView()
        regularRow.configure(realtimeModel(isLowFloor: false), showsRouteBadge: false, showsSeparator: false)
        regularRow.setNeedsLayout()
        regularRow.layoutIfNeeded()
        XCTAssertFalse(allLabels(in: regularRow).contains { $0.text == String(localized: "bus.realtime.low.floor") && !$0.isHidden })
    }

    func testSectionCardLoadingLayout() {
        let card = BusSectionCardView()
        card.configure(BusSectionContent(routeNames: [], stopName: "", rows: [], isLoading: true))
        card.setNeedsLayout()
        card.layoutIfNeeded()
        let size = card.systemLayoutSizeFitting(CGSize(width: 343, height: UIView.layoutFittingCompressedSize.height))
        XCTAssertEqual(size.height, 48 + 3 * 64 + 44, accuracy: 1)
    }

    func testBadgesHugContentWithLongRowsOnEveryTab() {
        for routes in [["10-1"], ["3102"], ["3100", "3101", "3100N"], ["7070", "9090"], ["50"]] {
            let card = BusSectionCardView()
            card.configure(BusSectionContent(
                routeNames: routes, stopName: String(localized: "bus.stop.main_gate"),
                rows: [BusArrivalRowModel(route: routes[0], isRealtime: true, primary: .stopsBefore(123),
                                          remaining: .minutes(69), seats: .unknown, isLowFloor: false,
                                          destinationArrival: nil)], isLoading: false
            ))
            card.frame = CGRect(x: 0, y: 0, width: 320, height: 156)
            card.layoutIfNeeded()
            let badges = descendants(of: card).compactMap { $0 as? BusRouteBadgeView }
            XCTAssertFalse(badges.isEmpty)
            for badge in badges {
                XCTAssertEqual(badge.bounds.width, badge.intrinsicContentSize.width, accuracy: 1)
            }
            XCTAssertEqual(card.stopInfoButton.bounds.size, CGSize(width: 44, height: 44))
        }
    }

    func testArrivalRowRendersMinutesOverAnHour() {
        let row = BusArrivalRowView()
        let model = BusArrivalRowModel(route: "10-1", isRealtime: false, primary: .waitingAtOrigin,
                                       remaining: .minutes(69), seats: .unknown, isLowFloor: false,
                                       destinationArrival: nil)
        row.configure(model, showsRouteBadge: false, showsSeparator: false)
        XCTAssertTrue(row.accessibilityLabel?.contains("69분") == true)
        XCTAssertFalse(row.accessibilityLabel?.contains("시간") == true)
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    func testTimetableLayoutMetrics() {
        XCTAssertEqual(BusTimetableRowCell.rowHeight, 44)
        XCTAssertEqual(BusTimetableHourHeaderView.height(isFirst: true), 32)
        XCTAssertEqual(BusTimetableHourHeaderView.height(isFirst: false), 26)
    }

    func testArrivalRowRendersKoreanETA() {
        let row = BusArrivalRowView()
        row.configure(realtimeModel(isLowFloor: false), showsRouteBadge: false, showsSeparator: false)
        XCTAssertTrue(row.accessibilityLabel?.contains("상록수역 14:30 도착") == true)
        XCTAssertTrue(row.accessibilityLabel?.contains("잔여 3석") == true)
        XCTAssertTrue(row.accessibilityLabel?.contains("7분") == true)
        XCTAssertTrue(row.accessibilityLabel?.contains("3정류장 전") == true)
        XCTAssertFalse(row.accessibilityLabel?.contains("bus.realtime") == true)
    }

    func testTimetableEmptyStateRendersKoreanText() {
        XCTAssertEqual(
            BusTimetableHeaderState.noService(dayName: "토요일"),
            .empty(title: "토요일에는 운행하지 않아요", detail: "다른 요일 탭에서 확인하세요")
        )
        if case let .empty(title, _) = BusTimetableHeaderState.noData(route: "3100N") {
            XCTAssertEqual(title, "3100N번은 시간표가 제공되지 않아요")
        } else {
            XCTFail("Expected no data empty state")
        }

        let header = BusTimetableHeaderView()
        header.configure(BusTimetableHeaderContent(
            routeNames: [], stopName: "", days: [.weekdays], selectedDay: .weekdays,
            dayCounts: [0], filter: nil, state: .noService(dayName: "토요일")
        ))
        XCTAssertTrue(allLabels(in: header).contains { ($0.text ?? $0.attributedText?.string) == "토요일에는 운행하지 않아요" })
    }

    @MainActor
    func testTimetablePublishEndsLoading() throws {
        let data = BusTimetableData.shared
        data.isLoading.onNext(true)
        data.publish([])
        XCTAssertEqual(try data.isLoading.value(), false)
        XCTAssertTrue(try data.timetable.value().isEmpty)

        data.isLoading.onNext(true)
        let item = BusTimetableItem(route: "3100N", weekdays: "weekdays", time: Date())
        data.publish([item])
        XCTAssertEqual(try data.isLoading.value(), false)
        XCTAssertEqual(try data.timetable.value().count, 1)
        data.publish([])
    }

    private func realtimeModel(isLowFloor: Bool) -> BusArrivalRowModel {
        BusArrivalRowModel(
            route: "3102", isRealtime: true, primary: .stopsBefore(3), remaining: .minutes(7),
            seats: .available(3), isLowFloor: isLowFloor, destinationArrival: "14:30", destinationName: "상록수역"
        )
    }

    private func allLabels(in view: UIView) -> [UILabel] {
        (view as? UILabel).map { [$0] } ?? view.subviews.flatMap { allLabels(in: $0) }
    }
}
