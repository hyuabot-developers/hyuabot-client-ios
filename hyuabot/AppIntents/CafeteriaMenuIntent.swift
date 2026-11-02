//
//  CafeteriaMenuIntent.swift
//  hyuabot
//

import AppIntents

struct CafeteriaMenuIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.cafeteria.intent.title"
    static let description = IntentDescription("intent.cafeteria.description")

    @Parameter(title: "intent.cafeteria.parameter.restaurant")
    var restaurant: CafeteriaRestaurantOption?

    @Parameter(title: "intent.cafeteria.parameter.meal")
    var meal: CafeteriaMealOption?

    @Parameter(title: "intent.cafeteria.parameter.day")
    var day: CafeteriaDayOption?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let answer = await CafeteriaIntentService.answer(meal: meal, day: day, restaurant: restaurant, now: .now)
        return .result(
            dialog: IntentDialog(stringLiteral: answer.dialog),
            view: IntentSnippetView(content: answer.snippet)
        )
    }
}
