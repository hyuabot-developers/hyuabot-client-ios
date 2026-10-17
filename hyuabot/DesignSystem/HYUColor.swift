//
//  HYUColor.swift
//  hyuabot
//

import UIKit

enum HYUColor {
    enum Background {
        static let canvas = UIColor.systemGroupedBackground
        static let card = UIColor.secondarySystemGroupedBackground
        static let cardInset = UIColor.tertiarySystemGroupedBackground
        static let fillSubtle = UIColor.tertiarySystemFill
    }

    enum Border {
        static let hairline = UIColor.separator
    }

    enum Text {
        static let primary = UIColor.label
        /// Light mode uses a fixed gray (#636366, 5.99:1 on white). The system `secondaryLabel` is only
        /// about 3.4:1 on white in light mode, below WCAG AA 4.5:1. Dark mode keeps the system color.
        static let secondary = UIColor(dynamicProvider: { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor.secondaryLabel.resolvedColor(with: traits)
            }
            return UIColor(red: 99.0 / 255.0, green: 99.0 / 255.0, blue: 102.0 / 255.0, alpha: 1.0)
        })
        static let tertiary = UIColor.tertiaryLabel
    }

    enum Brand {
        static let bar = assetColor(named: "hanyangBlue")
        static let onBar = UIColor.white
        static let primary = assetColor(named: "brandPrimary")
        static let primaryFill = assetColor(named: "brandPrimaryFill")
    }

    enum Status {
        static let realtimeFg = assetColor(named: "statusRealtimeFg")
        static let realtimeBg = assetColor(named: "statusRealtimeBg")
        static let scheduledFg = UIColor.secondaryLabel
        static let scheduledBg = UIColor.tertiarySystemFill
        static let imminentFg = assetColor(named: "statusImminentFg")
        static let imminentBg = assetColor(named: "statusImminentBg")
        static let lastRunFg = assetColor(named: "statusLastRunFg")
        static let lastRunBg = assetColor(named: "statusLastRunBg")
        static let endedFg = UIColor.secondaryLabel
        static let endedBg = UIColor.quaternarySystemFill
        static let staleFg = assetColor(named: "statusStaleFg")
        static let staleBg = assetColor(named: "statusStaleBg")
    }

    enum Route {
        static let shuttleDH = assetColor(named: "busRed")
        static let shuttleDY = assetColor(named: "hanyangOrange")
        static let shuttleDJ = assetColor(named: "hanyangGreen")
        static let shuttleC = assetColor(named: "busBlue")
        static let busGreen = assetColor(named: "busGreen")
        static let busRed = assetColor(named: "busRed")
        static let subwayLine4 = assetColor(named: "subwaySkyblue")
        static let subwaySuinBundang = assetColor(named: "subwayYellow")
        static let subwaySeohae = assetColor(named: "routeSubwaySeohae")
    }

    private static func assetColor(named name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            assertionFailure("Missing color asset: \(name)")
            return .clear
        }
        return color
    }
}
