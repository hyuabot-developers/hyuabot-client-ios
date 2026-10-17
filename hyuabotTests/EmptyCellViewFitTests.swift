//
//  EmptyCellViewFitTests.swift
//  hyuabot
//

@testable import hyuabot
import UIKit
import XCTest

/// Checks that the StateView inside each *EmptyCellView fits within the cell at normal and AX5 text sizes.
/// Sizing is measured with systemLayoutSizeFitting at a fixed 390pt width.
@MainActor
final class EmptyCellViewFitTests: XCTestCase {
    private let width: CGFloat = 390
    private let message = "표시할 항목이 없습니다."

    func testShuttleRealtimeEmptyCellFitsContent() {
        let cell = ShuttleRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    func testBusRealtimeEmptyCellFitsContent() {
        let cell = BusRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    func testBusTimetableEmptyCellFitsContent() {
        let cell = BusTimetableEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    func testContactSearchEmptyCellFitsContent() {
        let cell = ContactSearchEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    func testMapSearchEmptyCellFitsContent() {
        let cell = SearchEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    func testShuttleTimetableEmptyCellFitsContent() {
        let cell = ShuttleTimetableEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    func testSubwayRealtimeEmptyCellFitsContent() {
        let cell = SubwayRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        assertFitsContent(cell) { cell.configure($0) }
    }

    private func assertFitsContent(
        _ cell: UITableViewCell,
        configure: (StateContent) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        configure(.empty(message: message))
        let categories: [UIContentSizeCategory] = [.large, .accessibilityExtraExtraExtraLarge]

        for category in categories {
            cell.traitOverrides.preferredContentSizeCategory = category
            let cellFit = fittingSize(of: cell)
            cell.frame = CGRect(origin: .zero, size: CGSize(width: width, height: cellFit.height))
            cell.layoutIfNeeded()

            guard let stateView = cell.contentView.subviews.compactMap({ $0 as? StateView }).first else {
                XCTFail("StateView is not hosted in the cell's contentView (\(category.rawValue))", file: file, line: line)
                return
            }
            let stateFit = fittingSize(of: stateView)

            XCTAssertGreaterThan(cellFit.height, 0, "Cell height is zero (\(category.rawValue))", file: file, line: line)
            XCTAssertGreaterThanOrEqual(
                cellFit.height,
                stateFit.height,
                "Cell is shorter than StateView content (\(category.rawValue))",
                file: file,
                line: line
            )
            XCTAssertTrue(
                cell.contentView.bounds.contains(stateView.frame),
                "StateView is clipped by the cell (\(category.rawValue))",
                file: file,
                line: line
            )

            guard let unavailable = stateView.subviews.first(where: { $0 is UIContentUnavailableView }) else {
                XCTFail("UIContentUnavailableView is missing (\(category.rawValue))", file: file, line: line)
                return
            }
            XCTAssertTrue(
                stateView.bounds.contains(unavailable.frame),
                "UIContentUnavailableView content is clipped by StateView (\(category.rawValue))",
                file: file,
                line: line
            )
        }
    }

    func testLongestLocalizedStateTextFitsAtAccessibilityExtraExtraExtraLarge() throws {
        let cell = ShuttleRealtimeEmptyCellView(style: .default, reuseIdentifier: nil)
        let longest = try longestKoStateText()
        // Repeat the longest catalog string so the message wraps onto several lines at AX5.
        let message = Array(repeating: longest, count: 3).joined(separator: " ")
        cell.configure(.empty(message: message, action: StateAction(title: longest, handler: {})))
        cell.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge

        let cellFit = fittingSize(of: cell)
        cell.frame = CGRect(origin: .zero, size: CGSize(width: width, height: cellFit.height))
        cell.layoutIfNeeded()

        let stateView = try XCTUnwrap(cell.contentView.subviews.compactMap { $0 as? StateView }.first)
        stateView.layoutIfNeeded()
        let stateFit = fittingSize(of: stateView)

        XCTAssertGreaterThanOrEqual(
            cellFit.height,
            stateFit.height,
            "Cell is shorter than StateView content at AX5 with long text"
        )
        let wrappingLabels = labels(in: stateView).filter { $0.numberOfLines == 0 }
        XCTAssertFalse(wrappingLabels.isEmpty, "No wrapping labels found in StateView; truncation check would be vacuous")
        for label in wrappingLabels {
            let frame = label.convert(label.bounds, to: stateView)
            XCTAssertTrue(
                stateView.bounds.insetBy(dx: -0.5, dy: -0.5).contains(frame),
                "Label frame \(frame) is outside StateView bounds \(stateView.bounds) at AX5"
            )
            let requiredHeight = label.sizeThatFits(
                CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)
            ).height
            XCTAssertLessThanOrEqual(
                requiredHeight,
                label.bounds.height + 1,
                "Label text is clipped at AX5: needs \(requiredHeight), has \(label.bounds.height)"
            )
        }
    }

    /// Longest `ko` value among the `state.*` catalog entries, read from the same
    /// Localizable.xcstrings file that the app ships.
    private func longestKoStateText() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hyuabot/Localization/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        let koValues: [String] = strings.keys.sorted().compactMap { key in
            guard key.hasPrefix("state."),
                  let entry = strings[key] as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any],
                  let ko = localizations["ko"] as? [String: Any],
                  let unit = ko["stringUnit"] as? [String: Any],
                  let value = unit["value"] as? String else { return nil }
            return value
        }
        return try XCTUnwrap(koValues.max { $0.count < $1.count })
    }

    private func labels(in view: UIView) -> [UILabel] {
        var found: [UILabel] = []
        for subview in view.subviews {
            if let label = subview as? UILabel {
                found.append(label)
            }
            found += labels(in: subview)
        }
        return found
    }

    private func fittingSize(of view: UIView) -> CGSize {
        view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
