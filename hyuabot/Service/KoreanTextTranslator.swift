//
//  KoreanTextTranslator.swift
//  hyuabot
//

import Foundation
import OSLog
@preconcurrency import Translation
import UIKit

@MainActor
final class KoreanTextTranslator {
    static let shared = KoreanTextTranslator()

    private let cacheKey = "koreanTextTranslationCacheV2"
    private let translatedDataLanguageKey = "translatedDataLanguageV1"
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "net.jaram.hyuabot",
        category: "KoreanTextTranslator"
    )
    private var memoryCache: [String: String]
    private var unsupportedTargetLanguageIDs: Set<String> = []

    private init() {
        memoryCache = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: String] ?? [:]
    }

    var currentLanguageCode: String {
        Locale.preferredLanguages.first
            ?? Bundle.main.preferredLocalizations.first
            ?? Locale.current.language.languageCode?.identifier
            ?? "ko"
    }

    var shouldTranslateKorean: Bool {
        if #available(iOS 26.0, *) {
            targetLanguage != nil
        } else {
            false
        }
    }

    func prepareForCurrentLanguage() {
        if #available(iOS 26.0, *) {
            guard let targetLanguage else {
                debugLog("Skipping model download for language: \(currentLanguageCode)")
                return
            }
            guard !isUnsupportedTargetLanguage(targetLanguage) else {
                debugLog("Skipping model download for unsupported language: \(currentLanguageCode)")
                return
            }

            Task {
                switch await translationAvailabilityStatus(to: targetLanguage) {
                case .installed:
                    do {
                        let session = translationSession(for: targetLanguage)
                        try await session.prepareTranslation()
                        debugLog("Translation model is ready for language: \(currentLanguageCode)")
                    } catch {
                        markUnsupportedTargetLanguage(targetLanguage)
                        debugLog("Translation model preparation failed for language: \(currentLanguageCode), error: \(error)")
                    }
                case .supported:
                    debugLog("Translation model is supported but not installed for language: \(currentLanguageCode)")
                case .unsupported:
                    markUnsupportedTargetLanguage(targetLanguage)
                    debugLog("Translation model is unsupported for language: \(currentLanguageCode)")
                @unknown default:
                    debugLog("Unknown translation availability for language: \(currentLanguageCode)")
                }
            }
        } else {
            debugLog("Skipping translation model download on iOS versions earlier than 26.0")
        }
    }

    @available(iOS 26.0, *)
    func translationPreparationConfiguration() async -> TranslationSession.Configuration? {
        guard let targetLanguage else { return nil }
        let availability = LanguageAvailability()
        let status = await availability.status(from: Locale.Language(identifier: "ko"), to: targetLanguage)
        guard status == .supported else { return nil }
        return TranslationSession.Configuration(
            source: Locale.Language(identifier: "ko"),
            target: targetLanguage
        )
    }

    @available(iOS 26.0, *)
    func didPrepareTranslation(for configuration: TranslationSession.Configuration) {
        if let target = configuration.target {
            unsupportedTargetLanguageIDs.remove(target.minimalIdentifier)
        }
    }

    func invalidateStoredDataIfLanguageChanged() {
        let language = currentLanguageCode
        let previous = UserDefaults.standard.string(forKey: translatedDataLanguageKey)
        if previous == nil {
            if shouldTranslateKorean {
                clearTranslatedStoredData()
            }
            UserDefaults.standard.set(language, forKey: translatedDataLanguageKey)
            return
        }
        guard previous != language else { return }

        clearTranslatedStoredData()
        UserDefaults.standard.set(language, forKey: translatedDataLanguageKey)
    }

    func translate(_ text: String) async -> String {
        guard #available(iOS 26.0, *) else {
            return text
        }

        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard shouldTranslate(cleaned), let targetLanguage else { return text }
        guard !isUnsupportedTargetLanguage(targetLanguage) else { return text }

        let key = cacheKey(for: cleaned)
        if let cached = memoryCache[key] {
            return cached
        }

        switch await translationAvailabilityStatus(to: targetLanguage) {
        case .installed:
            do {
                let session = translationSession(for: targetLanguage)
                try await session.prepareTranslation()
                let translated = try await session.translate(cleaned).targetText
                let final = translated.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !final.isEmpty else { return text }
                memoryCache[key] = final
                UserDefaults.standard.set(memoryCache, forKey: cacheKey)
                return final
            } catch {
                markUnsupportedTargetLanguage(targetLanguage)
                debugLog("Translation failed for language: \(currentLanguageCode), text: \(cleaned), error: \(error)")
                return text
            }
        case .supported:
            return text
        case .unsupported:
            markUnsupportedTargetLanguage(targetLanguage)
            return text
        @unknown default:
            return text
        }
    }

    func translateMany(_ texts: [String]) async -> [String: String] {
        var result: [String: String] = [:]
        for text in Array(Set(texts)) {
            result[text] = await translate(text)
        }
        return result
    }

    @available(iOS 26.0, *)
    private var targetLanguage: Locale.Language? {
        let code = currentLanguageCode.lowercased()
        if code.hasPrefix("ko") { return nil }
        if code.hasPrefix("en") { return Locale.Language(identifier: "en") }
        if code.hasPrefix("ja") { return Locale.Language(identifier: "ja") }
        if code.hasPrefix("zh") { return Locale.Language(identifier: "zh") }
        return nil
    }

    private func shouldTranslate(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        guard text.range(of: #"\p{Hangul}"#, options: .regularExpression) != nil else { return false }
        guard text.range(of: #"^[\d\s:.,/()~+\-]+$"#, options: .regularExpression) == nil else { return false }
        guard text.range(of: #"^https?://"#, options: .regularExpression) == nil else { return false }
        return true
    }

    private func cacheKey(for text: String) -> String {
        "\(currentLanguageCode)|\(text)"
    }

    private func clearTranslatedStoredData() {
        Event.deleteAll()
        Contact.deleteAll()
        UserDefaults.standard.removeObject(forKey: "calendarVersion")
        UserDefaults.standard.removeObject(forKey: "contactVersion")
    }

    @available(iOS 26.0, *)
    private func translationSession(for targetLanguage: Locale.Language) -> TranslationSession {
        TranslationSession(installedSource: Locale.Language(identifier: "ko"), target: targetLanguage)
    }

    @available(iOS 26.0, *)
    private func translationAvailabilityStatus(to targetLanguage: Locale.Language) async -> LanguageAvailability.Status {
        let availability = LanguageAvailability()
        return await availability.status(from: Locale.Language(identifier: "ko"), to: targetLanguage)
    }

    @available(iOS 26.0, *)
    private func isUnsupportedTargetLanguage(_ targetLanguage: Locale.Language) -> Bool {
        unsupportedTargetLanguageIDs.contains(targetLanguage.minimalIdentifier)
    }

    @available(iOS 26.0, *)
    private func markUnsupportedTargetLanguage(_ targetLanguage: Locale.Language) {
        unsupportedTargetLanguageIDs.insert(targetLanguage.minimalIdentifier)
    }

    private func debugLog(_ message: String) {
        #if DEBUG
            logger.debug("\(message, privacy: .public)")
        #endif
    }
}

extension UILabel {
    func setKoreanTranslatedText(_ text: String?) {
        self.text = text
        guard let text else { return }
        Task { [weak self] in
            let translated = await KoreanTextTranslator.shared.translate(text)
            guard let self, self.text == text else { return }
            self.text = translated
        }
    }
}
