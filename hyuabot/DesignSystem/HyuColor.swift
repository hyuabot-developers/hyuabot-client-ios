import UIKit

enum HyuColor {
    enum bg {
        static let canvas = UIColor.systemGroupedBackground
        static let card = UIColor.secondarySystemGroupedBackground
        static let cardInset = UIColor.tertiarySystemGroupedBackground
        static let fillSubtle = UIColor.tertiarySystemFill
    }

    enum border {
        static let hairline = UIColor.separator
    }

    enum text {
        static let primary = UIColor.label
        static let secondary = UIColor.secondaryLabel
        static let tertiary = UIColor.tertiaryLabel
    }

    enum brand {
        static let bar = UIColor(named: "hanyangBlue")!
        static let onBar = UIColor.white
        static let primary = UIColor(named: "brandPrimary")!
        static let primaryFill = UIColor(named: "brandPrimaryFill")!
    }

    enum status {
        static let realtimeFg = UIColor(named: "statusRealtimeFg")!
        static let realtimeBg = UIColor(named: "statusRealtimeBg")!
        static let scheduledFg = UIColor.secondaryLabel
        static let scheduledBg = UIColor.tertiarySystemFill
        static let imminentFg = UIColor(named: "statusImminentFg")!
        static let imminentBg = UIColor(named: "statusImminentBg")!
        static let lastRunFg = UIColor(named: "statusLastRunFg")!
        static let lastRunBg = UIColor(named: "statusLastRunBg")!
        static let endedFg = UIColor.secondaryLabel
        static let endedBg = UIColor.quaternarySystemFill
        static let staleFg = UIColor(named: "statusStaleFg")!
        static let staleBg = UIColor(named: "statusStaleBg")!
    }

    enum route {
        static let shuttleDH = UIColor(named: "busRed")!
        static let shuttleDY = UIColor(named: "hanyangOrange")!
        static let shuttleDJ = UIColor(named: "hanyangGreen")!
        static let shuttleC = UIColor(named: "busBlue")!
        static let busGreen = UIColor(named: "busGreen")!
        static let busRed = UIColor(named: "busRed")!
        static let subwayLine4 = UIColor(named: "subwaySkyblue")!
        static let subwaySuinBundang = UIColor(named: "subwayYellow")!
        static let subwaySeohae = UIColor(named: "routeSubwaySeohae")!
    }
}
