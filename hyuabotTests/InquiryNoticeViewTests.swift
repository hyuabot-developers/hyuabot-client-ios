//
//  InquiryNoticeViewTests.swift
//  hyuabot
//

import MapKit
import UIKit
import XCTest
@testable import hyuabot

@MainActor
final class InquiryNoticeViewTests: XCTestCase {
    func testTimetableCardBuildsCallout() {
        let view = InquiryTimetableNoticeView()
        view.frame = CGRect(x: 0, y: 0, width: 310, height: 600)
        view.layoutIfNeeded()
        XCTAssertNotNil(find("inquiry.timetable.open", in: view))
        XCTAssertNotNil(find("inquiry.timetable.call", in: view))
        let callout = find("inquiry.timetable.callout.label", in: view) as? UILabel
        XCTAssertNotNil(callout?.attributedText)
        let emphasis = String(localized: "inquiry.timetable.callout.emphasis")
        let full = callout?.attributedText?.string ?? ""
        XCTAssertTrue(full.contains(emphasis))
        let range = (full as NSString).range(of: emphasis)
        let boldFont = callout?.attributedText?.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont
        let regularFont = callout?.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        XCTAssertNotEqual(boldFont, regularFont)
    }

    func testTimetableOpenCallsHandler() {
        let view = InquiryTimetableNoticeView()
        view.frame = CGRect(x: 0, y: 0, width: 310, height: 600)
        view.layoutIfNeeded()
        var opened = false
        view.onOpenTimetable = { opened = true }
        (find("inquiry.timetable.open", in: view) as? UIButton)?.sendActions(for: .touchUpInside)
        XCTAssertTrue(opened)
    }

    func testLostItemCardBuilds() {
        let view = ShuttleLostItemNoticeView()
        view.frame = CGRect(x: 0, y: 0, width: 310, height: 600)
        view.layoutIfNeeded()
        XCTAssertNotNil(find("inquiry.shuttle_lost.open_map", in: view))
        XCTAssertNotNil(find("inquiry.shuttle_lost.call", in: view))
        let map = find("inquiry.shuttle_lost.map_preview", in: view) as? MKMapView
        XCTAssertNotNil(map)
        XCTAssertLessThanOrEqual(abs((map?.region.center.latitude ?? 0) - 37.29275316695924), 0.0005)
        XCTAssertLessThanOrEqual(abs((map?.region.center.longitude ?? 0) - 126.83714484865253), 0.0005)
        let button = find("inquiry.shuttle_lost.open_map", in: view) as? UIButton
        XCTAssertEqual(button?.configuration?.image, UIImage(systemName: "map")?.withConfiguration(
            UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        ))
    }

    func testInquiryMapChoicesStartWithAppleMaps() {
        let choices = InquiryMapChoices.choices(
            name: String(localized: "inquiry.shuttleLost.office"),
            coordinate: CLLocationCoordinate2D(latitude: 37.29275316695924, longitude: 126.83714484865253)
        )
        XCTAssertEqual(choices.first?.name, String(localized: "commuter.map.apple"))
        XCTAssertEqual(choices.first?.symbol, "map.fill")
    }

    private func find(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        for child in view.subviews {
            if let match = find(identifier, in: child) { return match }
        }
        return nil
    }
}
