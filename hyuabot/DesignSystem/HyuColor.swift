//
//  HyuColor.swift
//  hyuabot
//

import UIKit

enum HyuColor {
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
        static let secondary = UIColor.secondaryLabel
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
