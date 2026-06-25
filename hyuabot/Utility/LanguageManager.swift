import Foundation

final class LanguageManager {
    static let shared = LanguageManager()
    private init() {}

    private let suggestionShownKey = "languageSuggestionShownV1"
    private let hasLaunchedKey = "appHasLaunched"

    var isFirstLaunch: Bool {
        let first = !UserDefaults.standard.bool(forKey: hasLaunchedKey)
        if first { UserDefaults.standard.set(true, forKey: hasLaunchedKey) }
        return first
    }

    // Whether to show the "new language support" dialog to existing users
    // Condition: app is showing in English but device prefers ja or zh
    var shouldShowSuggestion: Bool {
        guard !UserDefaults.standard.bool(forKey: suggestionShownKey) else { return false }
        let appLang = Bundle.main.preferredLocalizations.first ?? "ko"
        guard appLang == "en" else { return false }
        return Locale.preferredLanguages.contains { $0.hasPrefix("ja") || $0.hasPrefix("zh") }
    }

    /// Languages from device preferences that are newly supported
    var suggestedLanguages: [String] {
        var langs: [String] = []
        for lang in Locale.preferredLanguages {
            if lang.hasPrefix("ja"), !langs.contains("ja") { langs.append("ja") }
            if lang.hasPrefix("zh"), !langs.contains("zh-Hans") { langs.append("zh-Hans") }
        }
        return langs
    }

    func markSuggestionShown() {
        UserDefaults.standard.set(true, forKey: suggestionShownKey)
    }
}
