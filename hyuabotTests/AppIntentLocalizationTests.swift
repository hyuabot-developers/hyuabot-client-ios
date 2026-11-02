//
//  AppIntentLocalizationTests.swift
//  hyuabotTests
//

import XCTest

final class AppIntentLocalizationTests: XCTestCase {
    private static let intentKeys: [String] = [
        "intent.common.error",
        "intent.common.minutes.later",
        "intent.common.realtime",
        "intent.common.scheduled",
        "intent.shuttle.title",
        "intent.shuttle.description",
        "intent.shuttle.parameter.stop",
        "intent.shuttle.stop.type",
        "intent.shuttle.short.title",
        "intent.shuttle.snippet.title.all",
        "intent.shuttle.destination.station",
        "intent.shuttle.destination.terminal",
        "intent.shuttle.destination.campus",
        "intent.shuttle.destination.jungang",
        "intent.shuttle.dialog.next",
        "intent.shuttle.dialog.none",
        "intent.cafeteria.title",
        "intent.cafeteria.description",
        "intent.cafeteria.parameter.meal",
        "intent.cafeteria.parameter.day",
        "intent.cafeteria.meal.type",
        "intent.cafeteria.day.type",
        "intent.cafeteria.day.today",
        "intent.cafeteria.day.tomorrow",
        "intent.cafeteria.short.title",
        "intent.cafeteria.dialog.menu",
        "intent.cafeteria.dialog.none",
        "intent.subway.title",
        "intent.subway.description",
        "intent.subway.parameter.line",
        "intent.subway.line.type",
        "intent.subway.line.line4",
        "intent.subway.line.suin",
        "intent.subway.direction.up",
        "intent.subway.direction.down",
        "intent.subway.terminal",
        "intent.subway.short.title",
        "intent.subway.dialog.next",
        "intent.subway.dialog.none",
        "intent.bus.title",
        "intent.bus.description",
        "intent.bus.parameter.route",
        "intent.bus.route.type",
        "intent.bus.stops.left",
        "intent.bus.departure.time",
        "intent.bus.short.title",
        "intent.bus.dialog.next",
        "intent.bus.dialog.scheduled",
        "intent.bus.dialog.none",
        "intent.shuttle.intent.title",
        "intent.shuttle.parameter.direction",
        "intent.shuttle.direction.type",
        "intent.shuttle.direction.to.campus",
        "intent.shuttle.direction.from.campus",
        "intent.shuttle.nearest",
        "intent.shuttle.location.hint",
        "intent.shuttle.location.unavailable",
        "intent.shuttle.location.far",
        "intent.cafeteria.intent.title",
        "intent.cafeteria.parameter.restaurant",
        "intent.cafeteria.restaurant.type",
        "intent.cafeteria.dialog.none.restaurant",
        "intent.subway.intent.title",
        "intent.subway.parameter.direction",
        "intent.subway.direction.type",
        "intent.bus.intent.title",
        "intent.bus.route.10-1",
        "intent.bus.route.3102",
        "intent.bus.route.3100",
        "intent.bus.route.3101",
        "intent.bus.route.3100N",
        "intent.bus.route.7070",
        "intent.bus.route.9090",
        "shuttle.stop.dormitory.out",
        "shuttle.stop.shuttlecock.out",
        "shuttle.stop.station",
        "shuttle.stop.terminal",
        "shuttle.stop.jungang.station",
        "shuttle.stop.shuttlecock.in",
        "cafeteria.breakfast",
        "cafeteria.lunch",
        "cafeteria.dinner",
        "cafeteria.no.data",
        "cafeteria.title.1",
        "cafeteria.title.2",
        "cafeteria.title.4",
        "cafeteria.title.6",
        "cafeteria.title.7",
        "cafeteria.title.8",
        "cafeteria.title.11",
        "cafeteria.title.12",
        "cafeteria.title.13",
        "cafeteria.title.14",
        "cafeteria.title.15",
        "intent.entity.cafeteria.type",
        "intent.entity.shuttle.type",
        "intent.entity.subway.type",
        "intent.entity.bus.type",
        "intent.open.bus.title",
        "intent.open.cafeteria.title",
        "intent.open.shuttle.title",
        "intent.open.subway.title",
        "intent.search.title",
    ]

    func testIntentKeysHaveAllLanguages() throws {
        let catalog = try loadCatalog(named: "Localizable.xcstrings")
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        for key in Self.intentKeys {
            for language in ["ko", "en", "ja", "zh-Hans"] {
                XCTAssertFalse((value(strings, key: key, language: language) ?? "").isEmpty, "\(key) \(language)")
            }
        }
    }

    func testFormatSpecifiersMatchAcrossLanguages() throws {
        let catalog = try loadCatalog(named: "Localizable.xcstrings")
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        for key in Self.intentKeys {
            let korean = try XCTUnwrap(value(strings, key: key, language: "ko"))
            let expected = formatSpecifiers(in: korean)
            if !expected.isEmpty { XCTAssertFalse(expected.isEmpty) }
            for language in ["en", "ja", "zh-Hans"] {
                let localized = try XCTUnwrap(value(strings, key: key, language: language))
                XCTAssertEqual(expected, formatSpecifiers(in: localized), "\(key) \(language)")
            }
        }
    }

    func testAppShortcutPhrasesKeepPlaceholders() throws {
        let catalog = try loadCatalog(named: "AppShortcuts.xcstrings")
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        XCTAssertEqual(strings.count, 29)
        for key in strings.keys {
            XCTAssertTrue(key.contains("${applicationName}"), key)
            let expected = placeholders(in: key)
            for language in ["ko", "en", "ja", "zh-Hans"] {
                let localized = try XCTUnwrap(value(strings, key: key, language: language))
                XCTAssertEqual(expected, placeholders(in: localized), "\(key) \(language)")
            }
        }
    }

    private func loadCatalog(named name: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("hyuabot/Localization/\(name)")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func value(_ strings: [String: Any], key: String, language: String) -> String? {
        let entry = strings[key] as? [String: Any]
        let localizations = entry?["localizations"] as? [String: Any]
        let localization = localizations?[language] as? [String: Any]
        let stringUnit = localization?["stringUnit"] as? [String: Any]
        return stringUnit?["value"] as? String
    }

    private func formatSpecifiers(in value: String) -> [String] {
        matches(in: value, pattern: "%(\\d+\\$)?@").sorted()
    }

    private func placeholders(in value: String) -> Set<String> {
        Set(matches(in: value, pattern: "\\$\\{[A-Za-z]+\\}"))
    }

    private func matches(in value: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(value.startIndex..., in: value)
        return regex.matches(in: value, range: range).compactMap { Range($0.range, in: value).map { String(value[$0]) } }
    }
}
