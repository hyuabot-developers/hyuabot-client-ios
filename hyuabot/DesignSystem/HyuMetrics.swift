//
//  HyuMetrics.swift
//  hyuabot
//

import QuartzCore

enum HyuMetrics {
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
        static let card: CGFloat = 12

        static func capsule(height: CGFloat) -> CGFloat {
            height / 2
        }
    }

    static let cornerCurve: CALayerCornerCurve = .continuous
}
