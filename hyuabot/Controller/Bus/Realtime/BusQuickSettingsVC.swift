//
//  BusQuickSettingsVC.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class BusQuickSettingsVC: UIViewController {
    private static let actionButtonBackground = UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1.00)
    private static let menuForegroundColor = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .systemBlue : .hanyangBlue
    }

    var openHelp: (() -> Void)?
    var openInquiry: (() -> Void)?
    var updateShowSecondaryEta: ((Bool) -> Void)?
    var updateSeoulTarget: ((BusSeoulTargetStop) -> Void)?
    let preferredSheetHeight: CGFloat = 380

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let showSecondaryEtaSwitch = UISwitch()
    private let seoulTargetButton = UIButton(type: .system)
    private var seoulTarget: BusSeoulTargetStop

    init(showSecondaryEta: Bool, seoulTarget: BusSeoulTargetStop) {
        self.seoulTarget = seoulTarget
        showSecondaryEtaSwitch.isOn = showSecondaryEta
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateSelectionMenu()
    }
}

extension BusQuickSettingsVC {
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
        title.text = String(localized: "bus.quick_settings.title")
        title.font = .godo(size: 20, weight: .bold)
        title.textColor = .label

        configureControls()
        contentStack.addArrangedSubview(title)
        contentStack.addArrangedSubview(settingsGroup())
        contentStack.addArrangedSubview(helpActionRow())
        contentStack.addArrangedSubview(inquiryActionRow())
    }

    private func helpActionRow() -> UIView {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = Self.actionButtonBackground
        config.baseForegroundColor = .hanyangBlue
        config.cornerStyle = .medium
        config.image = UIImage(systemName: "questionmark.circle")
        config.attributedTitle = AttributedString(String(localized: "common.help"), attributes: AttributeContainer([
            .font: UIFont.godo(size: 17, weight: .bold)
        ]))
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(onTapHelp), for: .touchUpInside)
        button.accessibilityIdentifier = "bus.quick_settings.open_help"
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
        button.accessibilityIdentifier = "bus.quick_settings.open_inquiry"
        button.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        return button
    }

    @objc
    private func onTapHelp() {
        dismiss(animated: true) { [weak self] in
            self?.openHelp?()
        }
    }

    @objc
    private func onTapInquiry() {
        dismiss(animated: true) { [weak self] in
            self?.openInquiry?()
        }
    }

    private func settingsGroup() -> UIView {
        let card = UIStackView()
        card.axis = .vertical
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.clipsToBounds = true
        card.addArrangedSubview(switchSettingRow(
            title: String(localized: "bus.quick_settings.show_secondary_eta"),
            control: showSecondaryEtaSwitch,
            identifier: "bus.quick_settings.show_secondary_eta_row"
        ))
        card.addArrangedSubview(separator())
        card.addArrangedSubview(valueSettingRow(
            title: String(localized: "bus.quick_settings.seoul_target"),
            control: seoulTargetButton,
            identifier: "bus.quick_settings.seoul_target_row"
        ))
        return card
    }

    private func configureControls() {
        showSecondaryEtaSwitch.addTarget(self, action: #selector(onChangeShowSecondaryEta), for: .valueChanged)
        configureMenuButton(seoulTargetButton)
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

    private func separator() -> UIView {
        UIView().then {
            $0.backgroundColor = .separator
            $0.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
    }

    private func switchSettingRow(title: String, control: UISwitch, identifier: String) -> UIView {
        let row = horizontalSettingRow(title: title, control: control, identifier: identifier)
        control.accessibilityLabel = title
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

    private func updateSelectionMenu() {
        seoulTargetButton.menu = UIMenu(children: BusSeoulTargetStop.allCases.map { target in
            UIAction(
                title: target.title,
                state: target == seoulTarget ? .on : .off
            ) { [weak self] _ in
                self?.selectSeoulTarget(target)
            }
        })
        updateMenuButtonTitle(seoulTargetButton, title: seoulTarget.title)
    }

    private func updateMenuButtonTitle(_ button: UIButton, title: String) {
        var config = button.configuration
        config?.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.godo(size: 14, weight: .bold)
        ]))
        button.configuration = config
        button.accessibilityValue = title
    }

    private func selectSeoulTarget(_ target: BusSeoulTargetStop) {
        seoulTarget = target
        updateSelectionMenu()
        updateSeoulTarget?(target)
    }

    @objc
    private func onChangeShowSecondaryEta() {
        seoulTargetButton.isEnabled = showSecondaryEtaSwitch.isOn
        updateShowSecondaryEta?(showSecondaryEtaSwitch.isOn)
    }
}
