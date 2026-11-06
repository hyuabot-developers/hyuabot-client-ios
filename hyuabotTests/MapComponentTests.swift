//
//  MapComponentTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

@MainActor
final class MapComponentTests: XCTestCase {
    func testSearchBarKeepsIdentifierAndTogglesClear() {
        let view = MapSearchBarView()
        XCTAssertEqual(view.textField.accessibilityIdentifier, "map.search_text_field")
        view.text = "304"
        XCTAssertEqual(view.textField.text, "304")
    }

    func testSearchBarForwardsTextChanges() {
        let view = MapSearchBarView()
        var received: String?
        view.onTextChange = { received = $0 }
        view.textField.text = "공학"
        view.textField.sendActions(for: .editingChanged)
        XCTAssertEqual(received, "공학")
    }

    func testBuildingCardWithoutGuideDisablesPrimary() {
        let view = MapBuildingCardView()
        view.apply(.init(title: "컨퍼런스홀", caption: "x", translatesCaption: false, hasGuide: false, showsShowAll: false))
        XCTAssertFalse(view.primaryButton.isEnabled)
        XCTAssertTrue(view.showAllButton.isHidden)
    }

    func testBuildingCardResultShowsBothActions() {
        let view = MapBuildingCardView()
        view.apply(.init(title: "컨퍼런스홀", caption: "x", translatesCaption: false, hasGuide: true, showsShowAll: true))
        XCTAssertTrue(view.primaryButton.isEnabled)
        XCTAssertFalse(view.showAllButton.isHidden)
    }

    func testResultCellAccessibilityLabel() {
        let cell = SearchResultCellView(style: .default, reuseIdentifier: nil)
        cell.configure(
            item: RoomItem(name: "컴퓨터실습실", number: "304", building: "제3공학관", latitude: 0, longitude: 0),
            isFirst: true,
            isLast: true
        )
        XCTAssertTrue(cell.accessibilityLabel?.contains("제3공학관") == true)
        XCTAssertTrue(cell.accessibilityLabel?.contains("304") == true)
    }

    func testStatusPillAccessibilityLabel() {
        let view = MapStatusPillView()
        view.apply(.count(10))
        XCTAssertTrue(view.accessibilityLabel?.contains("10") == true)
    }

    func testMapEmptyCellKeywordPresentation() {
        let cell = SearchEmptyCellView(style: .default, reuseIdentifier: nil)
        cell.configure(keyword: "xyz")
        let visibleLabels = labels(in: cell.contentView).filter(isVisible)
        XCTAssertTrue(visibleLabels.contains { $0.text == String(localized: "map.search.empty.title") })
        XCTAssertTrue(visibleLabels.contains { $0.text?.contains("xyz") == true })
        XCTAssertTrue(cell.contentView.subviews.compactMap { $0 as? StateView }.first?.isHidden == true)
    }

    func testMapEmptyCellFailurePresentation() {
        let cell = SearchEmptyCellView(style: .default, reuseIdentifier: nil)
        cell.configureFailure()
        let visibleLabels = labels(in: cell.contentView).filter(isVisible)
        XCTAssertTrue(visibleLabels.contains { $0.text == String(localized: "map.search.error.title") })
        XCTAssertFalse(visibleLabels.contains { $0.text?.contains("xyz") == true })
    }

    func testMapEmptyCellLegacyConfigureShowsStateView() {
        let cell = SearchEmptyCellView(style: .default, reuseIdentifier: nil)
        cell.configure(.empty(message: "m"))
        XCTAssertFalse(cell.contentView.subviews.compactMap { $0 as? StateView }.first?.isHidden ?? true)
    }

    func testSkeletonCellLaysOutWithDistinctWidths() {
        let cell = MapSearchSkeletonCellView(style: .default, reuseIdentifier: nil)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 80))
        host.addSubview(cell)
        cell.frame = host.bounds
        cell.configure(index: 0, isFirst: true, isLast: false)
        host.setNeedsLayout()
        host.layoutIfNeeded()
        let stack = verticalStack(in: cell.contentView)
        let firstWidth = stack?.arrangedSubviews.first?.bounds.width
        let stackWidth = stack?.bounds.width

        cell.configure(index: 1, isFirst: false, isLast: true)
        host.setNeedsLayout()
        host.layoutIfNeeded()
        let secondWidth = verticalStack(in: cell.contentView)?.arrangedSubviews.first?.bounds.width
        XCTAssertNotNil(firstWidth)
        XCTAssertNotNil(secondWidth)
        XCTAssertNotEqual(firstWidth, secondWidth)
        XCTAssertTrue((firstWidth ?? 0) < (stackWidth ?? 0))
    }

    private func labels(in view: UIView) -> [UILabel] {
        ([view] + view.subviews.flatMap(labels(in:))).compactMap { $0 as? UILabel }
    }

    private func verticalStack(in view: UIView) -> UIStackView? {
        if let stack = view as? UIStackView, stack.axis == .vertical, stack.arrangedSubviews.count == 2 {
            return stack
        }
        for subview in view.subviews {
            if let stack = verticalStack(in: subview) { return stack }
        }
        return nil
    }

    private func isVisible(_ label: UILabel) -> Bool {
        var current: UIView? = label
        while let view = current {
            if view.isHidden { return false }
            current = view.superview
        }
        return true
    }
}
