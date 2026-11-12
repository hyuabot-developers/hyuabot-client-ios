//
//  ContentViewPagerTests.swift
//  hyuabotTests
//

@testable import hyuabot
import UIKit
import XCTest

@MainActor
final class ContentViewPagerTests: XCTestCase {
    func testMoveBeforeLayoutIsApplied() {
        let pager = ContentView(pages: [UIView(), UIView(), UIView()])
        pager.moveToPage(index: 2, animated: false)
        pager.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        pager.layoutIfNeeded()

        XCTAssertEqual(pager.currentIndex, 2)
        let collectionView = pager.subviews.first { $0 is UICollectionView } as? UICollectionView
        XCTAssertEqual(collectionView?.contentOffset.x, 600)
    }

    func testProgrammaticMoveDoesNotNotifyDelegate() {
        let pager = ContentView(pages: [UIView(), UIView(), UIView()])
        pager.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        pager.layoutIfNeeded()
        let spy = DelegateSpy()
        pager.delegate = spy

        pager.moveToPage(index: 1)

        XCTAssertEqual(spy.callCount, 0)
    }

    func testBackgroundIsClear() {
        let pager = ContentView()

        XCTAssertEqual(pager.backgroundColor, .clear)
        let collectionView = pager.subviews.first { $0 is UICollectionView } as? UICollectionView
        XCTAssertEqual(collectionView?.backgroundColor, .clear)
    }

    private final class DelegateSpy: ContentViewDelegate {
        var callCount = 0

        func didMoveToPage(index: Int) {
            callCount += 1
        }
    }
}
