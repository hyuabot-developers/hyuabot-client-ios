//
//  SubwayArrivalIntent.swift
//  hyuabot
//

import AppIntents
import Foundation

struct SubwayArrivalIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.subway.intent.title"
    static let description = IntentDescription("intent.subway.description")

    @Parameter(
        title: "intent.subway.parameter.line"
    )
    var line: SubwayLineOption?
    @Parameter(
        title: "intent.subway.parameter.direction"
    )
    var direction: SubwayDirectionOption?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let answer = await SubwayIntentService.answer(line: line, direction: direction, now: .now)
        return .result(
            dialog: IntentDialog(stringLiteral: answer.dialog),
            view: IntentSnippetView(content: answer.snippet)
        )
    }
}
