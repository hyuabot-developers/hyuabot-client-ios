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
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SettingsStyle.Color.background
        let title = UILabel()
        title.text = String(localized: "cafeteria.date.picker.title")
        title.font = SettingsStyle.font(17, bold: true)
        title.textColor = SettingsStyle.Color.text
        title.textAlignment = .center
        view.addSubview(title)
        title.snp
            .makeConstraints {
                $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16); $0.leading.trailing.equalToSuperview().inset(16)
            }
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.tintColor = SettingsStyle.Color.accent
        picker.date = selectedDate
        picker.accessibilityIdentifier = "cafeteria.date_picker"
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        view.addSubview(picker)
        picker.snp
            .makeConstraints {
                $0.top.equalTo(title.snp.bottom).offset(8); $0.centerX.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(16)
            }
    }

    @objc
    private func dateChanged(_ picker: UIDatePicker) {
        onSelect(picker.date)
        dismiss(animated: true)
    }
}
