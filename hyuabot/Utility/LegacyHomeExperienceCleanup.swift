//
//  LegacyHomeExperienceCleanup.swift
//  hyuabot
//

import Foundation

/// Removes UserDefaults values written only by the retired Home screen so that
/// users who had the Home experience enabled land on the Shuttle screen with no stale flags.
enum LegacyHomeExperienceCleanup {
    static let obsoleteKeys = [
        "homeExperienceEnabled",
        "homeExperiencePromptDecision",
        "home.showSeoulBusStop",
        "home.seoulBusStop"
    ]

    static func run(defaults: UserDefaults = .standard) {
        for key in obsoleteKeys {
            defaults.removeObject(forKey: key)
        }
    }
}
