//
//  ShuttleArrivalIntent.swift
//  hyuabot
//

import AppIntents

struct ShuttleArrivalIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.shuttle.intent.title"
    static let description = IntentDescription("intent.shuttle.description")

    @Parameter(title: "intent.shuttle.parameter.stop")
    var stop: ShuttleStopOption?

    @Parameter(title: "intent.shuttle.parameter.direction")
    var direction: ShuttleDirectionOption?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let answer = await ShuttleIntentService.answer(for: stop, direction: direction, now: .now)
        return .result(
            dialog: IntentDialog(stringLiteral: answer.dialog),
            view: IntentSnippetView(content: answer.snippet)
        )
    }
}
