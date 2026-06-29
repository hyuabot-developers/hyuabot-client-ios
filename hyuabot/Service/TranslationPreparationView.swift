//
//  TranslationPreparationView.swift
//  hyuabot
//

import OSLog
import SwiftUI
import Translation

@available(iOS 26.0, *)
struct TranslationPreparationView: View {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "net.jaram.hyuabot",
        category: "TranslationPreparationView"
    )

    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .task {
                configuration = await KoreanTextTranslator.shared.translationPreparationConfiguration()
            }
            .translationTask(configuration) { session in
                do {
                    try await session.prepareTranslation()
                    if let configuration {
                        KoreanTextTranslator.shared.didPrepareTranslation(for: configuration)
                    }
                } catch {
                    #if DEBUG
                        logger.debug("Translation model preparation failed: \(error.localizedDescription, privacy: .public)")
                    #endif
                }
            }
    }
}
