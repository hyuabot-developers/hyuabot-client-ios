//
//  SettingsCampusCardView.swift
//  hyuabot
//

import SnapKit
import UIKit

final class SettingsCampusCardView: UIView {
    var onSelectCampus: ((Int) -> Void)?
    let segmentedControl = UISegmentedControl(items: [String(localized: "campus.seoul"), String(localized: "campus.erica")])
    private let campusTitle = UILabel()

    init() {
        super.init(frame: .zero)
        backgroundColor = SettingsStyle.Color.card
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 12
        let icon = SettingsIconTileView(
            symbolName: "graduationcap.fill",
            color: SettingsStyle.Tile.blue,
            size: 36,
            radius: 10,
            glyphPointSize: 18
        )
        header.addArrangedSubview(icon)
        let labels = UIStackView()
        labels.axis = .vertical
        labels.spacing = 4
        let caption = UILabel()
        caption.font = SettingsStyle.font(13)
        caption.textColor = SettingsStyle.Color.secondaryText
        caption.text = String(localized: "setting.campus")
        campusTitle.font = SettingsStyle.font(18, bold: true)
        campusTitle.textColor = SettingsStyle.Color.text
        labels.addArrangedSubview(caption)
        labels.addArrangedSubview(campusTitle)
        header.addArrangedSubview(labels)
        stack.addArrangedSubview(header)
        segmentedControl.accessibilityIdentifier = "setting.campus_control"
        segmentedControl.backgroundColor = SettingsStyle.Color.segmentBackground
        segmentedControl.selectedSegmentTintColor = SettingsStyle.Color.accent
        segmentedControl.setTitleTextAttributes([.font: SettingsStyle.font(15), .foregroundColor: SettingsStyle.Color.text], for: .normal)
        segmentedControl.setTitleTextAttributes(
            [.font: SettingsStyle.font(15, bold: true), .foregroundColor: SettingsStyle.Color.onAccent],
            for: .selected
        )
        stack.addArrangedSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { $0.height.equalTo(48) }
        let note = UILabel()
        note.font = SettingsStyle.font(13)
        note.textColor = SettingsStyle.Color.secondaryText
        note.numberOfLines = 0
        note.text = String(localized: "setting.campus.caption")
        stack.addArrangedSubview(note)
        segmentedControl.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        setCampusID(1)
    }

    func setCampusID(_ campusID: Int) {
        let name = String(localized: campusID == 1 ? "campus.seoul" : "campus.erica")
        segmentedControl.selectedSegmentIndex = campusID == 1 ? 0 : 1
        campusTitle.text = String(format: String(localized: "setting.campus.current.%@"), name)
    }

    @objc
    private func selectionChanged() {
        let id = segmentedControl.selectedSegmentIndex == 0 ? 1 : 2
        setCampusID(id)
        onSelectCampus?(id)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
