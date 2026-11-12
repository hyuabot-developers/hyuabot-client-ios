//
//  ShuttleQuickSettingsVC.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class ShuttleQuickSettingsVC: UIViewController {
    var openHelp: (() -> Void)?
    var openInquiry: (() -> Void)?
    var updateShowDepartureTime: ((Bool) -> Void)?
    var updateShowArrivalByTime: ((Bool) -> Void)?
    var updateShowPresenceStatus: ((Bool) -> Void)?
    var updateShowBusTransfer: ((Bool) -> Void)?
    var updateShowSubwayTransfer: ((Bool) -> Void)?
    var updateSubwayDestination: ((ShuttleSubwayTransferDestination) -> Void)?
    var updateAlternativeDisplayMode: ((ShuttleAlternativeDisplayMode) -> Void)?
    /// Measured once: re-measuring on every detent pass makes the sheet resize between taps.
    private var cachedSheetHeight: CGFloat?
    var preferredSheetHeight: CGFloat {
        if let cachedSheetHeight {
            return cachedSheetHeight
        }
        view.layoutIfNeeded()
        let height = sheetView.contentHeight
        cachedSheetHeight = height
        return height
    }

    private let sheetView = HYUSheetView(title: String(localized: "shuttle.quick_settings.title"))
    private let showDepartureTimeSwitch = UISwitch()
    private let emphasisSegment = SubwaySegmentView(buttonIdentifierPrefix: "shuttle.quick_settings.emphasis")
    private let showArrivalByTimeSwitch = UISwitch()
    private let showPresenceStatusSwitch = UISwitch()
    private let showBusTransferSwitch = UISwitch()
    private let showSubwayTransferSwitch = UISwitch()
    private let subwayDestinationButton = UIButton(type: .system)
    private let showAlternativeSwitch = UISwitch()
    private let sortSegment = SubwaySegmentView(buttonIdentifierPrefix: "shuttle.quick_settings.sort")
    private var subwayDestination: ShuttleSubwayTransferDestination
    private var alternativeDisplayMode: ShuttleAlternativeDisplayMode

    init(
        showArrivalByTime: Bool,
        showDepartureTime: Bool,
        showPresenceStatus: Bool,
        showBusTransfer: Bool,
        showSubwayTransfer: Bool,
        subwayDestination: ShuttleSubwayTransferDestination,
        alternativeDisplayMode: ShuttleAlternativeDisplayMode
    ) {
        self.subwayDestination = subwayDestination
        self.alternativeDisplayMode = alternativeDisplayMode
        showArrivalByTimeSwitch.isOn = showArrivalByTime
        showDepartureTimeSwitch.isOn = showDepartureTime
        showPresenceStatusSwitch.isOn = showPresenceStatus
        showBusTransferSwitch.isOn = showBusTransfer
        showSubwayTransferSwitch.isOn = showSubwayTransfer
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateSelectionMenus()
    }
}

extension ShuttleQuickSettingsVC {
    private func setupUI() {
        view.addSubview(sheetView)
        sheetView.snp.makeConstraints { $0.edges.equalToSuperview() }
        sheetView.showsCloseButton(true, identifier: "shuttle.quick_settings.close")
        sheetView.closeButton.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
        configureControls()
        let stack = sheetView.contentStack
        stack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.quick_settings.section.display"), isFirst: true))
        stack.addArrangedSubview(displaySettingsGroup())
        stack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.quick_settings.section.connections")))
        stack.addArrangedSubview(connectionSettingsGroup())
        stack.addArrangedSubview(HYUSheetView.sectionHeader(String(localized: "shuttle.quick_settings.section.alternative")))
        let alternative = alternativeGroup()
        stack.addArrangedSubview(alternative)
        let bottom = UIStackView(arrangedSubviews: [horizontalActionButtons()])
        bottom.axis = .vertical
        bottom.spacing = 8
        stack.setCustomSpacing(16, after: alternative)
        stack.addArrangedSubview(bottom)
    }

    private func displaySettingsGroup() -> UIView {
        let card = HYUSheetView.card()
        sortSegment.configure(
            items: [
                SubwaySegmentView.Item(title: String(localized: "shuttle.quick_settings.sort.destination"), dotColors: [], count: nil),
                SubwaySegmentView.Item(
                    title: String(localized: "shuttle.quick_settings.sort.time"),
                    dotColors: [],
                    count: nil
                )
            ],
            selected: showArrivalByTimeSwitch.isOn ? 1 : 0
        )
        sortSegment.onSelect = { [weak self] index in self?.updateShowArrivalByTime?(index == 1) }
        emphasisSegment.configure(
            items: [
                SubwaySegmentView.Item(title: String(localized: "shuttle.quick_settings.emphasis.remaining"), dotColors: [], count: nil),
                SubwaySegmentView.Item(
                    title: String(localized: "shuttle.quick_settings.emphasis.departure"),
                    dotColors: [],
                    count: nil
                )
            ],
            selected: showDepartureTimeSwitch.isOn ? 1 : 0
        )
        emphasisSegment.onSelect = { [weak self] index in self?.updateShowDepartureTime?(index == 1) }
        let sort = settingTitleRow(
            String(localized: "shuttle.quick_settings.sort.title"),
            identifier: "shuttle.quick_settings.arrival_by_time_row"
        )
        sort.addArrangedSubview(sortSegment)
        let emphasis = settingTitleRow(
            String(localized: "shuttle.quick_settings.emphasis.title"),
            identifier: "shuttle.quick_settings.departure_time_row"
        )
        emphasis.addArrangedSubview(emphasisSegment)
        [
            sort,
            emphasis,
            switchSettingRow(
                title: String(localized: "shuttle.quick_settings.presence.title"),
                hint: String(localized: "shuttle.quick_settings.presence.subtitle"),
                control: showPresenceStatusSwitch,
                identifier: "shuttle.quick_settings.presence_row"
            )
        ].enumerated().forEach { index, row in
            if index > 0 {
                card.addArrangedSubview(HYUSheetView.separator())
            }
            card.addArrangedSubview(row)
        }
        return card
    }

    private func connectionSettingsGroup() -> UIView {
        settingsGroup(
            rows: [
                switchSettingRow(
                    title: String(localized: "home.quick_settings.subway_transfer.title"),
                    hint: String(localized: "home.quick_settings.subway_transfer.subtitle"),
                    control: showSubwayTransferSwitch,
                    identifier: "shuttle.quick_settings.subway_transfer_row"
                ),
                switchSettingRow(
                    title: String(localized: "home.quick_settings.bus50_transfer.title"),
                    hint: String(localized: "home.quick_settings.bus50_transfer.subtitle"),
                    control: showBusTransferSwitch,
                    identifier: "shuttle.quick_settings.bus_transfer_row"
                ),
                valueSettingRow(
                    title: String(localized: "shuttle.quick_settings.subway_destination.title"),
                    control: subwayDestinationButton,
                    identifier: "shuttle.quick_settings.subway_destination_row"
                )
            ]
        )
    }

    private func alternativeGroup() -> UIView {
        settingsGroup(
            rows: [
                switchSettingRow(
                    title: String(localized: "shuttle.quick_settings.alternative.title"),
                    hint: String(localized: "shuttle.quick_settings.alternative.subtitle"),
                    control: showAlternativeSwitch,
                    identifier: "shuttle.quick_settings.alternative_row"
                )
            ]
        )
    }

    private func configureControls() {
        let values = [showPresenceStatusSwitch, showBusTransferSwitch, showSubwayTransferSwitch]
        for (index, control) in values.enumerated() {
            control.onTintColor = SettingsStyle.Color.accent
            control.addTarget(
                self,
                action: [#selector(onChangePresenceStatus), #selector(onChangeBusTransfer), #selector(onChangeSubwayTransfer)][index],
                for: .valueChanged
            )
        }
        showAlternativeSwitch.onTintColor = SettingsStyle.Color.accent
        showAlternativeSwitch.isOn = alternativeDisplayMode != .hidden
        showAlternativeSwitch.addTarget(self, action: #selector(onChangeAlternative), for: .valueChanged)
        var menuConfig = UIButton.Configuration.plain()
        menuConfig.image = UIImage(
            systemName: "chevron.up.chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .regular)
        )
        menuConfig.imagePlacement = .trailing
        menuConfig.imagePadding = 6
        menuConfig.contentInsets = .zero
        subwayDestinationButton.configuration = menuConfig
        subwayDestinationButton.setContentHuggingPriority(.required, for: .horizontal)
        subwayDestinationButton.tintColor = SettingsStyle.Color.link
        subwayDestinationButton.showsMenuAsPrimaryAction = true
    }

    private func switchSettingRow(title: String, hint: String, control: UISwitch, identifier: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        row.accessibilityIdentifier = identifier
        let labels = UIStackView()
        labels.axis = .vertical
        labels.spacing = 2
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            title, font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 20
        )
        let detail = UILabel()
        detail.attributedText = SettingsStyle.attributedText(
            hint, font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText, lineHeight: 18
        )
        detail.numberOfLines = 0
        labels.addArrangedSubview(label)
        labels.addArrangedSubview(detail)
        row.addArrangedSubview(labels)
        row.addArrangedSubview(control)
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 64).isActive = true
        control.accessibilityLabel = title
        control.accessibilityHint = hint
        control.accessibilityIdentifier = "\(identifier).switch"
        return row
    }

    private func valueSettingRow(title: String, control: UIButton, identifier: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            title, font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 20
        )
        row.addArrangedSubview(label)
        row.addArrangedSubview(control)
        control.accessibilityIdentifier = "\(identifier).menu"
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        return row
    }

    private func settingsGroup(rows: [UIView], footer: String? = nil) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        let card = HYUSheetView.card()
        for (index, row) in rows.enumerated() {
            if index > 0 {
                card.addArrangedSubview(HYUSheetView.separator())
            }
            card.addArrangedSubview(row)
        }
        container.addArrangedSubview(card)
        if let footer {
            container.addArrangedSubview(HYUSheetView.footnote(footer))
        }
        return container
    }

    private func horizontalActionButtons() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        let help = HYUSheetView.actionButton(
            title: String(localized: "common.help"),
            systemImage: "questionmark.circle",
            identifier: "shuttle.quick_settings.help"
        )
        help.addTarget(self, action: #selector(onTapHelp), for: .touchUpInside)
        let inquiry = HYUSheetView.actionButton(
            title: String(localized: "inquiry.title"),
            systemImage: "bubble.left.and.bubble.right",
            identifier: "shuttle.quick_settings.inquiry"
        )
        inquiry.addTarget(self, action: #selector(onTapInquiry), for: .touchUpInside)
        stack.addArrangedSubview(help)
        stack.addArrangedSubview(inquiry)
        return stack
    }

    @objc
    private func onTapHelp() {
        dismiss(animated: true) { [weak self] in self?.openHelp?() }
    }

    private func settingTitleRow(_ title: String, identifier: String) -> UIStackView {
        let row = UIStackView()
        row.axis = .vertical
        row.spacing = 10
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        row.accessibilityIdentifier = identifier
        row.isAccessibilityElement = false
        let label = UILabel()
        label.attributedText = SettingsStyle.attributedText(
            title, font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text, lineHeight: 20
        )
        row.addArrangedSubview(label)
        return row
    }

    private func updateSelectionMenus() {
        subwayDestinationButton.menu = UIMenu(children: ShuttleSubwayTransferDestination.allCases.map { destination in
            UIAction(
                title: destination.title,
                state: destination == subwayDestination ? .on : .off
            ) { [weak self] _ in
                self?.selectSubwayDestination(destination)
            }
        })
        updateMenuButtonTitle(subwayDestinationButton, title: subwayDestination.title)
    }

    private func updateMenuButtonTitle(_ button: UIButton, title: String) {
        var config = button.configuration
        config?.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: SettingsStyle.font(15, bold: true)
        ]))
        button.configuration = config
        button.accessibilityValue = title
    }

    private func selectSubwayDestination(_ destination: ShuttleSubwayTransferDestination) {
        subwayDestination = destination
        updateSelectionMenus()
        updateSubwayDestination?(destination)
    }

    @objc
    private func onChangeAlternative() {
        alternativeDisplayMode = showAlternativeSwitch.isOn ? .always : .hidden
        updateAlternativeDisplayMode?(alternativeDisplayMode)
    }

    @objc
    private func onTapClose() {
        dismiss(animated: true)
    }

    @objc
    private func onTapInquiry() {
        dismiss(animated: true) { [weak self] in
            self?.openInquiry?()
        }
    }

    @objc
    private func onChangeArrivalByTime() {
        updateShowArrivalByTime?(showArrivalByTimeSwitch.isOn)
    }

    @objc
    private func onChangePresenceStatus() {
        updateShowPresenceStatus?(showPresenceStatusSwitch.isOn)
    }

    @objc
    private func onChangeBusTransfer() {
        updateShowBusTransfer?(showBusTransferSwitch.isOn)
    }

    @objc
    private func onChangeSubwayTransfer() {
        subwayDestinationButton.isEnabled = showSubwayTransferSwitch.isOn
        updateShowSubwayTransfer?(showSubwayTransferSwitch.isOn)
    }
}
