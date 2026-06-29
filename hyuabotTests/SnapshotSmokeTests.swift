//
//  SnapshotSmokeTests.swift
//  hyuabotTests
//

@testable import hyuabot
import SnapshotTesting
import UIKit
import XCTest

final class SnapshotSmokeTests: XCTestCase {
    func testReadingRoomEmptyCellSnapshot() {
        let cell = ReadingRoomSkeletonCellView(style: .default, reuseIdentifier: ReadingRoomSkeletonCellView.reuseIdentifier)
        cell.frame = CGRect(x: 0, y: 0, width: 390, height: 96)
        cell.contentView.backgroundColor = .systemBackground
        cell.overrideUserInterfaceStyle = .dark

        assertSnapshot(of: cell, as: .image(size: cell.frame.size, traits: darkTraits), record: .missing, timeout: 5)
    }

    func testCafeteriaHeaderSnapshot() {
        let header = CafeteriaHeaderView(reuseIdentifier: CafeteriaHeaderView.reuseIdentifier)
        header.frame = CGRect(x: 0, y: 0, width: 390, height: 72)
        header.overrideUserInterfaceStyle = .dark
        header.setupUI(id: 1, runningTime: "00:00 ~ 23:59", hasMenu: true, showCafeteriaInfoVC: {})
        setHeaderSnapshotText(in: header)

        assertSnapshot(of: header, as: .image(size: header.frame.size, traits: darkTraits), record: .missing, timeout: 5)
    }

    private var darkTraits: UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(displayScale: 3),
            UITraitCollection(userInterfaceStyle: .dark)
        ])
    }

    private func setHeaderSnapshotText(in view: UIView) {
        let labels = findLabels(in: view).sorted { first, second in
            if first.frame.minY == second.frame.minY {
                first.frame.minX < second.frame.minX
            } else {
                first.frame.minY < second.frame.minY
            }
        }
        labels.first?.text = "Student Cafeteria"
        labels.dropFirst().first?.text = "Running Time: 00:00 ~ 23:59 \u{00B7} Open now"
    }

    private func findLabels(in view: UIView) -> [UILabel] {
        let current = (view as? UILabel).map { [$0] } ?? []
        return view.subviews.reduce(current) { result, subview in
            result + findLabels(in: subview)
        }
    }
}
