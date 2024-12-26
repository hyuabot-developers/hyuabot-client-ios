//
//  UIFont.swift
//  hyuabot
//
//  Created by 이정인 on 12/26/24.
//

import Foundation
import SwiftUI

extension Font {
    static private var regularFontName: String = "GodoM"
    static private var mediumFontName: String = "GodoM"
    static private var boldFontName: String = "GodoB"
    static private var semiBoldFontName: String = "GodoB"
    static private var extraBoldFontName: String = "GodoB"
    static private var heavyFontName: String = "GodoB"
    static private var lightFontName: String = "GodoM"
    static private var thinFontName: String = "GodoM"
    static private var ultraLightFontName: String = "GodoM"
    
    private static var preferredSizeTitle: CGFloat = UIFont.preferredFont(forTextStyle: .title1).pointSize
    private static var preferredLargeTitle: CGFloat = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
    private static var preferredExtraLargeTitle: CGFloat {
        if #available(iOS 17.0, *) {
            UIFont.preferredFont(forTextStyle: .extraLargeTitle).pointSize
        } else {
            UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
        }
    }
    private static var preferredExtraLargeTitle2: CGFloat {
        if #available(iOS 17.0, *) {
            UIFont.preferredFont(forTextStyle: .extraLargeTitle2).pointSize
        } else {
            UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
        }
    }
    private static var preferredTitle1: CGFloat = UIFont.preferredFont(forTextStyle: .title1).pointSize
    private static var preferredTitle2: CGFloat = UIFont.preferredFont(forTextStyle: .title2).pointSize
    private static var preferredTitle3: CGFloat = UIFont.preferredFont(forTextStyle: .title3).pointSize
    private static var preferredHeadline: CGFloat = UIFont.preferredFont(forTextStyle: .headline).pointSize
    private static var preferredSubheadline: CGFloat = UIFont.preferredFont(forTextStyle: .subheadline).pointSize
    private static var preferredBody: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize
    private static var preferredCallout: CGFloat = UIFont.preferredFont(forTextStyle: .callout).pointSize
    private static var preferredFootnote: CGFloat = UIFont.preferredFont(forTextStyle: .footnote).pointSize
    private static var preferredCaption1: CGFloat = UIFont.preferredFont(forTextStyle: .caption1).pointSize
    private static var preferredCaption2: CGFloat = UIFont.preferredFont(forTextStyle: .caption2).pointSize
    
    private static var title = Font.custom(regularFontName, size: preferredSizeTitle)
    private static var largeTitle = Font.custom(regularFontName, size: preferredLargeTitle)
    private static var extraLargeTitle = Font.custom(regularFontName, size: preferredExtraLargeTitle)
    private static var extraLargeTitle2 = Font.custom(regularFontName, size: preferredExtraLargeTitle2)
    private static var title1 = Font.custom(regularFontName, size: preferredTitle1)
    private static var title2 = Font.custom(regularFontName, size: preferredTitle2)
    private static var title3 = Font.custom(regularFontName, size: preferredTitle3)
    private static var headline = Font.custom(regularFontName, size: preferredHeadline)
    private static var subheadline = Font.custom(regularFontName, size: preferredSubheadline)
    private static var body = Font.custom(regularFontName, size: preferredBody)
    private static var callout = Font.custom(regularFontName, size: preferredCallout)
    private static var footnote = Font.custom(regularFontName, size: preferredFootnote)
    private static var caption1 = Font.custom(regularFontName, size: preferredCaption1)
    private static var caption2 = Font.custom(regularFontName, size: preferredCaption2)
    
    public static func system(_ style: Font.TextStyle, design: Font.Design? = nil, weight: Font.Weight? = nil) -> Font {
        var size: CGFloat
        var font: String

        switch style {
        case .largeTitle:
            size = preferredLargeTitle
        case .title:
            size = preferredTitle1
        case .title2:
            size = preferredTitle2
        case .title3:
            size = preferredTitle3
        case .headline:
            size = preferredHeadline
        case .subheadline:
            size = preferredSubheadline
        case .body:
            size = preferredBody
        case .callout:
            size = preferredCallout
        case .footnote:
            size = preferredFootnote
        case .caption:
            size = preferredCaption1
        case .caption2:
            size = preferredCaption2
        case .extraLargeTitle:
            size = preferredExtraLargeTitle
        case .extraLargeTitle2:
            size = preferredExtraLargeTitle2
        default:
            size = preferredBody
        }
                
        switch weight {
        case .bold:
            font = boldFontName
        case .regular:
            font = regularFontName
        case .heavy:
            font = heavyFontName
        case .light:
            font = lightFontName
        case .medium:
            font = mediumFontName
        case .semibold:
            font = semiBoldFontName
        case .thin:
            font = thinFontName
        case .ultraLight:
            font = ultraLightFontName
        default:
            font = regularFontName
        }
        
        return Font.custom(font, size: size)
    }
    
    public static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        var font: String
        
        switch weight {
        case .bold:
            font = boldFontName
        case .regular:
            font = regularFontName
        case .heavy:
            font = heavyFontName
        case .light:
            font = lightFontName
        case .medium:
            font = mediumFontName
        case .semibold:
            font = semiBoldFontName
        case .thin:
            font = thinFontName
        case .ultraLight:
            font = ultraLightFontName
        default:
            font = regularFontName
        }
        
        return Font.custom(font, size: size)
    }
}
