//
//  Font.swift
//  hyuabot
//

import SwiftUI
import UIKit

extension Font {
    static func godo(size: CGFloat, weight: UIFont.Weight) -> Font {
        switch weight {
        case .black, .bold, .heavy, .semibold:
            .custom("GodoB", size: size)
        case .light, .medium, .regular, .thin, .ultraLight:
            .custom("GodoM", size: size)
        default:
            .custom("GodoM", size: size)
        }
    }

    static var godoTitle2: Font {
        .godo(size: 22, weight: .bold)
    }

    static var godoTitle3: Font {
        .godo(size: 20, weight: .semibold)
    }

    static var godoHeadline: Font {
        .godo(size: 17, weight: .bold)
    }

    static var godoSubheadline: Font {
        .godo(size: 15, weight: .regular)
    }

    static var godoSubheadlineMedium: Font {
        .godo(size: 15, weight: .medium)
    }

    static var godoSubheadlineBold: Font {
        .godo(size: 15, weight: .bold)
    }

    static var godoSubheadlineSemibold: Font {
        .godo(size: 15, weight: .semibold)
    }

    static var godoBody: Font {
        .godo(size: 17, weight: .regular)
    }

    static var godoCaption: Font {
        .godo(size: 12, weight: .regular)
    }

    static var godoCaptionBold: Font {
        .godo(size: 12, weight: .bold)
    }

    static var godoCaptionSemibold: Font {
        .godo(size: 12, weight: .semibold)
    }

    static var godoCaption2: Font {
        .godo(size: 11, weight: .regular)
    }

    static var godoCaption2Bold: Font {
        .godo(size: 11, weight: .bold)
    }

    static var godoCaption2Semibold: Font {
        .godo(size: 11, weight: .semibold)
    }
}
