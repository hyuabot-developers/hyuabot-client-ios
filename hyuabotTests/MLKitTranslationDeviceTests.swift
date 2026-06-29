//
//  MLKitTranslationDeviceTests.swift
//  hyuabotTests
//

@testable import hyuabot
import XCTest

@MainActor
final class MLKitTranslationDeviceTests: XCTestCase {
    func testKoreanTextTranslatorDownloadsModelAndTranslatesOnDevice() async throws {
        #if targetEnvironment(simulator)
            throw XCTSkip("ML Kit translation is disabled on simulator.")
        #else
            let source = "학생지원팀"
            for languageCode in ["en-US", "ja-JP", "zh-Hans"] {
                UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
                UserDefaults.standard.synchronize()

                XCTAssertTrue(
                    KoreanTextTranslator.shared.currentLanguageCode.lowercased().hasPrefix(languageCode.prefix(2).lowercased()),
                    "Expected \(languageCode), got \(KoreanTextTranslator.shared.currentLanguageCode)."
                )
                XCTAssertTrue(KoreanTextTranslator.shared.shouldTranslateKorean)

                let translated = await KoreanTextTranslator.shared.translate(source)

                XCTAssertNotEqual(translated, source)
                XCTAssertNil(translated.range(of: #"\p{Hangul}"#, options: .regularExpression))
                XCTAssertFalse(translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        #endif
    }
}
