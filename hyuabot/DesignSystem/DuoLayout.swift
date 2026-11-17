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
    /// No phone screen has a short side this large; the unfolded Duo inner display does (669pt).
    static let innerDisplayMinSide: CGFloat = 600
    static let railWidth: CGFloat = 72
    /// Rail inset from the trailing edge; it lives inside the system strip that carries the clock and Wi-Fi.
    static let railTrailing: CGFloat = 6
    /// Estimated bottom of the system clock / Wi-Fi block on the inner display (measured from screenshots; no API reports it).
    static let railTop: CGFloat = 108
    /// Space the rail occupies from the trailing edge; right-hand content stays clear of it in either landscape direction.
    static let railClearance: CGFloat = railWidth + railTrailing
    /// Gutter between the left column's content and the fold.
    static let foldGutter: CGFloat = 24

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
