//
//  SettingsStyle.swift
//  hyuabot
//

import UIKit

enum SettingsStyle {
    enum Color {
        static let background = adaptive(light: 0xF2F4F7, dark: 0x0B0F14)
        static let card = adaptive(light: 0xFFFFFF, dark: 0x161B22)
        static let text = adaptive(light: 0x111827, dark: 0xE8EDF3)
        static let secondaryText = adaptive(light: 0x5B6472, dark: 0x9AA4B2)
        static let separator = adaptive(light: 0xE5E8EC, dark: 0x262D36)
        static let segmentBackground = adaptive(light: 0xE9EDF2, dark: 0x222A33)
        static let accent = HYUColor.Brand.primary
        static let accentFill = HYUColor.Brand.primaryFill
        static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x0B0F14)
        static let switchOff = adaptive(light: 0xD1D5DB, dark: 0x3A434E)
        static let link = HYUColor.Brand.primary
        static let body = adaptive(light: 0x374151, dark: 0xC9D1DC)
        static let toastBackground = adaptive(light: 0x111827, dark: 0xE8EDF3)
        static let toastText = adaptive(light: 0xFFFFFF, dark: 0x0B0F14)
        static let sheet = adaptive(light: 0xFFFFFF, dark: 0x1C222B)
        static let grabber = adaptive(light: 0xC9CED6, dark: 0x3A434E)
        static let highlight = adaptive(light: 0xFDE68A, dark: 0x5C4A12)
        static let highlightText = adaptive(light: 0x111827, dark: 0xFDE68A)
        static let danger = adaptive(light: 0xB91C1C, dark: 0xF87171)
        static let levelGood = adaptive(light: 0x15803D, dark: 0x4ADE80)
        static let levelGoodFill = adaptive(light: 0xDCFCE7, dark: 0x123321)
        static let levelMid = adaptive(light: 0xB45309, dark: 0xFBBF24)
        static let levelMidFill = adaptive(light: 0xFEF3C7, dark: 0x3A2C0B)
        static let levelBusy = adaptive(light: 0xC2410C, dark: 0xFB923C)
        static let levelBusyFill = adaptive(light: 0xFFEDD5, dark: 0x3B200E)
        static let levelFull = adaptive(light: 0xB91C1C, dark: 0xF87171)
        static let levelFullFill = adaptive(light: 0xFEE2E2, dark: 0x3D1618)
        static let faint = adaptive(light: 0x7C8593, dark: 0x7F8896)
        static let commuterFaint = adaptive(light: 0x6B7480, dark: 0x8A93A1)
        static let commuterRail = adaptive(light: 0xC9D3DE, dark: 0x3A4450)
        static let commuterRailTraveled = adaptive(light: 0x9FB4CB, dark: 0x4E6A88)
        static let commuterRailSoft = adaptive(light: 0xD5DCE4, dark: 0x333C47)
        static let commuterNearRow = adaptive(light: 0xEEF6FD, dark: 0x132638)
        static let segmentSelected = adaptive(light: 0xFFFFFF, dark: 0x3A4450)
        static let levelMidText = adaptive(light: 0x7A3E06, dark: 0xFBD38D)
        static let segmentShadow = UIColor(red: 17 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1)
        static let chevron = adaptive(light: 0x8A93A0, dark: 0x6B7480)
        static let tabUnselected = adaptive(light: 0x4B5563, dark: 0xAEB7C3)
        static let supportIconGray = adaptive(light: 0x6B7280, dark: 0x4B5563)
        static let supportIconBlue = adaptive(light: 0x1D6FD1, dark: 0x2F6FB8)
        static let supportIconPink = adaptive(light: 0xD6336C, dark: 0xB4275A)
        static let tabGlass = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 30 / 255, green: 37 / 255, blue: 46 / 255, alpha: 0.72)
                : UIColor(white: 1, alpha: 0.78)
        }

        static let tabEdge = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.10)
                : UIColor(white: 1, alpha: 0.90)
        }

        static let tabSelectionFill = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 127 / 255, green: 178 / 255, blue: 229 / 255, alpha: 0.18)
                : UIColor(red: 14 / 255, green: 74 / 255, blue: 132 / 255, alpha: 0.12)
        }

        static let saturday = adaptive(light: 0x1D4ED8, dark: 0x93C5FD)
        static let sunday = adaptive(light: 0xC62828, dark: 0xFF8A80)
        static let weekSaturday = adaptive(light: 0x1D5FB8, dark: 0x8AB4F8)
        static let cafeteriaGrabber = adaptive(light: 0xC9D0D8, dark: 0x3A4450)
        static let subwaySoon = adaptive(light: 0xC2410C, dark: 0xFDBA74)
        static let subwayLastFill = adaptive(light: 0xFEE2E2, dark: 0x3A1616)
        static let subwayLastText = adaptive(light: 0xB91C1C, dark: 0xFCA5A5)
        static let subwayPast = adaptive(light: 0x8A93A1, dark: 0x6B7480)
        static let subwayCompactBar = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 11 / 255, green: 15 / 255, blue: 20 / 255, alpha: 0.85)
                : UIColor(red: 242 / 255, green: 244 / 255, blue: 247 / 255, alpha: 0.88)
        }

        private static let calendarCategoryStrongColors: [UIColor] = [
            adaptive(light: 0x1D4ED8, dark: 0x93C5FD),
            adaptive(light: 0xC2410C, dark: 0xFDBA74),
            adaptive(light: 0x15803D, dark: 0x86EFAC),
            adaptive(light: 0x7E22CE, dark: 0xD8B4FE)
        ]
        private static let calendarCategoryFillColors: [UIColor] = [
            adaptive(light: 0xDBEAFE, dark: 0x1E3A5F),
            adaptive(light: 0xFFEDD5, dark: 0x43260F),
            adaptive(light: 0xDCFCE7, dark: 0x123321),
            adaptive(light: 0xF3E8FF, dark: 0x2E1A47)
        ]

        static func calendarCategoryStrong(_ categoryID: Int) -> UIColor {
            calendarCategoryStrongColors[((categoryID - 1) % 4 + 4) % 4]
        }

        static func calendarCategoryFill(_ categoryID: Int) -> UIColor {
            calendarCategoryFillColors[((categoryID - 1) % 4 + 4) % 4]
        }

        private static func adaptive(light: UInt32, dark: UInt32) -> UIColor {
            UIColor { traits in
                hex(traits.userInterfaceStyle == .dark ? dark : light)
            }
        }

        private static func hex(_ value: UInt32) -> UIColor {
            UIColor(
                red: CGFloat((value >> 16) & 0xFF) / 255,
                green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1
            )
        }
    }

    enum Tile {
        static let blue = UIColor(red: 0x0E / 255, green: 0x4A / 255, blue: 0x84 / 255, alpha: 1)
        static let indigo = UIColor(red: 0x4F / 255, green: 0x46 / 255, blue: 0xE5 / 255, alpha: 1)
        static let teal = UIColor(red: 0x0F / 255, green: 0x76 / 255, blue: 0x6E / 255, alpha: 1)
        static let slate = UIColor(red: 0x47 / 255, green: 0x55 / 255, blue: 0x69 / 255, alpha: 1)
    }

    enum Metric {
        static let cardRadius: CGFloat = 16
        static let cardInset: CGFloat = 16
        static let sectionHeaderTop: CGFloat = 28
        static let sectionHeaderInsetX: CGFloat = 8
        static let rowMinHeight: CGFloat = 52
        static let iconTileSize: CGFloat = 30
        static let iconTileRadius: CGFloat = 8
        static let separatorInset: CGFloat = 58
        static let segmentRadius: CGFloat = 12
        static let segmentInset: CGFloat = 4
        static let segmentButtonHeight: CGFloat = 36
        static let chipHeight: CGFloat = 20
        static let chipRadius: CGFloat = 10
        static let capsuleRadius: CGFloat = 16
    }

    static func font(_ size: CGFloat, bold: Bool = false) -> UIFont {
        UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont.godo(size: size, weight: bold ? .bold : .regular)
        )
    }

    static func monospacedDigitFont(_ size: CGFloat, bold: Bool = false) -> UIFont {
        let settings = [[
            UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
            UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
        ]]
        let descriptor = UIFont.godo(size: size, weight: bold ? .bold : .regular).fontDescriptor
            .addingAttributes([.featureSettings: settings])
        return UIFontMetrics(forTextStyle: .body).scaledFont(
            for: UIFont(descriptor: descriptor, size: size)
        )
    }

    static func attributedText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        lineHeight: CGFloat,
        alignment: NSTextAlignment = .natural,
        lineBreakMode: NSLineBreakMode = .byWordWrapping
    ) -> NSAttributedString {
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: lineHeight)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = scaled
        paragraphStyle.maximumLineHeight = scaled
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode
        return NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: (scaled - font.lineHeight) / 4
            ]
        )
    }
}

protocol SettingsStyledScreen: UIViewController {}

enum SettingsNavigationStyle {
    static func apply(to viewController: UIViewController, largeTitle: Bool = false) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = SettingsStyle.Color.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: UIFont.godo(size: 17, weight: .bold),
            .foregroundColor: SettingsStyle.Color.text
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
                for: UIFont.godo(size: 32, weight: .bold)
            ),
            .foregroundColor: SettingsStyle.Color.text,
            .kern: -0.5
        ]
        let button = UIBarButtonItemAppearance(style: .plain)
        button.normal.titleTextAttributes = [
            .font: UIFont.godo(size: 16, weight: .regular),
            .foregroundColor: SettingsStyle.Color.link
        ]
        appearance.buttonAppearance = button
        appearance.doneButtonAppearance = button
        appearance.backButtonAppearance = button
        viewController.navigationItem.standardAppearance = appearance.copy()
        viewController.navigationItem.compactAppearance = appearance.copy()
        let scrollEdgeAppearance = appearance.copy()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = appearance.titleTextAttributes
        scrollEdgeAppearance.largeTitleTextAttributes = appearance.largeTitleTextAttributes
        scrollEdgeAppearance.buttonAppearance = button
        scrollEdgeAppearance.doneButtonAppearance = button
        scrollEdgeAppearance.backButtonAppearance = button
        viewController.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
        viewController.navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
        if largeTitle, let bar = viewController.navigationController?.navigationBar {
            bar.prefersLargeTitles = true
            bar.setNeedsLayout()
        }
    }

    static func screenWillAppear(_ viewController: UIViewController) {
        guard let bar = viewController.navigationController?.navigationBar else { return }
        bar.tintColor = SettingsStyle.Color.link
        bar.prefersLargeTitles = true
        bar.setNeedsLayout()
        bar.layoutIfNeeded()
        viewController.tabBarController?.setNeedsStatusBarAppearanceUpdate()
    }

    static func screenWillDisappear(_ viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else { return }
        if let top = navigationController.topViewController, top !== viewController, top is SettingsStyledScreen {
            return
        }
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.prefersLargeTitles = false
        let tabBarController = viewController.tabBarController
        if let coordinator = viewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { context in
                if context.isCancelled {
                    screenWillAppear(viewController)
                }
                tabBarController?.setNeedsStatusBarAppearanceUpdate()
            }
        } else {
            tabBarController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
}
