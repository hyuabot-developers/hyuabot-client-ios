//
//  DuoLayout.swift
//  hyuabot
//
//  Wide (unfolded iPhone Duo) layout gate. Phone widths never reach the wide path.
//

import UIKit

enum DuoLayout {
    /// Unfolded Duo inner display is ~951pt wide; the folded cover display (~466pt) keeps the phone rules.
    static let wideThreshold: CGFloat = 700
    static let railWidth: CGFloat = 72
    static let primaryColumnWidth: CGFloat = 380

    /// DEBUG-only: `-DuoSimulate wide|cover` pins the root to the Duo point sizes on any simulator.
    static var simulatedSize: CGSize? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-DuoSimulate"), args.indices.contains(i + 1) else { return nil }
        switch args[i + 1] {
        case "wide": return CGSize(width: 951, height: 669)
        case "cover": return CGSize(width: 466, height: 678)
        default: return nil
        }
        #else
        return nil
        #endif
    }

    static func isWide(width: CGFloat, idiom: UIUserInterfaceIdiom) -> Bool {
        guard width >= wideThreshold else { return false }
        return idiom == .phone || simulatedSize != nil
    }
}
