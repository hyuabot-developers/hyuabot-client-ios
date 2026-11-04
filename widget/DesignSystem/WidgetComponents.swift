//
//  WidgetComponents.swift
//  hyuabot
//

import AppIntents
import SwiftUI

struct DestinationDot: View {
    let color: Color
    var size: CGFloat = HYUWidgetMetrics.dotSize

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct RouteBadge: View {
    let colorKey: String

    var body: some View {
        Text(verbatim: badgeText)
            .font(.godo(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .frame(
                minWidth: HYUWidgetMetrics.badgeMinWidth,
                minHeight: HYUWidgetMetrics.badgeHeight,
                maxHeight: HYUWidgetMetrics.badgeHeight
            )
            .background(Capsule().fill(HYUWidgetColor.route(forColorKey: colorKey)))
            .fixedSize()
    }

    private var badgeText: String {
        switch colorKey {
        case "line4": "4"
        case "suin": String(localized: "transit.badge.suin")
        default: "50"
        }
    }
}

struct MinutesText: View {
    let minutes: Int
    let size: CGFloat
    let imminent: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(verbatim: String(minutes))
                .font(.godo(size: size, weight: .bold))
                .tracking(-0.02 * size)
                .monospacedDigit()
            Text(verbatim: String(localized: "transit.minutes.suffix"))
                .font(.godo(size: size / 2, weight: .bold))
        }
        .foregroundStyle(imminent ? HYUWidgetColor.imminent : HYUWidgetColor.foreground)
        .lineLimit(1)
        .fixedSize()
    }
}

struct InlineMinutesText: View {
    let minutes: Int
    let size: CGFloat
    var imminent = false

    var body: some View {
        Text(verbatim: "\(minutes)" + String(localized: "transit.minutes.suffix"))
            .font(.godo(size: size, weight: .bold))
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(imminent ? HYUWidgetColor.imminent : HYUWidgetColor.foreground)
    }
}

struct WidgetRefreshStamp<Intent: AppIntent>: View {
    let date: Date?
    let intent: Intent

    var body: some View {
        HStack(spacing: 4) {
            if let date {
                Text(date, style: .time)
                    .font(.godo(size: 11, weight: .regular))
                    .monospacedDigit()
            }
            Button(intent: intent) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(HYUWidgetColor.muted)
        .lineLimit(1)
        .fixedSize()
    }
}

struct WidgetSeparator: View {
    var axis: Axis = .horizontal

    var body: some View {
        Rectangle()
            .fill(HYUWidgetColor.separator)
            .frame(
                maxWidth: axis == .horizontal ? .infinity : nil,
                maxHeight: axis == .vertical ? .infinity : nil
            )
            .frame(width: axis == .vertical ? 1 : nil, height: axis == .horizontal ? 1 : nil)
    }
}

extension View {
    func heroBlock() -> some View {
        padding(.vertical, HYUWidgetMetrics.heroPaddingVertical)
            .padding(.horizontal, HYUWidgetMetrics.heroPaddingHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HYUWidgetMetrics.heroRadius, style: .continuous)
                    .fill(HYUWidgetColor.hero)
            )
    }
}
