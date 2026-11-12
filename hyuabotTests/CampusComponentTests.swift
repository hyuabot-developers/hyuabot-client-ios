//
//  CampusComponentTests.swift
//  hyuabot
//

@testable import hyuabot
import XCTest

@MainActor
final class CampusComponentTests: XCTestCase {
    func testCampusToolsKeepIdentifiersAndOrder() {
        let vc = CampusVC()
        vc.loadViewIfNeeded()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.view.layoutIfNeeded()
        let ids = ["commuter_bus", "map", "reading_room", "calendar", "contact", "setting", "inquiry", "donate"]
        let controls = ids.map { id -> UIControl in
            let view = findView(withIdentifier: "campus.tool." + id, in: vc.view)
            XCTAssertTrue(view is UIControl)
            XCTAssertTrue(view?.accessibilityTraits.contains(.button) == true)
            return view as? UIControl ?? UIControl()
        }
        let frames = controls.map { $0.convert($0.bounds, to: vc.view) }
        XCTAssertLessThan(frames[0].minY, frames[1].minY)
        XCTAssertEqual(frames[1].minY, frames[2].minY, accuracy: 0.5)
        XCTAssertLessThan(frames[1].minX, frames[2].minX)
        XCTAssertEqual(frames[1].height, frames[2].height, accuracy: 0.5)
    }

    func testCampusFeatureBadgeStaysNextToTitle() throws {
        let control = CampusFeatureCardControl(title: "통학버스", subtitle: "셔틀버스 안내", badge: "NEW", symbol: "bus")
        control.frame = CGRect(x: 0, y: 0, width: 354, height: 64)
        control.layoutIfNeeded()

        let titleLabel = try XCTUnwrap(labels(in: control).first { $0.text?.contains("통학버스") == true })
        let badgeLabel = try XCTUnwrap(labels(in: control).first { $0.text == "NEW" })
        let titleFrame = titleLabel.convert(titleLabel.bounds, to: control)
        let badgeContainer = try XCTUnwrap(badgeLabel.superview)
        let badgeFrame = badgeContainer.convert(badgeContainer.bounds, to: control)

        XCTAssertEqual(badgeFrame.minX - titleFrame.maxX, 6, accuracy: 0.5)
        XCTAssertLessThan(titleLabel.frame.width, 140)
    }

    func testDonateRowHasKakaoPayAccessibilityLabel() {
        let vc = CampusVC()
        vc.loadViewIfNeeded()
        XCTAssertEqual(findView(withIdentifier: "campus.tool.donate", in: vc.view)?.accessibilityLabel,
                       String(localized: "campus.donate.accessibility_label"))
    }

    func testCampusCardsKeepVoiceOverSubtitles() {
        let vc = CampusVC()
        vc.loadViewIfNeeded()
        XCTAssertEqual(findView(withIdentifier: "campus.tool.map", in: vc.view)?.accessibilityValue,
                       String(localized: "campus.map.subtitle"))
        XCTAssertEqual(findView(withIdentifier: "campus.tool.reading_room", in: vc.view)?.accessibilityValue,
                       String(localized: "campus.reading_room.subtitle"))
        XCTAssertEqual(findView(withIdentifier: "campus.tool.commuter_bus", in: vc.view)?.accessibilityValue,
                       String(localized: "campus.commuter.badge") + ", " + String(localized: "campus.commuter.subtitle"))
    }

    func testCommuterDestinationPushesEmptyScreen() {
        XCTAssertEqual(CampusDestination(rawValue: "commuter_bus"), .commuterBus)
        let nc = CampusNC()
        nc.loadViewIfNeeded()
        nc.open(.commuterBus, animated: false)
        let commuter = nc.topViewController
        XCTAssertTrue(commuter is CommuterBusVC)
        commuter?.loadViewIfNeeded()
        XCTAssertEqual(commuter?.title, String(localized: "campus.commuter.title"))
        XCTAssertEqual(commuter?.view.accessibilityIdentifier, "commuter.root")
    }

    func testFloatingTabBarMatchesDesignGeometry() throws {
        let bar = makeBar(selectedIndex: 4)
        XCTAssertEqual(FloatingTabBar.barHeight, 64)
        XCTAssertEqual(FloatingTabBar.sideInset, 16)
        XCTAssertEqual(FloatingTabBar.bottomInset, 16)
        XCTAssertEqual(FloatingTabBar.maxWidth, 480)
        XCTAssertEqual(bar.layer.cornerRadius, 32)
        XCTAssertEqual(bar.layer.borderWidth, 1)
        XCTAssertEqual(bar.accessibilityIdentifier, "tab.bar")
        let button = try XCTUnwrap(bar.button(at: 0))
        let frame = button.convert(button.bounds, to: bar)
        XCTAssertEqual(frame.minX, 5, accuracy: 0.5)
        XCTAssertEqual(frame.minY, 5, accuracy: 0.5)
        XCTAssertEqual(frame.height, 54, accuracy: 0.5)
        XCTAssertEqual(frame.width, (358 - 10) / 5, accuracy: 0.5)
        for index in 0..<5 { XCTAssertEqual(bar.button(at: index)?.layer.cornerRadius, 27) }
        XCTAssertEqual(bar.button(at: 3)?.accessibilityIdentifier, "tab.3")
    }

    func testFloatingTabBarSelectionStyle() {
        let bar = makeBar(selectedIndex: 4)
        XCTAssertEqual(bar.button(at: 4)?.backgroundColor, SettingsStyle.Color.tabSelectionFill)
        XCTAssertTrue(bar.button(at: 4)?.accessibilityTraits.contains(.selected) == true)
        XCTAssertTrue(bar.button(at: 0)?.backgroundColor == .clear || bar.button(at: 0)?.backgroundColor == nil)
        XCTAssertFalse(bar.button(at: 0)?.accessibilityTraits.contains(.selected) ?? true)
        bar.selectedIndex = 1
        XCTAssertTrue(bar.button(at: 1)?.accessibilityTraits.contains(.selected) == true)
        XCTAssertFalse(bar.button(at: 4)?.accessibilityTraits.contains(.selected) ?? true)
        var tapped: Int?
        bar.onSelect = { tapped = $0 }
        bar.button(at: 2)?.sendActions(for: .touchUpInside)
        XCTAssertEqual(tapped, 2)
    }

    func testRootVCHidesSystemTabBarAndSyncsSelection() {
        let root = RootVC()
        root.loadViewIfNeeded()
        XCTAssertTrue(root.floatingTabBar.superview === root.view)
        root.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        root.view.layoutIfNeeded()
        XCTAssertEqual(root.floatingTabBar.frame.height, 64, accuracy: 0.5)
        XCTAssertEqual(root.floatingTabBar.frame.maxY, 874 - 16, accuracy: 0.5)
        if #available(iOS 18.0, *) { XCTAssertTrue(root.isTabBarHidden) } else { XCTAssertTrue(root.tabBar.isHidden) }
        let identifiers = (0..<5).compactMap { root.floatingTabBar.button(at: $0)?.accessibilityIdentifier }
        XCTAssertEqual(identifiers, ["tab.shuttle", "tab.bus", "tab.subway", "tab.cafeteria", "tab.campus"])
        root.selectedIndex = 3
        XCTAssertEqual(root.floatingTabBar.selectedIndex, 3)
        root.selectedViewController = root.campusNC
        XCTAssertEqual(root.floatingTabBar.selectedIndex, 4)
    }

    func testFloatingTabBarUpdateItemRefreshesMetadata() throws {
        let bar = makeBar(selectedIndex: 2)
        var tapped: Int?
        bar.onSelect = { tapped = $0 }
        let custom = UITabBarItem(title: "Custom", image: UIImage(systemName: "star"), tag: 0)
        custom.accessibilityIdentifier = "tab.custom"
        bar.updateItem(custom, at: 0)
        let button = try XCTUnwrap(bar.button(at: 0))
        XCTAssertEqual(button.accessibilityIdentifier, "tab.custom")
        XCTAssertEqual(button.accessibilityLabel, "Custom")
        XCTAssertEqual(button.largeContentTitle, "Custom")
        XCTAssertNotNil(button.largeContentImage)
        XCTAssertTrue(labels(in: button).contains { $0.attributedText?.string == "Custom" })
        XCTAssertNotNil(bar.button(at: 4))
        XCTAssertNil(bar.button(at: 5))
        XCTAssertEqual(bar.selectedIndex, 2)
        XCTAssertTrue(bar.button(at: 2)?.accessibilityTraits.contains(.selected) == true)
        XCTAssertNil(tapped)
        let shuttle = UITabBarItem(title: "Shuttle", image: UIImage(systemName: "bus"), tag: 0)
        shuttle.accessibilityIdentifier = "tab.shuttle"
        bar.updateItem(shuttle, at: 0)
        XCTAssertEqual(button.accessibilityIdentifier, "tab.shuttle")
        XCTAssertEqual(button.accessibilityLabel, "Shuttle")
        XCTAssertEqual(button.largeContentTitle, "Shuttle")
        XCTAssertNotNil(button.largeContentImage)
        XCTAssertTrue(labels(in: button).contains { $0.attributedText?.string == "Shuttle" })
        bar.updateItem(custom, at: 9)
        XCTAssertEqual(button.accessibilityLabel, "Shuttle")
    }

    func testRootVCRefreshesShuttleTabItem() {
        let root = RootVC()
        root.loadViewIfNeeded()
        root.selectedIndex = 2
        root.shuttleNC.tabBarItem.title = "Updated"
        root.shuttleNC.tabBarItem.image = UIImage(systemName: "star")
        root.shuttleNC.tabBarItem.accessibilityIdentifier = "tab.shuttle.updated"
        root.refreshFloatingTabItem(for: root.shuttleNC)
        let button = root.floatingTabBar.button(at: 0)
        XCTAssertEqual(button?.accessibilityIdentifier, "tab.shuttle.updated")
        XCTAssertEqual(button?.accessibilityLabel, "Updated")
        XCTAssertEqual(button?.largeContentTitle, "Updated")
        XCTAssertNotNil(root.floatingTabBar.button(at: 4))
        XCTAssertNil(root.floatingTabBar.button(at: 5))
        XCTAssertEqual(root.selectedIndex, 2)
        XCTAssertEqual(root.floatingTabBar.selectedIndex, 2)
        root.shuttleNC.tabBarItem.title = String(localized: "tabbar.shuttle")
        root.shuttleNC.tabBarItem.image = UIImage(systemName: "bus")
        root.shuttleNC.tabBarItem.accessibilityIdentifier = "tab.shuttle"
        root.refreshFloatingTabItem(for: root.shuttleNC)
        XCTAssertEqual(button?.accessibilityIdentifier, "tab.shuttle")
        XCTAssertEqual(button?.accessibilityLabel, String(localized: "tabbar.shuttle"))
        XCTAssertEqual(button?.largeContentTitle, String(localized: "tabbar.shuttle"))
        XCTAssertEqual(root.selectedIndex, 2)
        XCTAssertEqual(root.floatingTabBar.selectedIndex, 2)
    }

    private func makeBar(selectedIndex: Int) -> FloatingTabBar {
        let bar = FloatingTabBar()
        bar.frame = CGRect(x: 0, y: 0, width: 358, height: 64)
        let items = (0..<5).map { index -> UITabBarItem in
            let item = UITabBarItem(title: "t\(index)", image: UIImage(systemName: "bus"), tag: index)
            item.accessibilityIdentifier = "tab.\(index)"
            return item
        }
        bar.setItems(items)
        bar.selectedIndex = selectedIndex
        bar.layoutIfNeeded()
        return bar
    }

    private func findView(withIdentifier id: String, in root: UIView) -> UIView? {
        if root.accessibilityIdentifier == id { return root }
        for view in root.subviews {
            if let found = findView(withIdentifier: id, in: view) { return found }
        }
        return nil
    }

    private func labels(in root: UIView) -> [UILabel] {
        var found = (root as? UILabel).map { [$0] } ?? []
        let children = root.subviews + ((root as? UIStackView)?.arrangedSubviews ?? [])
        for child in children { found.append(contentsOf: labels(in: child)) }
        return found
    }
}
