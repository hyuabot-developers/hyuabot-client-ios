//
//  DependencyAdapterTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class DependencyAdapterTests: XCTestCase {
    func testMockDefaultsStoreCanDriveSettingsLogic() {
        let defaults = MockDefaultsStore()

        defaults.set(SettingsLogic.themeID(for: "theme.dark"), forKey: "themeID")
        defaults.set(SettingsLogic.campusID(for: "campus.seoul"), forKey: "campusID")

        XCTAssertEqual(defaults.integer(forKey: "themeID"), 2)
        XCTAssertEqual(defaults.integer(forKey: "campusID"), 1)
    }

    func testClockCanBeInjected() {
        let fixedDate = Date(timeIntervalSince1970: 1_767_225_600)
        let clock = FixedClock(now: fixedDate)

        XCTAssertEqual(clock.now, fixedDate)
    }
}

private final class MockDefaultsStore: UserDefaultsStoring {
    private var storage: [String: Any] = [:]

    func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    func stringArray(forKey defaultName: String) -> [String]? {
        storage[defaultName] as? [String]
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
}

private struct FixedClock: Clock {
    let now: Date
}
