//
//  KoreanTextTranslator.swift
//  hyuabot
//

import Foundation
#if !targetEnvironment(simulator)
    import MLKitTranslate
#endif
import OSLog
import UIKit

@MainActor
final class KoreanTextTranslator {
    static let shared = KoreanTextTranslator()

    private let cacheKey = "koreanTextTranslationCacheV1"
    private let translatedDataLanguageKey = "translatedDataLanguageV1"
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "net.jaram.hyuabot",
        category: "KoreanTextTranslator"
    )
    private var memoryCache: [String: String]
    #if !targetEnvironment(simulator)
        private var translators: [String: Translator] = [:]
    #endif

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
        #if targetEnvironment(simulator)
            false
        #else
            targetLanguage != nil
        #endif
    }

    func prepareForCurrentLanguage() {
        #if targetEnvironment(simulator)
            debugLog("Skipping model download on simulator")
        #else
            guard let targetLanguage else {
                debugLog("Skipping model download for language: \(currentLanguageCode)")
                return
            }

            Task {
                let translator = translator(for: targetLanguage)
                let conditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
                do {
                    try await downloadModelIfNeeded(translator, conditions: conditions)
                    debugLog("Translation model is ready for language: \(currentLanguageCode)")
                } catch {
                    debugLog("Translation model download failed for language: \(currentLanguageCode), error: \(error)")
                }
            }
        #endif
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
        #if targetEnvironment(simulator)
            return text
        #else
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard shouldTranslate(cleaned), let targetLanguage else { return text }

            let key = cacheKey(for: cleaned)
            if let cached = memoryCache[key] {
                return cached
            }

            let translator = translator(for: targetLanguage)
            let conditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
            do {
                try await downloadModelIfNeeded(translator, conditions: conditions)
                let translated = try await translate(cleaned, translator: translator)
                let final = translated.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !final.isEmpty else { return text }
                memoryCache[key] = final
                UserDefaults.standard.set(memoryCache, forKey: cacheKey)
                return final
            } catch {
                debugLog("Translation failed for language: \(currentLanguageCode), text: \(cleaned), error: \(error)")
                return text
            }
        #endif
    }

    func translateMany(_ texts: [String]) async -> [String: String] {
        var result: [String: String] = [:]
        for text in Array(Set(texts)) {
            result[text] = await translate(text)
        }
        return result
    }

    #if !targetEnvironment(simulator)
        private var targetLanguage: TranslateLanguage? {
            let code = currentLanguageCode.lowercased()
            if code.hasPrefix("ko") { return nil }
            if code.hasPrefix("en") { return .english }
            if code.hasPrefix("ja") { return .japanese }
            if code.hasPrefix("zh") { return .chinese }
            return nil
        }
    #endif

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

    #if !targetEnvironment(simulator)
        private func translator(for targetLanguage: TranslateLanguage) -> Translator {
            let key = "\(targetLanguage.rawValue)"
            if let translator = translators[key] {
                return translator
            }
            let options = TranslatorOptions(sourceLanguage: .korean, targetLanguage: targetLanguage)
            let translator = Translator.translator(options: options)
            translators[key] = translator
            return translator
        }

        private func downloadModelIfNeeded(_ translator: Translator, conditions: ModelDownloadConditions) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                translator.downloadModelIfNeeded(with: conditions) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }

        private func translate(_ text: String, translator: Translator) async throws -> String {
            try await withCheckedThrowingContinuation { continuation in
                translator.translate(text) { translatedText, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: translatedText ?? text)
                    }
                }
            }
        }
    #endif

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
