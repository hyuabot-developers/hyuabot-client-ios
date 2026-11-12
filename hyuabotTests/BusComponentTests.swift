//
//  BusComponentTests.swift
//  hyuabotTests
//
import MapKit
import UIKit
import XCTest
@testable import hyuabot

final class BusComponentTests: XCTestCase {
    @MainActor
    func testHourHeaderInsetDefaultsToTwentyAndAcceptsSixteen() throws {
        let header = BusTimetableHourHeaderView(reuseIdentifier: nil)
        header.frame = CGRect(x: 0, y: 0, width: 390, height: BusTimetableHourHeaderView.height(isFirst: true))
        header.configure(hour: 8, isFirst: true, roundsTop: true)
        header.layoutIfNeeded()
        let strip = try XCTUnwrap(header.contentView.subviews.first)
        XCTAssertEqual(strip.frame.minX, 20, accuracy: 0.5)
        XCTAssertEqual(strip.frame.maxX, 370, accuracy: 0.5)

        header.configure(hour: 8, isFirst: true, roundsTop: true, horizontalInset: 16)
        header.layoutIfNeeded()
        XCTAssertEqual(strip.frame.minX, 16, accuracy: 0.5)
        XCTAssertEqual(strip.frame.maxX, 374, accuracy: 0.5)
    }

    @MainActor
    func testStopSheetKeepsMapStaticAndHeaderAligned() throws {
        let controller = BusStopInfoVC(input: [])
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: 640)
        let name = try XCTUnwrap(allLabels(in: controller.view).first { $0.accessibilityIdentifier == "bus.stop.name" })
        name.text = "한양대학교 정문 앞 아주 긴 정류장 이름"
        controller.view.layoutIfNeeded()
        let views = descendants(of: controller.view)
        let map = try XCTUnwrap(views.compactMap { $0 as? MKMapView }.first)
        XCTAssertFalse(map.isScrollEnabled)
        XCTAssertFalse(map.isZoomEnabled)
        XCTAssertFalse(map.isRotateEnabled)
        XCTAssertFalse(map.isPitchEnabled)
        XCTAssertFalse(map.isUserInteractionEnabled)
        XCTAssertFalse(views.contains { $0.accessibilityIdentifier == "bus.stop.close" })
        XCTAssertFalse(controller.isModalInPresentation)
        let heading = try XCTUnwrap(allLabels(in: controller.view).first {
            $0.text == String(localized: "bus.stop.route_first_last")
        })
        let title = try XCTUnwrap(allLabels(in: controller.view).first { $0.accessibilityIdentifier == "bus.stop.title" })
        for element in [map, name, heading, title] {
            XCTAssertEqual(element.convert(element.bounds, to: controller.view).minX, 20, accuracy: 0.5)
        }
        XCTAssertEqual(heading.frame.minY - name.frame.maxY, 12, accuracy: 0.5)
        let table = try XCTUnwrap(views.compactMap { $0 as? UITableView }.first)
        let header = try XCTUnwrap(table.tableHeaderView)
        XCTAssertEqual(header.bounds.maxY - heading.convert(heading.bounds, to: header).maxY, 8, accuracy: 0.5)
    }

    @MainActor
    func testStopRouteTimesStayAtTrailingEdgeWithLongDestinations() throws {
        let cell = BusFirstLastCellView(style: .default, reuseIdentifier: BusFirstLastCellView.reuseIdentifier)
        let labels = allLabels(in: cell)
        let destinations = labels.filter { $0.numberOfLines == 1 && $0.font.pointSize == 14 }
        let times = labels.filter { $0.font.pointSize == 15 }
        XCTAssertEqual(destinations.count, 2)
        XCTAssertEqual(times.count, 2)
        for destination in destinations {
            destination.text = String(format: String(localized: "bus.stop.destination_format"), "아주 긴 이름의 종점 정류장")
            XCTAssertTrue(destination.text?.hasSuffix(" 방면") == true)
            XCTAssertEqual(destination.lineBreakMode, .byTruncatingTail)
        }
        for time in times { time.text = "05:00–23:59" }
        cell.frame = CGRect(x: 0, y: 0, width: 280, height: 100)
        cell.layoutIfNeeded()
        for time in times {
            XCTAssertEqual(time.convert(time.bounds, to: cell.contentView).maxX, 260, accuracy: 0.5)
            XCTAssertGreaterThanOrEqual(time.bounds.width, time.intrinsicContentSize.width)
            XCTAssertEqual(time.textAlignment, .right)
        }
    }

    @MainActor
    func testSettingsPillFitsNarrowHeaderAndForwardsTap() throws {
        let view = BusRealtimeContentView()
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 640)
        view.layoutIfNeeded()
        let button = view.settingsButton
        let label = try XCTUnwrap(allLabels(in: button).first)
        let capsule = try XCTUnwrap(button.subviews.first { $0.layer.cornerRadius == 18 })
        XCTAssertEqual(button.accessibilityIdentifier, "bus.settings")
        XCTAssertEqual(button.bounds.height, 44, accuracy: 0.5)
        XCTAssertEqual(capsule.bounds.height, 36, accuracy: 0.5)
        XCTAssertGreaterThan(button.bounds.width, 44)
        XCTAssertEqual(label.bounds.width, label.intrinsicContentSize.width, accuracy: 0.5)
        let title = try XCTUnwrap(allLabels(in: view).first { $0.accessibilityIdentifier == "bus.title" })
        XCTAssertEqual(title.convert(title.bounds, to: view).midY, button.convert(button.bounds, to: view).midY, accuracy: 0.5)
        XCTAssertLessThanOrEqual(title.convert(title.bounds, to: view).maxX, button.convert(button.bounds, to: view).minX - 12)
        var didTap = false
        view.onSettingsTap = { didTap = true }
        button.sendActions(for: .touchUpInside)
        XCTAssertTrue(didTap)
    }

    @MainActor
    func testTimetableHeaderBadgesKeepIntrinsicSize() {
        for routes in [["10-1"], ["3100", "3101", "3100N"]] {
            let header = BusTimetableHeaderView()
            header.configure(BusTimetableHeaderContent(
                routeNames: routes, stopName: "한양대 정문", days: [.weekdays], selectedDay: .weekdays,
                dayCounts: [3], filter: nil, state: .list(hiddenPastCount: 0)
            ))
            header.frame = CGRect(x: 0, y: 0, width: 320, height: header.fittingHeight(width: 320))
            header.layoutIfNeeded()
            let badges = descendants(of: header).compactMap { $0 as? BusRouteBadgeView }
            XCTAssertEqual(badges.count, routes.count)
            for badge in badges {
                XCTAssertEqual(badge.bounds.width, badge.intrinsicContentSize.width, accuracy: 1)
                XCTAssertEqual(badge.bounds.height, badge.intrinsicContentSize.height, accuracy: 1)
            }
        }
    }

    @MainActor
    func testTimetableFootnoteFitsOneLine() throws {
        let footer = BusTimetableCardFooterView()
        footer.configure(showsCard: true)
        footer.frame = CGRect(x: 0, y: 0, width: 390, height: BusTimetableCardFooterView.height(showsCard: true, width: 390))
        footer.layoutIfNeeded()
        let label = try XCTUnwrap(allLabels(in: footer).first)
        XCTAssertEqual(label.convert(label.bounds, to: footer).minY, HYUMetrics.Layout.contentToFootnote, accuracy: 0.5)
        XCTAssertEqual(label.numberOfLines, 1)
        XCTAssertEqual(label.lineBreakMode, .byTruncatingTail)
        XCTAssertLessThanOrEqual(label.bounds.height, 17)
        XCTAssertLessThanOrEqual(try XCTUnwrap(label.attributedText).size().width, label.bounds.width)
    }

    @MainActor
    func testTimetableRouteBadgeLeadsTimeInFixedSlotOnMergedRows() throws {
        let cell = BusTimetableRowCell(style: .default, reuseIdentifier: BusTimetableRowCell.reuseIdentifier)
        let row = BusTimetableRowModel(
            entry: BusTimetableEntry(route: "3100", minutes: 600, isFirst: true, isLast: false), state: .upcoming
        )
        cell.frame = CGRect(x: 0, y: 0, width: 390, height: BusTimetableRowCell.rowHeight)
        cell.configure(row, showsRouteBadge: true)
        cell.layoutIfNeeded()
        let time = try XCTUnwrap(allLabels(in: cell).first { $0.attributedText?.string == "10:00" })
        let badge = try XCTUnwrap(descendants(of: cell).compactMap { $0 as? BusRouteBadgeView }.first)
        let chip = try XCTUnwrap(allLabels(in: cell).first { $0.attributedText?.string == String(localized: "bus.timetable.chip.first") })
        let badgeFrame = badge.convert(badge.bounds, to: cell)
        let mergedTimeX = time.convert(.zero, to: cell).x
        XCTAssertFalse(badge.isHidden)
        XCTAssertGreaterThan(badgeFrame.height, 0)
        XCTAssertEqual(badgeFrame.minX, 36, accuracy: 0.5)
        XCTAssertLessThan(badgeFrame.maxX, mergedTimeX)
        XCTAssertGreaterThan(chip.convert(chip.bounds, to: cell).minX, time.convert(time.bounds, to: cell).maxX)
        XCTAssertFalse(chip.isDescendant(of: badge))
        XCTAssertTrue(cell.accessibilityLabel?.contains("3100") == true)

        let lastRow = BusTimetableRowModel(
            entry: BusTimetableEntry(route: "50", minutes: 660, isFirst: false, isLast: true), state: .upcoming
        )
        cell.configure(lastRow, showsRouteBadge: true)
        cell.layoutIfNeeded()
        XCTAssertFalse(badge.isHidden)
        XCTAssertEqual(allLabels(in: badge).first?.text, "50")
        XCTAssertEqual(badge.bounds.width, badgeFrame.width, accuracy: 0.5)
        XCTAssertEqual(time.convert(.zero, to: cell).x, mergedTimeX, accuracy: 0.5)

        cell.configure(row, showsRouteBadge: false)
        cell.layoutIfNeeded()
        XCTAssertTrue(badge.isHidden)
        XCTAssertEqual(time.convert(.zero, to: cell).x, 36, accuracy: 0.5)
        XCTAssertFalse(cell.accessibilityLabel?.contains("3100") == true)
    }

    @MainActor
    func testDepartureLogCellResetsHighlightWhenReused() {
        let cell = BusLogCell(style: .default, reuseIdentifier: BusLogCell.reuseIdentifier)
        cell.configure(BusDepartureLogRowModel(time: "15:00", isPast: false, isNext: true))
        XCTAssertEqual(cell.accessibilityIdentifier, "bus.log.next")
        XCTAssertTrue(cell.accessibilityLabel?.contains("15:00") == true)
        cell.configure(BusDepartureLogRowModel(time: "14:30", isPast: true, isNext: false))
        XCTAssertEqual(cell.accessibilityLabel, "14:30")
        XCTAssertEqual(cell.accessibilityIdentifier, "bus.log.time")
        XCTAssertEqual(allLabels(in: cell).first?.backgroundColor, .clear)
    }

    @MainActor
    func testDepartureLogSheetKeepsBadgesCompactAtNarrowWidth() {
        let controller = BusLogVC(stopID: 1, routes: [], routeNames: ["10-1", "3102"], stopName: "한양대")
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: 640)
        controller.view.layoutIfNeeded()
        let badges = descendants(of: controller.view).compactMap { $0 as? BusRouteBadgeView }
        XCTAssertEqual(badges.count, 2)
        XCTAssertTrue(badges.allSatisfy { $0.bounds.width < 70 && $0.bounds.width > 0 })
        let tables = descendants(of: controller.view).compactMap { $0 as? UITableView }
        XCTAssertEqual(tables.count, 3)
        XCTAssertTrue(tables.allSatisfy { $0.bounds.width > 60 })
        XCTAssertTrue(descendants(of: controller.view).contains { $0.accessibilityIdentifier == "bus.log.expand" })
    }

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

extension BusComponentTests {
    @MainActor
    func testTimetableNavigationShowsTitleOnlyAfterScrolling() {
        let controller = BusTimetableVC(stopID: 1, routes: [1, 2], routeNames: ["10-1", "50"], stopName: "Stop")
        let parent = UIViewController()
        parent.navigationItem.backButtonTitle = String(localized: "tabbar.bus")
        parent.navigationItem.backButtonDisplayMode = .minimal
        let navigation = UINavigationController(rootViewController: parent)
        navigation.pushViewController(controller, animated: false)
        controller.loadViewIfNeeded()
        controller.viewWillAppear(false)
        XCTAssertFalse(navigation.isNavigationBarHidden)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertEqual(parent.navigationItem.backButtonDisplayMode, .minimal)
        XCTAssertFalse(descendants(of: controller.view).contains { $0 is SubwayCompactBarView })
        XCTAssertEqual(controller.navigationItem.title, "Stop")
        XCTAssertNil(controller.navigationItem.titleView)
        XCTAssertNil(controller.navigationItem.leftBarButtonItem)
        for appearance in [controller.navigationItem.standardAppearance, controller.navigationItem.compactAppearance] {
            let color = appearance?.titleTextAttributes[.foregroundColor] as? UIColor
            XCTAssertEqual(color, SettingsStyle.Color.text)
        }
        let edges = [
            controller.navigationItem.scrollEdgeAppearance,
            controller.navigationItem.compactScrollEdgeAppearance
        ]
        for appearance in edges {
            XCTAssertEqual(appearance?.titleTextAttributes[.foregroundColor] as? UIColor, .clear)
            XCTAssertNil(appearance?.backgroundEffect)
        }
    }

    @MainActor
    func testStopRouteDirectionsFollowBadgeWidthAndAlignWithinCard() throws {
        for width: CGFloat in [280, 320, 390] {
            var directionPositions: [CGFloat] = []
            for route in ["10", "3100N", "3101"] {
                let cell = BusFirstLastCellView(style: .default, reuseIdentifier: BusFirstLastCellView.reuseIdentifier)
                let badge = try XCTUnwrap(descendants(of: cell).compactMap { $0 as? BusRouteBadgeView }.first)
                badge.configure(route: route)
                let destinations = allLabels(in: cell).filter { $0.numberOfLines == 1 && $0.font.pointSize == 14 }
                for destination in destinations { destination.text = "한양대학교 방면" }
                let times = allLabels(in: cell).filter { $0.font.pointSize == 15 }
                for time in times { time.text = "05:00–23:59" }
                cell.frame = CGRect(x: 0, y: 0, width: width, height: 100)
                cell.layoutIfNeeded()
                XCTAssertEqual(badge.bounds.width, badge.intrinsicContentSize.width, accuracy: 0.5)
                XCTAssertEqual(badge.convert(badge.bounds, to: cell.contentView).minX, 20, accuracy: 0.5)
                let badgeEnd = badge.convert(badge.bounds, to: cell.contentView).maxX
                for destination in destinations {
                    XCTAssertEqual(
                        destination.convert(destination.bounds, to: cell.contentView).minX,
                        badgeEnd + 8,
                        accuracy: 0.5
                    )
                }
                try directionPositions.append(XCTUnwrap(destinations.first).convert(.zero, to: cell.contentView).x)
                for time in times {
                    XCTAssertEqual(time.convert(time.bounds, to: cell.contentView).maxX, width - 20, accuracy: 0.5)
                    XCTAssertGreaterThanOrEqual(time.bounds.width, time.intrinsicContentSize.width)
                }
            }
            XCTAssertGreaterThan(directionPositions[1], directionPositions[0])
        }
    }
}

extension BusComponentTests {
    func testSectionHeaderDropsBadgesAndRowsShowThem() {
        let card = BusSectionCardView()
        card.configure(BusSectionContent(
            routeNames: ["10-1"], stopName: String(localized: "bus.stop.main_gate"),
            rows: [
                BusArrivalRowModel(route: "10-1", isRealtime: true, primary: .stopsBefore(3),
                                   remaining: .minutes(5), seats: .unknown, isLowFloor: false,
                                   destinationArrival: nil),
                BusArrivalRowModel(route: "10-1", isRealtime: true, primary: .stopsBefore(2),
                                   remaining: .minutes(8), seats: .unknown, isLowFloor: false,
                                   destinationArrival: nil)
            ], isLoading: false
        ))
        card.frame = CGRect(x: 0, y: 0, width: 375, height: 200)
        card.layoutIfNeeded()
        let badges = descendants(of: card).compactMap { $0 as? BusRouteBadgeView }
        XCTAssertEqual(badges.count, 2)
        for badge in badges {
            var ancestor = badge.superview
            var belongsToRow = false
            while let view = ancestor {
                if view is BusArrivalRowView { belongsToRow = true; break }
                ancestor = view.superview
            }
            XCTAssertTrue(belongsToRow)
        }
    }

    func testArrivalRowShowsPrimaryUnderMinutes() {
        let row = BusArrivalRowView()
        let model = BusArrivalRowModel(route: "10-1", isRealtime: false, primary: .waitingAtOrigin,
                                       remaining: .minutes(5), seats: .unknown, isLowFloor: false,
                                       destinationArrival: nil)
        row.configure(model, showsRouteBadge: true, showsSeparator: false)
        row.frame = CGRect(x: 0, y: 0, width: 375, height: 64)
        row.layoutIfNeeded()
        let label = descendants(of: row).compactMap { $0 as? UILabel }.first {
            $0.text == String(localized: "bus.realtime.waiting_at_origin")
        }
        let minutesLabel = descendants(of: row).compactMap { $0 as? UILabel }.first {
            $0.text == BusDisplayLogic.remainingText(.minutes(5))
        }
        XCTAssertNotNil(label, "Non-realtime rows must include the primary subtitle")
        XCTAssertNotNil(minutesLabel, "The remaining-time label must be present")
        if let label, let minutesLabel {
            let subtitleFrame = label.convert(label.bounds, to: row)
            let minutesFrame = minutesLabel.convert(minutesLabel.bounds, to: row)
            XCTAssertGreaterThan(subtitleFrame.minY, minutesFrame.maxY)
            XCTAssertEqual(subtitleFrame.maxX, minutesFrame.maxX, accuracy: 1)
        }
    }
}

final class BusRealtimeNavigationTests: XCTestCase {
    @MainActor
    func testRealtimeScreenShowsChevronOnlyBackOnPushedScreens() {
        let controller = BusRealtimeVC()
        controller.loadViewIfNeeded()
        XCTAssertEqual(controller.navigationItem.backButtonTitle, String(localized: "tabbar.bus"))
        XCTAssertEqual(controller.navigationItem.backButtonDisplayMode, .minimal)
    }
}
