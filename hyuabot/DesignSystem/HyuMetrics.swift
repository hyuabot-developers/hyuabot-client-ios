import QuartzCore

enum HyuMetrics {
    enum space {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 32
    }

    enum radius {
        static let badge: CGFloat = 4
        static let row: CGFloat = 8
        static let card: CGFloat = 12

        static func capsule(height: CGFloat) -> CGFloat {
            height / 2
        }
    }

    static let cornerCurve: CALayerCornerCurve = .continuous
}
