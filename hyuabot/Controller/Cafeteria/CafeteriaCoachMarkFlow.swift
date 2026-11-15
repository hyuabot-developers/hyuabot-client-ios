//
//  CafeteriaCoachMarkFlow.swift
//  hyuabot
//

import UIKit

@MainActor
final class CafeteriaCoachMarkFlow {
    let pageId: String
    let version: Int
    private(set) var isInfoPending = false

    init(pageId: String = "cafeteria", version: Int = 1) {
        self.pageId = pageId
        self.version = version
    }

    func markInfoPending() {
        isInfoPending = true
    }

    @discardableResult
    func presentFirstStage(on host: UIViewController, items: [CoachMarkItem], onFinished: @escaping () -> Void) -> Bool {
        guard !isInfoPending else { return false }
        return host.presentCoachMarks(pageId: pageId, items: items, version: version, shouldMarkAsShown: false, onSkip: { [weak self] in
            guard let self else { return }
            isInfoPending = false
            CoachMarkManager.shared.markPageShown(pageId, version: version)
        }, onComplete: { [weak self] in
            self?.markInfoPending()
            onFinished()
        })
    }

    @discardableResult
    func presentPendingInfo(on host: UIViewController, items: [CoachMarkItem]) -> Bool {
        guard isInfoPending else { return false }
        return host.presentCoachMarks(pageId: pageId, items: items, version: version, shouldMarkAsShown: true, onSkip: { [weak self] in
            self?.isInfoPending = false
        }, onComplete: { [weak self] in
            self?.isInfoPending = false
        })
    }
}
