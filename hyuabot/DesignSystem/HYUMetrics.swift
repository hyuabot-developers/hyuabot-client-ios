//
//  HYUMetrics.swift
//  hyuabot
//

import QuartzCore

enum HYUMetrics {
    enum Space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let badge: CGFloat = 4
        static let row: CGFloat = 8
        static let card: CGFloat = 16
        static let sheet: CGFloat = 24

        static func capsule(height: CGFloat) -> CGFloat {
            height / 2
        }
    }

    enum Layout {
        static let titleToControl: CGFloat = 16
        static let controlToContent: CGFloat = 16
        static let contentToFootnote: CGFloat = 12
        static let screenBottom: CGFloat = 24
        static let tabBarContentGap: CGFloat = 12
        static let headerButtonHeight: CGFloat = 36
        static let headerButtonHitHeight: CGFloat = 44
        static let sheetHorizontalInset: CGFloat = 20
        static let sheetTitleTop: CGFloat = 11
    }

    static let cornerCurve: CALayerCornerCurve = .continuous
}
