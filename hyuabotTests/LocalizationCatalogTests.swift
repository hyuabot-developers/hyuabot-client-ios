//
//  LocalizationCatalogTests.swift
//  hyuabotTests
//

import XCTest

final class LocalizationCatalogTests: XCTestCase {
    private let requiredLanguages = ["ko", "en", "ja", "zh-Hans"]

    func testLocalizableCatalogHasRequiredLanguagesForManualTranslations() throws {
        let catalog = try loadCatalog(named: "Localizable.xcstrings")
        try assertRequiredLanguages(in: catalog, file: "Localizable.xcstrings")
    }

    func testInfoPlistCatalogHasRequiredLanguagesForManualTranslations() throws {
        let catalog = try loadCatalog(named: "InfoPlist.xcstrings")
        try assertRequiredLanguages(in: catalog, file: "InfoPlist.xcstrings")
    }

    private func loadCatalog(named name: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hyuabot/Localization/\(name)")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func assertRequiredLanguages(in catalog: [String: Any], file: String) throws {
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        for (key, rawValue) in strings {
            let value = try XCTUnwrap(rawValue as? [String: Any])
            guard value["shouldTranslate"] as? Bool != false else { continue }
            guard value["extractionState"] as? String == "manual" else { continue }
            guard let localizations = value["localizations"] as? [String: Any] else { continue }
            for language in requiredLanguages {
                XCTAssertNotNil(localizations[language], "\(file) is missing \(language) for \(key)")
            }
        }
    }
}
