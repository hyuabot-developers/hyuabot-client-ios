//
//  BusArrivalIntent.swift
//  hyuabot
//

import AppIntents
import Foundation

struct BusArrivalIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.bus.intent.title"
    static let description = IntentDescription("intent.bus.description")

    @Parameter(
        title: "intent.bus.parameter.route"
    )
    var route: BusRouteOption?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let answer = await BusIntentService.answer(route: route)
        return .result(
            dialog: IntentDialog(stringLiteral: answer.dialog),
            view: IntentSnippetView(content: answer.snippet)
        )
    }
}
