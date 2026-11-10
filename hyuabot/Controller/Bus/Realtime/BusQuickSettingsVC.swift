//
//  BusQuickSettingsVC.swift
//  hyuabot
//

import SnapKit
import Then
import UIKit

final class BusQuickSettingsVC: UIViewController {
    var openHelp: (() -> Void)?
    var openInquiry: (() -> Void)?
    var updateShowSecondaryEta: ((Bool) -> Void)?
    var updateSeoulTarget: ((BusSeoulTargetStop) -> Void)?
    let preferredSheetHeight: CGFloat = 284

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
        view.backgroundColor = SettingsStyle.Color.busSheetBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.alwaysBounceVertical = false
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 6, left: 0, bottom: 34, right: 0)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.insetsLayoutMarginsFromSafeArea = false
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView.contentLayoutGuide)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }

        let title = UILabel()
        title.text = String(localized: "bus.quick_settings.title")
        title.attributedText = SettingsStyle.attributedText(
            String(localized: "bus.quick_settings.title"),
            font: SettingsStyle.font(20, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 26
        )
        title.adjustsFontForContentSizeCategory = true

        let header = UIStackView(arrangedSubviews: [title])
        header.axis = .horizontal
        header.alignment = .center
        header.distribution = .equalSpacing
        header.isLayoutMarginsRelativeArrangement = true
        header.layoutMargins = .zero
        header.insetsLayoutMarginsFromSafeArea = false
        header.snp.makeConstraints { make in make.height.equalTo(52) }

        configureControls()
        contentStack.addArrangedSubview(header)
        contentStack.addArrangedSubview(settingsGroup())
        contentStack.addArrangedSubview(actionButtonsRow())
    }

    private func actionButtonsRow() -> UIStackView {
        let helpButton = actionButton(
            title: String(localized: "common.help"),
            image: "questionmark.circle",
            identifier: "bus.quick_settings.open_help",
            action: #selector(onTapHelp)
        )
        let inquiryButton = actionButton(
            title: String(localized: "inquiry.title"),
            image: "message",
            identifier: "bus.quick_settings.open_inquiry",
            action: #selector(onTapInquiry)
        )
        let row = UIStackView(arrangedSubviews: [helpButton, inquiryButton])
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        return row
    }

    private func actionButton(title: String, image: String, identifier: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = SettingsStyle.Color.accentFill
        config.background.cornerRadius = 12
        config.baseForegroundColor = SettingsStyle.Color.link
        config.image = UIImage(systemName: image)
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: SettingsStyle.font(15, bold: true),
            .foregroundColor: SettingsStyle.Color.link
        ]))
        config.imagePadding = 8
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityIdentifier = identifier
        button.snp.makeConstraints { make in make.height.equalTo(48) }
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
        card.backgroundColor = SettingsStyle.Color.sheet
        card.layer.cornerRadius = SettingsStyle.Metric.cardRadius
        card.clipsToBounds = true
        card.addArrangedSubview(switchSettingRow(
            title: String(localized: "bus.quick_settings.show_secondary_eta"),
            detail: String(localized: "bus.quick_settings.show_secondary_eta.detail"),
            control: showSecondaryEtaSwitch,
            identifier: "bus.quick_settings.show_secondary_eta_row"
        ))
        card.addArrangedSubview(separator())
        card.addArrangedSubview(valueSettingRow(
            title: String(localized: "bus.quick_settings.seoul_target"),
            detail: String(localized: "bus.quick_settings.seoul_target.detail"),
            control: seoulTargetButton,
            identifier: "bus.quick_settings.seoul_target_row"
        ))
        return card
    }

    private func configureControls() {
        showSecondaryEtaSwitch.onTintColor = SettingsStyle.Color.accent
        showSecondaryEtaSwitch.addTarget(self, action: #selector(onChangeShowSecondaryEta), for: .valueChanged)
        configureMenuButton(seoulTargetButton)
    }

    private func configureMenuButton(_ button: UIButton) {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = SettingsStyle.Color.chevron
        config.image = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
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
            $0.backgroundColor = SettingsStyle.Color.separator
            $0.snp.makeConstraints { make in
                make.height.equalTo(1 / UIScreen.main.scale)
            }
        }
    }

    private func switchSettingRow(title: String, detail: String, control: UISwitch, identifier: String) -> UIView {
        let row = horizontalSettingRow(title: title, detail: detail, control: control, identifier: identifier)
        control.accessibilityLabel = title
        control.accessibilityIdentifier = "\(identifier).switch"
        return row
    }

    private func valueSettingRow(title: String, detail: String, control: UIButton, identifier: String) -> UIView {
        let row = horizontalSettingRow(title: title, detail: detail, control: control, identifier: identifier)
        control.accessibilityLabel = title
        control.accessibilityIdentifier = "\(identifier).menu"
        return row
    }

    private func horizontalSettingRow(title: String, detail: String, control: UIView, identifier: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 12)
        row.isLayoutMarginsRelativeArrangement = true
        row.accessibilityIdentifier = identifier
        row.isAccessibilityElement = false

        let titleLabel = UILabel()
        titleLabel.attributedText = SettingsStyle.attributedText(
            title,
            font: SettingsStyle.font(15, bold: true),
            color: SettingsStyle.Color.text,
            lineHeight: 20
        )
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85

        let detailLabel = UILabel()
        detailLabel.attributedText = SettingsStyle.attributedText(
            detail,
            font: SettingsStyle.font(13),
            color: SettingsStyle.Color.secondaryText,
            lineHeight: 18
        )
        detailLabel.adjustsFontForContentSizeCategory = true
        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = 2
        row.addArrangedSubview(labels)
        row.addArrangedSubview(control)
        row.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
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
            .font: SettingsStyle.font(15, bold: true),
            .foregroundColor: SettingsStyle.Color.link
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
