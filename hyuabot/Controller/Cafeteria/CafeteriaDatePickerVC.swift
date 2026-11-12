//
//  CafeteriaDatePickerVC.swift
//  hyuabot
//

import SnapKit
import UIKit

final class CafeteriaDatePickerVC: UIViewController {
    private let selectedDate: Date
    private let onSelect: (Date) -> Void

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
            $0.leading.trailing.equalToSuperview().inset(HYUMetrics.Layout.sheetHorizontalInset)
        }
        let card = UIView()
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = HYUMetrics.Radius.card
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(HYUMetrics.Layout.sheetHorizontalInset)
        }

        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.tintColor = SettingsStyle.Color.accent
        picker.date = selectedDate
        picker.accessibilityIdentifier = "cafeteria.date_picker"
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        card.addSubview(picker)
        picker.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }
    }

    @objc
    private func dateChanged(_ picker: UIDatePicker) {
        onSelect(picker.date)
        dismiss(animated: true)
    }
}
