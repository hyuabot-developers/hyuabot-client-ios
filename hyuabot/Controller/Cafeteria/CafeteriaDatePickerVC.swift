//
//  CafeteriaDatePickerVC.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaDatePickerVC: UIViewController {
    private let selectedDate: Date
    private let onSelect: (Date) -> Void
    private var titleInsets: Constraint?
    private var cardInsets: Constraint?

    init(selectedDate: Date, onSelect: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        HYUSheet.configure(self, detents: [.medium(), .large()])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        HYUSheet.applyBackground(to: view)
        let title = HYUSheet.makeTitleLabel()
        HYUSheet.setTitle(String(localized: "cafeteria.date.picker.title"), on: title)
        view.addSubview(title)
        title.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(HYUMetrics.Layout.sheetTitleTop)
            titleInsets = $0.horizontalEdges.equalToSuperview().inset(HYUMetrics.Layout.sheetHorizontalInset).constraint
        }
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = HYUMetrics.Radius.card
        // On the Duo cover display the card spans under the system strip's safe-area inset; inheriting it as layout
        // margins makes the inline calendar's internal compositional layout oscillate and pin the main thread.
        card.insetsLayoutMarginsFromSafeArea = false
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(8)
            cardInsets = $0.horizontalEdges.equalToSuperview().inset(HYUMetrics.Layout.sheetHorizontalInset).constraint
        }

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.tintColor = SettingsStyle.Color.accent
        picker.insetsLayoutMarginsFromSafeArea = false
        picker.date = selectedDate
        picker.accessibilityIdentifier = "cafeteria.date_picker"
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        card.addSubview(picker)
        picker.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep the title and card clear of the cover display's system strip (zero when unfolded).
        let safe = duoHorizontalSafeInsets
        let inset = HYUMetrics.Layout.sheetHorizontalInset
        let edges = UIEdgeInsets(top: 0, left: inset + safe.left, bottom: 0, right: inset + safe.right)
        titleInsets?.update(inset: edges)
        cardInsets?.update(inset: edges)
    }

    @objc
    private func dateChanged(_ picker: UIDatePicker) {
        onSelect(picker.date)
        dismissOrClearDuoDetail()
    }
}
