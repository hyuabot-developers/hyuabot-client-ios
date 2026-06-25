//
//  LanguageManagerTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

final class LanguageManagerTests: XCTestCase {
    private let suggestionShownKey = "languageSuggestionShownV1"
    private let hasLaunchedKey = "appHasLaunched"

    override func setUp() {
        super.setUp()
        resetDefaults()
    }

    override func tearDown() {
        resetDefaults()
        super.tearDown()
    }

    func testIsFirstLaunchOnlyReturnsTrueOnce() {
        XCTAssertTrue(LanguageManager.shared.isFirstLaunch)
        XCTAssertFalse(LanguageManager.shared.isFirstLaunch)
    }

    func testMarkSuggestionShownPersistsFlag() {
        XCTAssertFalse(UserDefaults.standard.bool(forKey: suggestionShownKey))

        LanguageManager.shared.markSuggestionShown()

        XCTAssertTrue(UserDefaults.standard.bool(forKey: suggestionShownKey))
    }

    private func resetDefaults() {
        UserDefaults.standard.removeObject(forKey: suggestionShownKey)
        UserDefaults.standard.removeObject(forKey: hasLaunchedKey)
    }
}
