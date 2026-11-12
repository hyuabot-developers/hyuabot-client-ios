//
//  ShuttleRealtimeTableFooterView2.swift
//  hyuabot
//

import UIKit

final class ShuttleRealtimeTableFooterView2: UIView {
    private let stopID: ShuttleStopEnum
    private let showEntireTimetable: @MainActor (_ stop: ShuttleStopEnum, _ section: Int) -> Void
    private let footnoteLabel = UILabel().then {
        $0.numberOfLines = 0
        $0.attributedText = SettingsStyle.attributedText(
            String(localized: "shuttle.realtime.footnote"),
            font: SettingsStyle.font(12),
            color: SettingsStyle.Color.commuterFaint,
            lineHeight: 16
        )
    }

    private let showEntireTimeTableButton1 = ShuttleRealtimeTableFooterView2.makeTimetableButton("shuttle.show.entire.timetable.station")
    private let showEntireTimeTableButton2 = ShuttleRealtimeTableFooterView2.makeTimetableButton("shuttle.show.entire.timetable.campus")
    private let showEntireTimeTableButton3 = ShuttleRealtimeTableFooterView2.makeTimetableButton("shuttle.show.entire.timetable.terminal")
    private let showEntireTimeTableButton4 = ShuttleRealtimeTableFooterView2
        .makeTimetableButton("shuttle.show.entire.timetable.jungang_stn")

    init(
        parentView: UIView,
        stopID: ShuttleStopEnum,
        showEntireTimetable: @escaping @MainActor (_ stop: ShuttleStopEnum, _ section: Int) -> Void
    ) {
        self.stopID = stopID
        self.showEntireTimetable = showEntireTimetable

        let width = parentView.bounds.width
        let noteSize = footnoteLabel.sizeThatFits(CGSize(width: max(0, width - 40), height: .greatestFiniteMagnitude))
        let buttonCount = Self.visibleButtonCount(for: stopID)
        let cardHeight = CGFloat(buttonCount * 44 + max(0, buttonCount - 1))
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: cardHeight + 12 + noteSize.height + 8))

        let buttons = visibleButtons()
        for button in buttons {
            button.addTarget(self, action: #selector(showEntireTimeTable(_:)), for: .touchUpInside)
        }

        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 0
        card.backgroundColor = SettingsStyle.Color.card
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        for (index, button) in buttons.enumerated() {
            let row = makeRow(for: button)
            card.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(44) }
            if index < buttons.count - 1 {
                let separator = UIView().then { $0.backgroundColor = SettingsStyle.Color.separator }
                card.addArrangedSubview(separator)
                separator.snp.makeConstraints { make in
                    make.height.equalTo(1)
                    make.leading.trailing.equalToSuperview().inset(16)
                }
            }
        }

        addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        addSubview(footnoteLabel)
        footnoteLabel.snp.makeConstraints { make in
            make.top.equalTo(card.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeTimetableButton(_ key: String) -> UIButton {
        UIButton().then {
            var configuration = UIButton.Configuration.plain()
            var title = AttributedString(String(localized: String.LocalizationValue(key)))
            title.font = SettingsStyle.font(14, bold: true)
            configuration.attributedTitle = title
            configuration.contentInsets = .zero
            $0.configuration = configuration
            $0.contentHorizontalAlignment = .leading
            $0.tintColor = SettingsStyle.Color.link
        }
    }

    private static func visibleButtonCount(for stopID: ShuttleStopEnum) -> Int {
        stopID == .terminal || stopID == .jungangStation || stopID == .shuttlecockIn ? 1 : 3
    }

    private func visibleButtons() -> [UIButton] {
        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            return [showEntireTimeTableButton1, showEntireTimeTableButton3, showEntireTimeTableButton4]
        }
        if stopID == .station {
            return [showEntireTimeTableButton2, showEntireTimeTableButton3, showEntireTimeTableButton4]
        }
        return [showEntireTimeTableButton2]
    }

    private func makeRow(for button: UIButton) -> UIView {
        let row = UIView()
        row.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(44)
        }

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = SettingsStyle.Color.commuterFaint
        chevron.contentMode = .scaleAspectFit
        row.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        return row
    }

    @objc
    private func showEntireTimeTable(_ sender: UIButton) {
        guard let index = visibleButtons().firstIndex(of: sender) else { return }
        AnalyticsManager.logSelect(.shuttleShowEntireTimetable)

        if stopID == .dormiotryOut || stopID == .shuttlecockOut {
            let section = [0, 1, 2][index]
            showEntireTimetable(stopID, section)
        } else if stopID == .station {
            let section = [0, 1, 2][index]
            showEntireTimetable(stopID, section)
        } else {
            showEntireTimetable(stopID, 0)
        }
    }
}
