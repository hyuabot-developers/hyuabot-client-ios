//
//  ShuttleQuickSettingsVC.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class ShuttleQuickSettingsVC: UIViewController {
    private static let actionButtonBackground = UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1.00)
    private static let menuForegroundColor = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemBlue : .hanyangBlue
    }

    var openHome: (() -> Void)?
    var openInquiry: (() -> Void)?
    var updateShowArrivalByTime: ((Bool) -> Void)?
    var updateShowDepartureTime: ((Bool) -> Void)?
    var updateShowPresenceStatus: ((Bool) -> Void)?
    var updateShowBusTransfer: ((Bool) -> Void)?
    var updateShowSubwayTransfer: ((Bool) -> Void)?
    var updateSubwayDestination: ((ShuttleSubwayTransferDestination) -> Void)?
    var updateAlternativeDisplayMode: ((ShuttleAlternativeDisplayMode) -> Void)?
    let preferredSheetHeight: CGFloat = 680

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let showArrivalByTimeSwitch = UISwitch()
    private let showDepartureTimeSwitch = UISwitch()
    private let showPresenceStatusSwitch = UISwitch()
    private let showBusTransferSwitch = UISwitch()
    private let showSubwayTransferSwitch = UISwitch()
    private let subwayDestinationButton = UIButton(type: .system)
    private let alternativeModeButton = UIButton(type: .system)
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
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.alwaysBounceVertical = false
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 18, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        let title = UILabel()
        title.text = String(localized: "shuttle.quick_settings.title")
        title.font = .godo(size: 20, weight: .bold)
        title.textColor = .label

        configureControls()
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(displaySettingsGroup())
        contentStack.addArrangedSubview(connectionSettingsGroup())
        contentStack.addArrangedSubview(inquiryActionRow())
        contentStack.addArrangedSubview(homeActionRow())
    }

    private func displaySettingsGroup() -> UIView {
        settingsGroup(
            title: String(localized: "shuttle.quick_settings.section.display"),
            rows: [
                switchSettingRow(
                    title: String(localized: "shuttle.realtime.showByDestination"),
                    hint: String(localized: "shuttle.quick_settings.arrival_by_time.subtitle"),
                    control: showArrivalByTimeSwitch,
                    identifier: "shuttle.quick_settings.arrival_by_time_row"
                ),
                switchSettingRow(
                    title: String(localized: "shuttle.realtime.showDepartureTime"),
                    hint: String(localized: "shuttle.quick_settings.departure_time.subtitle"),
                    control: showDepartureTimeSwitch,
                    identifier: "shuttle.quick_settings.departure_time_row"
                ),
                switchSettingRow(
                    title: String(localized: "shuttle.quick_settings.presence.title"),
                    hint: String(localized: "shuttle.quick_settings.presence.subtitle"),
                    control: showPresenceStatusSwitch,
                    identifier: "shuttle.quick_settings.presence_row"
                )
            ]
        )
    }

    private func connectionSettingsGroup() -> UIView {
        settingsGroup(
            title: String(localized: "shuttle.quick_settings.section.connections"),
            rows: [
                switchSettingRow(
                    title: String(localized: "home.quick_settings.bus50_transfer.title"),
                    hint: String(localized: "home.quick_settings.bus50_transfer.subtitle"),
                    control: showBusTransferSwitch,
                    identifier: "shuttle.quick_settings.bus_transfer_row"
                ),
                switchSettingRow(
                    title: String(localized: "home.quick_settings.subway_transfer.title"),
                    hint: String(localized: "home.quick_settings.subway_transfer.subtitle"),
                    control: showSubwayTransferSwitch,
                    identifier: "shuttle.quick_settings.subway_transfer_row"
                ),
                valueSettingRow(
                    title: String(localized: "shuttle.quick_settings.subway_destination.title"),
                    control: subwayDestinationButton,
                    identifier: "shuttle.quick_settings.subway_destination_row"
                ),
                valueSettingRow(
                    title: String(localized: "shuttle.quick_settings.alternative.title"),
                    control: alternativeModeButton,
                    identifier: "shuttle.quick_settings.alternative_row"
                )
            ],
            footer: String(localized: "shuttle.quick_settings.alternative.subtitle")
        )
    }

    private func configureControls() {
        showArrivalByTimeSwitch.addTarget(self, action: #selector(onChangeArrivalByTime), for: .valueChanged)
        showDepartureTimeSwitch.addTarget(self, action: #selector(onChangeDepartureTime), for: .valueChanged)
        showPresenceStatusSwitch.addTarget(self, action: #selector(onChangePresenceStatus), for: .valueChanged)
        showBusTransferSwitch.addTarget(self, action: #selector(onChangeBusTransfer), for: .valueChanged)
        showSubwayTransferSwitch.addTarget(self, action: #selector(onChangeSubwayTransfer), for: .valueChanged)
        configureMenuButton(subwayDestinationButton)
        configureMenuButton(alternativeModeButton)
        subwayDestinationButton.isEnabled = showSubwayTransferSwitch.isOn
    }

    private func configureMenuButton(_ button: UIButton) {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = Self.menuForegroundColor
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        button.configuration = config
        button.contentHorizontalAlignment = .trailing
        button.showsMenuAsPrimaryAction = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func settingsGroup(title: String, rows: [UIView], footer: String? = nil) -> UIView {
        let section = UIStackView()
        section.axis = .vertical
        section.spacing = 6

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .godo(size: 13, weight: .bold)
        titleLabel.textColor = .secondaryLabel
        section.addArrangedSubview(titleLabel)

        let card = UIStackView()
        card.axis = .vertical
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.clipsToBounds = true
        for (index, row) in rows.enumerated() {
            if index > 0 {
                card.addArrangedSubview(separator())
            }
            card.addArrangedSubview(row)
        }
        section.addArrangedSubview(card)

        if let footer {
            let footerLabel = UILabel()
            footerLabel.text = footer
            footerLabel.font = .godo(size: 12, weight: .regular)
            footerLabel.textColor = .secondaryLabel
            footerLabel.numberOfLines = 0
            section.addArrangedSubview(footerLabel)
            section.setCustomSpacing(8, after: card)
        }
        return section
    }

    private func separator() -> UIView {
        UIView().then {
            $0.backgroundColor = .separator
            $0.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
    }

    private func switchSettingRow(
        title: String,
        hint: String,
        control: UISwitch,
        identifier: String
    ) -> UIView {
        let row = horizontalSettingRow(title: title, control: control, identifier: identifier)
        control.accessibilityLabel = title
        control.accessibilityHint = hint
        control.accessibilityIdentifier = "\(identifier).switch"
        return row
    }

    private func valueSettingRow(title: String, control: UIButton, identifier: String) -> UIView {
        let row = horizontalSettingRow(title: title, control: control, identifier: identifier)
        control.accessibilityLabel = title
        control.accessibilityIdentifier = "\(identifier).menu"
        return row
    }

    private func horizontalSettingRow(title: String, control: UIView, identifier: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 10)
        row.isLayoutMarginsRelativeArrangement = true
        row.accessibilityIdentifier = identifier
        row.isAccessibilityElement = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .godo(size: 15, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85

        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(control)
        row.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        row.setContentHuggingPriority(.required, for: .vertical)
        row.setContentCompressionResistancePriority(.required, for: .vertical)
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

        alternativeModeButton.menu = UIMenu(children: ShuttleAlternativeDisplayMode.allCases.map { mode in
            UIAction(
                title: mode.title,
                state: mode == alternativeDisplayMode ? .on : .off
            ) { [weak self] _ in
                self?.selectAlternativeDisplayMode(mode)
            }
        })
        updateMenuButtonTitle(alternativeModeButton, title: alternativeDisplayMode.title)
    }

    private func updateMenuButtonTitle(_ button: UIButton, title: String) {
        var config = button.configuration
        config?.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.godo(size: 14, weight: .bold)
        ]))
        button.configuration = config
        button.accessibilityValue = title
    }

    private func selectSubwayDestination(_ destination: ShuttleSubwayTransferDestination) {
        subwayDestination = destination
        updateSelectionMenus()
        updateSubwayDestination?(destination)
    }

    private func selectAlternativeDisplayMode(_ mode: ShuttleAlternativeDisplayMode) {
        alternativeDisplayMode = mode
        updateSelectionMenus()
        updateAlternativeDisplayMode?(mode)
    }

    private func homeActionRow() -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = Self.actionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "house.fill")
        config.attributedTitle = AttributedString(String(localized: "home.experience_new"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 17, weight: .bold)
        ]))
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onTapHome), for: .touchUpInside)
        button.accessibilityIdentifier = "shuttle.quick_settings.open_home"
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }

    private func inquiryActionRow() -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = Self.actionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "message")
        config.attributedTitle = AttributedString(String(localized: "inquiry.title"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 17, weight: .bold)
        ]))
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onTapInquiry), for: .touchUpInside)
        button.accessibilityIdentifier = "shuttle.quick_settings.open_inquiry"
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }

    @objc
    private func onTapHome() {
        dismiss(animated: true) { [weak self] in
            self?.openHome?()
        }
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
    private func onChangeDepartureTime() {
        updateShowDepartureTime?(showDepartureTimeSwitch.isOn)
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
