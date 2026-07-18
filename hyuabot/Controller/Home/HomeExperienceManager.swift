import Foundation

@MainActor
enum HomeExperienceManager {
    private static let enabledKey = "homeExperienceEnabled"
    private static let promptDecisionKey = "homeExperiencePromptDecision"
    private static var sessionEnabledOverride: Bool?

    static var isEnabled: Bool {
        if let sessionEnabledOverride {
            return sessionEnabledOverride
        }
        return UserDefaults.standard.bool(forKey: enabledKey)
    }

    static var shouldPrompt: Bool {
        UserDefaults.standard.object(forKey: promptDecisionKey) == nil
    }

    static func enable() {
        sessionEnabledOverride = true
        UserDefaults.standard.set(true, forKey: enabledKey)
        UserDefaults.standard.set(true, forKey: promptDecisionKey)
    }

    static func disable() {
        sessionEnabledOverride = false
        UserDefaults.standard.set(false, forKey: enabledKey)
        UserDefaults.standard.set(false, forKey: promptDecisionKey)
    }

    static func deferPrompt() {
        UserDefaults.standard.set(false, forKey: promptDecisionKey)
    }
}
