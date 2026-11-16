//
//  BusRealtimeLayoutTests.swift
//  hyuabot
//

import XCTest
@testable import hyuabot

private struct SectionExpectation: Equatable {
    let stopID: Int32
    let routes: [Int32]
    let destinationStopID: Int32?
}

private func expectations(_ specs: [BusRealtimeSectionSpec]) -> [SectionExpectation] {
    specs.map { SectionExpectation(stopID: $0.stopID, routes: $0.routes, destinationStopID: $0.destinationStopID) }
}

private func sectionExpectation(_ stopID: Int32, _ routes: [Int32], _ destinationStopID: Int32?) -> SectionExpectation {
    SectionExpectation(stopID: stopID, routes: routes, destinationStopID: destinationStopID)
}

private struct GroupTabExpectation {
    let group: BusLocationGroup
    let tab: BusRealtimeType
    let sections: [SectionExpectation]
}

private let customGroupTabExpectations: [GroupTabExpectation] = [
        .init(group: .seocho, tab: .seoul, sections: [
            sectionExpectation(121_000_060, [216_000_061], 216_000_378),
            sectionExpectation(121_000_060, [216_000_026, 216_000_043, 216_000_096], 216_000_048)
        ]),
        .init(group: .yangjae, tab: .seoul, sections: [
            sectionExpectation(121_000_970, [216_000_061], 216_000_378),
            sectionExpectation(121_000_970, [216_000_026, 216_000_043, 216_000_096], 216_000_048)
        ]),
        .init(group: .gyodae, tab: .seoul, sections: [
            sectionExpectation(121_000_929, [216_000_061], 216_000_378),
            sectionExpectation(121_000_929, [216_000_026, 216_000_043, 216_000_096], 216_000_048)
        ]),
        .init(group: .gangnam, tab: .seoul, sections: [
            sectionExpectation(121_000_974, [216_000_061], 216_000_378),
            sectionExpectation(121_000_974, [216_000_026, 216_000_043, 216_000_096], 216_000_048)
        ]),
        .init(group: .yangjaeForest, tab: .seoul, sections: [
            sectionExpectation(121_000_220, [216_000_061], 216_000_378),
            sectionExpectation(121_000_220, [216_000_026, 216_000_043, 216_000_096], 216_000_048)
        ]),
        .init(group: .suwonStation, tab: .suwon, sections: [
            sectionExpectation(202_000_106, [216_000_104, 200_000_015], 216_000_141)
        ]),
        .init(group: .uiwangTollgate, tab: .seoul, sections: [
            sectionExpectation(226_000_038, [216_000_061], 216_000_378),
            sectionExpectation(226_000_038, [216_000_026, 216_000_096], 216_000_048)
        ]),
        .init(group: .artist, tab: .city, sections: [
            sectionExpectation(216_000_759, [216_000_075], 213_000_487),
            sectionExpectation(216_000_074, [216_000_016], nil),
            sectionExpectation(216_000_077, [216_000_082], nil)
        ]),
        .init(group: .jungang, tab: .city, sections: [
            sectionExpectation(217_000_264, [216_000_016], nil),
            sectionExpectation(217_000_140, [216_000_082], nil)
        ]),
        .init(group: .campus, tab: .city, sections: [
            sectionExpectation(216_000_379, [216_000_068], 216_000_138),
            sectionExpectation(216_000_152, [216_000_016], nil)
        ]),
        .init(group: .sangnoksuHandae, tab: .city, sections: [
            sectionExpectation(216_000_138, [216_000_068], 216_000_378),
            sectionExpectation(216_000_722, [216_000_049], 216_000_691)
        ]),
        .init(group: .kitech, tab: .city, sections: [
            sectionExpectation(216_000_381, [216_000_068], 216_000_138),
            sectionExpectation(216_000_691, [216_000_049], nil)
        ]),
        .init(group: .kitech, tab: .seoul, sections: [
            sectionExpectation(216_000_381, [216_000_061], 121_000_974),
            sectionExpectation(216_000_719, [216_000_026, 216_000_043, 216_000_096], 121_000_974)
        ]),
        .init(group: .dormitory, tab: .city, sections: [
            sectionExpectation(216_000_383, [216_000_068], 216_000_138),
            sectionExpectation(216_000_028, [216_000_081], nil)
        ]),
        .init(group: .dormitory, tab: .seoul, sections: [
            sectionExpectation(216_000_383, [216_000_061], 121_000_974),
            sectionExpectation(216_000_719, [216_000_026, 216_000_043, 216_000_096], 121_000_974)
        ]),
        .init(group: .gwangmyeong, tab: .city, sections: [
            sectionExpectation(213_000_487, [216_000_075], 216_000_117)
        ])
]

final class BusRealtimeLayoutTests: XCTestCase {

    func testDefaultLayout() {
        let layout = BusRealtimeLayout.layout(for: nil, seoulTarget: .gangnam)
        XCTAssertEqual(layout.defaultTab, .city)
        XCTAssertEqual(expectations(layout.city), [
            sectionExpectation(216_000_379, [216_000_068], 216_000_138),
            sectionExpectation(216_000_138, [216_000_068], 216_000_378)
        ])
        XCTAssertEqual(expectations(layout.seoul), [
            sectionExpectation(216_000_379, [216_000_061], 121_000_974),
            sectionExpectation(216_000_719, [216_000_026, 216_000_043, 216_000_096], 121_000_974)
        ])
        XCTAssertEqual(expectations(layout.suwon), [
            sectionExpectation(216_000_070, [216_000_104, 200_000_015], 202_000_208)
        ])
    }

    func testGroupDefaultTabsAndUncustomizedTabs() {
        let base = BusRealtimeLayout.layout(for: nil, seoulTarget: .gangnam)
        for group in BusLocationGroup.allCases {
            let layout = BusRealtimeLayout.layout(for: group, seoulTarget: .gangnam)
            switch group {
            case .seocho, .yangjae, .gyodae, .gangnam, .yangjaeForest, .uiwangTollgate:
                XCTAssertEqual(layout.defaultTab, .seoul)
                XCTAssertEqual(expectations(layout.city), expectations(base.city))
                XCTAssertEqual(expectations(layout.suwon), expectations(base.suwon))
            case .suwonStation:
                XCTAssertEqual(layout.defaultTab, .suwon)
                XCTAssertEqual(expectations(layout.city), expectations(base.city))
                XCTAssertEqual(expectations(layout.seoul), expectations(base.seoul))
            default:
                XCTAssertEqual(layout.defaultTab, .city)
                XCTAssertEqual(expectations(layout.suwon), expectations(base.suwon))
            }
        }
    }

    func testCustomGroupSectionStops() {
        let custom = customGroupTabExpectations
        let base = BusRealtimeLayout.layout(for: nil, seoulTarget: .gangnam)
        for expectation in custom {
            let group = expectation.group
            let tab = expectation.tab
            let layout = BusRealtimeLayout.layout(for: group, seoulTarget: .gangnam)
            XCTAssertEqual(expectations(layout.sections(for: expectation.tab)), expectation.sections, "\(group) \(expectation.tab)")
            let customizedTabs = custom.filter { $0.group == group }.map(\.tab)
            for other in [BusRealtimeType.city, .seoul, .suwon] where !customizedTabs.contains(other) {
                XCTAssertEqual(layout.sections(for: other), base.sections(for: other), "\(group) \(other)")
            }
        }
    }

    func testUiwangExcludes3101() {
        let layout = BusRealtimeLayout.layout(for: .uiwangTollgate, seoulTarget: .gangnam)
        XCTAssertFalse(layout.allSections.contains { $0.stopID == 226_000_038 && $0.routes.contains(216_000_043) })
    }

    func testNoLayoutHasEmptyTabs() {
        XCTAssertFalse(BusRealtimeLayout.layout(for: nil, seoulTarget: .gangnam).allSections.isEmpty)
        for group in BusLocationGroup.allCases {
            XCTAssertFalse(BusRealtimeLayout.layout(for: group, seoulTarget: .gangnam).allSections.isEmpty)
        }
    }

    func testSeoulTargetFeedsCampusDestinations() {
        XCTAssertEqual(BusRealtimeLayout.layout(for: nil, seoulTarget: .seocho).seoul[0].destinationStopID, 121_000_060)
    }

    func testLocatedEventReplacesGroup() {
        let locatedGroup = BusLocationGroupEvent.located(.kitech).nextGroup(current: .campus)
        XCTAssertEqual(locatedGroup, .kitech)
        XCTAssertNil(BusLocationGroupEvent.located(nil).nextGroup(current: .campus))
    }

    func testAuthorizationUnavailableFallsBackToDefault() {
        XCTAssertNil(BusLocationGroupEvent.authorizationUnavailable.nextGroup(current: .gangnam))
    }

    func testTransientFailureKeepsGroup() {
        let retainedGroup = BusLocationGroupEvent.locationFailed(isTransient: true)
            .nextGroup(current: .suwonStation)
        XCTAssertEqual(retainedGroup, .suwonStation)
    }

    func testPermanentFailureFallsBackToDefault() {
        XCTAssertNil(BusLocationGroupEvent.locationFailed(isTransient: false).nextGroup(current: .suwonStation))
    }

    func testRevokeAndRestoreSequence() {
        var current: BusLocationGroup?
        current = BusLocationGroupEvent.located(.gangnam).nextGroup(current: current)
        XCTAssertEqual(BusRealtimeLayout.layout(for: current, seoulTarget: .gangnam).defaultTab, .seoul)
        current = BusLocationGroupEvent.authorizationUnavailable.nextGroup(current: current)
        XCTAssertNil(current)
        let currentLayout = BusRealtimeLayout.layout(for: current, seoulTarget: .gangnam)
        let defaultLayout = BusRealtimeLayout.layout(for: nil, seoulTarget: .gangnam)
        XCTAssertEqual(currentLayout, defaultLayout)
        current = BusLocationGroupEvent.located(.gangnam).nextGroup(current: current)
        XCTAssertEqual(BusRealtimeLayout.layout(for: current, seoulTarget: .gangnam).defaultTab, .seoul)
    }
}
