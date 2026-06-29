//
//  AppleTranslationDeviceTests.swift
//  hyuabotTests
//

@testable import hyuabot
import Translation
import XCTest

@MainActor
final class AppleTranslationDeviceTests: XCTestCase {
    func testKoreanTextTranslatorTranslatesToEnglishOnIOS26() async throws {
        try await assertTranslation(languageCode: "en-US", languageIdentifier: "en")
    }

    func testKoreanTextTranslatorTranslatesToJapaneseOnIOS26() async throws {
        try await assertTranslation(languageCode: "ja-JP", languageIdentifier: "ja")
    }

    func testKoreanTextTranslatorTranslatesToSimplifiedChineseOnIOS26() async throws {
        try await assertTranslation(languageCode: "zh-Hans", languageIdentifier: "zh")
    }

    private func assertTranslation(languageCode: String, languageIdentifier: String) async throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Apple Translation is only enabled on iOS 26 or later.")
        }

        let source = "학생지원팀"
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        let status = await LanguageAvailability().status(
            from: Locale.Language(identifier: "ko"),
            to: Locale.Language(identifier: languageIdentifier)
        )
        XCTContext.runActivity(named: "Apple Translation status ko -> \(languageCode): \(status)") { _ in }
        guard status == .installed else {
            throw XCTSkip("Apple Translation model is \(status) for ko -> \(languageCode) on this device.")
        }

        XCTAssertTrue(KoreanTextTranslator.shared.shouldTranslateKorean)

        let translated = await KoreanTextTranslator.shared.translate(source)

        XCTAssertNotEqual(translated, source, "Expected \(source) to translate for \(languageCode).")
        XCTAssertNil(translated.range(of: #"\p{Hangul}"#, options: .regularExpression))
        XCTAssertFalse(translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
