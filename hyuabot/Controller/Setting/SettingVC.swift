//
//  SettingVC.swift
//  hyuabot
//

import SafariServices
import SnapKit
import UIKit
import WidgetKit

final class SettingVC: UIViewController, SettingsStyledScreen {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let campusCard = SettingsCampusCardView()
    private let themePicker = SettingsThemePickerView()
    private let analyticsSwitch = UISwitch()
    private var languageRow: SettingsRowView?

    override func viewDidLoad() {
        super.viewDidLoad()
        SettingsNavigationStyle.apply(to: self, largeTitle: true)
        navigationItem.title = String(localized: "tabbar.setting")
        if UserDefaults.standard.integer(forKey: "campusID") == 0 {
            UserDefaults.standard.set(2, forKey: "campusID")
            UserDefaults(suiteName: "group.net.jaram.hyuabot")?.set(2, forKey: "campusID")
        }
        buildLayout()
        campusCard.setCampusID(UserDefaults.standard.integer(forKey: "campusID"))
        campusCard.onSelectCampus = { [weak self] in self?.applyCampus($0) }
        themePicker.setThemeID(UserDefaults.standard.integer(forKey: "themeID"))
        themePicker.onSelectTheme = { [weak self] in self?.applyTheme($0) }
        analyticsSwitch.accessibilityIdentifier = "setting.analytics_switch"
        analyticsSwitch.isOn = AnalyticsManager.isCollectionEnabled
        analyticsSwitch.addAction(UIAction { [weak self] action in
            guard let toggle = action.sender as? UISwitch else { return }
            self?.setAnalyticsConsent(toggle.isOn)
        }, for: .valueChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logScreenView(.setting)
        if CoachMarkManager.shared.shouldShowPage("setting") {
            DispatchQueue.main.async { [weak self] in self?.presentSettingsCoachMarks() }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingsNavigationStyle.screenWillAppear(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingsToastView.dismiss(in: navigationController?.view ?? view)
        SettingsNavigationStyle.screenWillDisappear(self)
    }

    private func buildLayout() {
        view.backgroundColor = SettingsStyle.Color.background
        scrollView.alwaysBounceVertical = true
        scrollView.accessibilityIdentifier = "setting.scroll"
        scrollView.contentInsetAdjustmentBehavior = .automatic
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
        }
        setContentScrollView(scrollView, for: .top)
        buildCampusSection()
        buildDisplaySection()
        buildPrivacySection()
        buildSupportSection()
        buildFooter()
    }

    private func buildCampusSection() {
        let topInset = UIView()
        topInset.snp.makeConstraints { $0.height.equalTo(4) }
        contentStack.addArrangedSubview(topInset)
        let container = UIView()
        container.addSubview(campusCard)
        campusCard.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        contentStack.addArrangedSubview(container)
    }

    private func buildDisplaySection() {
        let card = SettingsCardView()
        card.addRow(themePicker)
        let locale = Locale.current.localizedString(forIdentifier: Bundle.main.preferredLocalizations.first ?? "ko") ?? ""
        let row = SettingsRowView(
            symbolName: "globe",
            tileColor: SettingsStyle.Tile.teal,
            title: String(localized: "setting.language"),
            accessory: .valueAndExternalLink(
                locale,
                accessibilityLabel: String(localized: "setting.language.open_settings")
            )
        )
        row.onTap = {
            AnalyticsManager.logSelect(.settingSelectRow, type: .listItem, name: "setting.language")
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
        languageRow = row
        card.addRow(row)
        contentStack.addArrangedSubview(SettingsSectionView(
            header: String(localized: "setting.section.display"),
            content: card,
            footer: String(localized: "setting.language.footer")
        ))
    }

    private func buildPrivacySection() {
        let card = SettingsCardView()
        let analytics = SettingsRowView(
            symbolName: "chart.bar.fill",
            tileColor: SettingsStyle.Tile.slate,
            title: String(localized: "setting.analytics"),
            subtitle: String(localized: "setting.analytics.subtitle"),
            accessory: .toggle(analyticsSwitch),
            verticalPadding: 12
        )
        card.addRow(analytics)
        card.addRow(makeActionRow(
            "lock.shield.fill", SettingsStyle.Tile.slate, "setting.privacy_policy", .externalLink, "setting.privacy_policy"
        ) { $0.openPrivacyPolicy() })
        contentStack.addArrangedSubview(SettingsSectionView(header: String(localized: "setting.section.privacy"), content: card))
    }

    private func buildSupportSection() {
        let card = SettingsCardView()
        card.addRow(makeActionRow(
            "questionmark.circle.fill", SettingsStyle.Tile.blue, "setting.help", .externalLink, "setting.help"
        ) { $0.openHelp() })
        card.addRow(makeActionRow(
            "sparkles", SettingsStyle.Tile.blue, "setting.coachmark.reset",
            .action(String(localized: "setting.coachmark.reset.action")), "setting.coachmark.reset"
        ) { controller in
            controller.resetCoachMarks()
            SettingsToastView.show(
                message: String(localized: "toast.coachmark.reset.complete"),
                in: controller.navigationController?.view ?? controller.view
            )
        })
        card.addRow(makeActionRow(
            "doc.text.fill", SettingsStyle.Tile.slate, "setting.open_source_licenses", .chevron,
            "setting.open_source_licenses"
        ) { controller in
            let licenses = OpenSourceLicensesVC()
            licenses.hidesBottomBarWhenPushed = true
            controller.navigationController?.pushViewController(licenses, animated: true)
        })
        contentStack.addArrangedSubview(SettingsSectionView(header: String(localized: "setting.section.support"), content: card))
    }

    private func buildFooter() {
        let info = Bundle.main.infoDictionary
        let localized = Bundle.main.localizedInfoDictionary
        let appName = (localized?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String) ?? ""
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        contentStack.addArrangedSubview(SettingsAppInfoFooterView(
            appName: appName,
            versionText: "\(String(localized: "setting.version")) · \(version)",
            developerText: "\(String(localized: "setting.developer")) · \(String(localized: "setting.developer.info"))"
        ))
    }

    private func makeActionRow(
        _ symbol: String,
        _ color: UIColor,
        _ titleKey: String,
        _ accessory: SettingsRowAccessory,
        _ analyticsName: String,
        action: @escaping (SettingVC) -> Void
    ) -> SettingsRowView {
        let row = SettingsRowView(
            symbolName: symbol,
            tileColor: color,
            title: String(localized: String.LocalizationValue(titleKey)),
            accessory: accessory
        )
        row.onTap = { [weak self] in
            guard let self else { return }
            AnalyticsManager.logSelect(.settingSelectRow, type: .listItem, name: analyticsName)
            action(self)
        }
        return row
    }

    private func applyCampus(_ campusID: Int) {
        let campusName = campusID == 1 ? String(localized: "campus.seoul") : String(localized: "campus.erica")
        AnalyticsManager.logSelect(.settingSelectCampus, type: .menu, name: campusID == 1 ? "seoul" : "erica")
        UserDefaults.standard.set(campusID, forKey: "campusID")
        UserDefaults(suiteName: "group.net.jaram.hyuabot")?.set(campusID, forKey: "campusID")
        WidgetCenter.shared.reloadTimelines(ofKind: "CafeteriaWidget")
        SettingsToastView.show(
            message: String(format: String(localized: "toast.campus.changed.%@"), campusName),
            in: navigationController?.view ?? view
        )
    }

    private func applyTheme(_ themeID: Int) {
        let name = ["system", "light", "dark"].indices.contains(themeID) ? ["system", "light", "dark"][themeID] : "system"
        themePicker.setThemeID(themeID)
        AnalyticsManager.logSelect(.settingSelectTheme, type: .menu, name: name)
        UserDefaults.standard.set(themeID, forKey: "themeID")
        let style: UIUserInterfaceStyle = themeID == 1 ? .light : themeID == 2 ? .dark : .unspecified
        view.window?.overrideUserInterfaceStyle = style
        tabBarController?.setNeedsStatusBarAppearanceUpdate()
    }

    private func setAnalyticsConsent(_ isEnabled: Bool) { AnalyticsManager.setCollectionEnabled(isEnabled) }

    private func openHelp() {
        let lang = Bundle.main.preferredLocalizations.first ?? "ko"
        let localePath = lang.hasPrefix("en") ? "en/" : lang.hasPrefix("ja") ? "ja/" : lang.hasPrefix("zh") ? "zh-Hans/" : ""
        guard let url = URL(string: "https://hyuabot-developers.github.io/\(localePath)docs/ios") else { return }
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true)
    }

    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://hyuabot-developers.github.io/privacy-policy") else { return }
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true)
    }

    private func resetCoachMarks() { CoachMarkManager.shared.resetAll() }

    private func presentSettingsCoachMarks() {
        let items = [
            CoachMarkItem(
                id: "setting.0",
                targetView: campusCard,
                title: String(localized: "coach.setting.campus.title"),
                message: String(localized: "coach.setting.campus.message")
            ),
            CoachMarkItem(
                id: "setting.1",
                targetView: themePicker,
                title: String(localized: "coach.setting.theme.title"),
                message: String(localized: "coach.setting.theme.message")
            ),
            CoachMarkItem(
                id: "setting.2",
                targetView: languageRow ?? campusCard,
                title: String(localized: "coach.setting.language.title"),
                message: String(localized: "coach.setting.language.message")
            )
        ]
        presentCoachMarks(pageId: "setting", items: items)
    }
}
