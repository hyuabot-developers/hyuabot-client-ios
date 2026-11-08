//
//  SnapshotSmokeTests.swift
//  hyuabotTests
//

@testable import hyuabot
import SnapshotTesting
import UIKit
import XCTest

@MainActor
final class SnapshotSmokeTests: XCTestCase {
    func testReadingRoomEmptyCellSnapshot() {
        let cell = ReadingRoomSkeletonCellView(style: .default, reuseIdentifier: ReadingRoomSkeletonCellView.reuseIdentifier)
        cell.configure(index: 0, isFirst: true, isLast: true)
        cell.frame = CGRect(x: 0, y: 0, width: 390, height: 82)
        cell.backgroundColor = SettingsStyle.Color.background
        cell.overrideUserInterfaceStyle = .dark

        assertSnapshot(of: cell, as: .image(size: cell.frame.size, traits: darkTraits), record: .missing, timeout: 5)
    }

    func testCafeteriaMenuCardSnapshot() {
        let card = CafeteriaMenuCardView()
        card.configure(CafeteriaCardModel(
            seq: 13,
            name: "Dormitory Cafeteria",
            timeText: "11:30–13:20",
            status: .open,
            rows: [
                CafeteriaMenuRowModel(tag: "Breakfast", main: "Beef seaweed soup", sides: "Rice · Salad · Kimchi", price: "1,000"),
                CafeteriaMenuRowModel(tag: nil, main: "Pork cutlet bowl", sides: "Udon broth · Pickles", price: "4,500")
            ]
        ))
        let fittingSize = card.systemLayoutSizeFitting(CGSize(width: 358, height: UIView.layoutFittingCompressedSize.height))
        card.frame = CGRect(origin: .zero, size: fittingSize)
        card.overrideUserInterfaceStyle = .dark

        assertSnapshot(of: card, as: .image(size: card.frame.size, traits: darkTraits), record: .missing, timeout: 5)
    }

    private var darkTraits: UITraitCollection {
        UITraitCollection(mutations: { traits in
            traits.displayScale = 3
            traits.userInterfaceStyle = .dark
        })
    }
}
