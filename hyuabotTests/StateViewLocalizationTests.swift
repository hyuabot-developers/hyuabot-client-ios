//
//  StateViewLocalizationTests.swift
//  hyuabotTests
//

import XCTest

/// Validates the `state.*` String Catalog entries used by `StateView`.
///
/// `LocalizationCatalogTests` only checks entries marked `extractionState == "manual"`,
/// and these keys are not marked that way, so they are validated here instead.
final class StateViewLocalizationTests: XCTestCase {
    private let requiredLanguages = ["ko", "en", "ja", "zh-Hans"]
    private let expectedKeys: Set<String> = [
        "state.action.full_timetable",
        "state.action.open_settings",
        "state.action.retry",
        "state.empty.title",
        "state.ended.title",
        "state.error.title",
        "state.permission_denied.title",
        "state.suspended.title"
    ]

    func testStateCatalogContainsExpectedKeys() throws {
        let strings = try stateStrings()
        XCTAssertEqual(Set(strings.keys), expectedKeys)
    }

    func testStateCatalogEntriesHaveNonEmptyValuesForAllLanguages() throws {
        let strings = try stateStrings()
        for key in expectedKeys {
            let localizations = try XCTUnwrap(strings[key]?["localizations"] as? [String: Any], "\(key) has no localizations")
            for language in requiredLanguages {
                let unit = try XCTUnwrap(
                    (localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any],
                    "\(key) is missing a stringUnit for \(language)"
                )
                let value = try XCTUnwrap(unit["value"] as? String, "\(key) has no value for \(language)")
                XCTAssertFalse(
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "\(key) has an empty value for \(language)"
                )
            }
        }
    }

    private func stateStrings() throws -> [String: [String: Any]] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hyuabot/Localization/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        return try strings.reduce(into: [:]) { result, entry in
            guard entry.key.hasPrefix("state.") else { return }
            result[entry.key] = try XCTUnwrap(entry.value as? [String: Any])
        }
    }
}
