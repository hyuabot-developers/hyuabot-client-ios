//
//  ContactVC+Actions.swift
//  hyuabot
//

import UIKit

extension ContactVC {
    func callContact(_ entry: ContactEntry) {
        let phoneNumber = entry.phoneNumber.filter { $0.isNumber || $0 == "+" }
        let urls = [URL(string: "telprompt://\(phoneNumber)"), URL(string: "tel://\(phoneNumber)")].compactMap { $0 }
        if let url = urls.first(where: { UIApplication.shared.canOpenURL($0) }) ?? urls.first {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func copyPhone(_ entry: ContactEntry) {
        UIPasteboard.general.string = entry.phoneNumber
        let message = String(format: String(localized: "toast.contact.phone.copied.%@"), entry.phoneNumber)
        SettingsToastView.show(message: message, in: navigationController?.view ?? view)
    }

    func shareContact(_ entry: ContactEntry, sourceView: UIView?) {
        let text = String(format: String(localized: "contact.share.format.%@.%@"), entry.name, entry.phoneNumber)
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sourceView ?? view
        activityVC.popoverPresentationController?.sourceRect = sourceView?.bounds ?? view.bounds
        present(activityVC, animated: true)
    }

    func showCoachMarksIfNeeded() {
        let item = CoachMarkItem(
            id: "contact.search",
            targetView: searchField,
            title: String(localized: "coach.contact.search.title"),
            message: String(localized: "coach.contact.search.message")
        )
        presentCoachMarks(pageId: "contact", items: [item], shouldMarkAsShown: false, onComplete: { [weak self] in
            guard let self else { return }
            if !self.sections.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.presentContactItemCoachMark()
                }
            } else {
                self.pendingItemCoachMark = true
            }
        })
    }

    func presentContactItemCoachMark() {
        let item = CoachMarkItem(
            id: "contact.item",
            targetViewProvider: { [weak self] in
                self?.tableView.cellForRow(at: IndexPath(row: 0, section: 0))
            },
            title: String(localized: "coach.contact.item.title"),
            message: String(localized: "coach.contact.item.message")
        )
        presentCoachMarks(
            pageId: "contact",
            items: [item],
            shouldMarkAsShown: false,
            onComplete: { CoachMarkManager.shared.markPageShown("contact") }
        )
    }
}
