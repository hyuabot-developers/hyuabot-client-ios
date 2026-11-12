//
//  ShuttleLiveViews.swift
//  hyuabot
//

import SwiftUI
import UIKit
import WidgetKit

enum ShuttleLivePalette {
    private static func adaptive(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        Color(uiColor: UIColor { trait in
            let isDark = trait.userInterfaceStyle == .dark
            let hex = isDark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: isDark ? darkAlpha : lightAlpha
            )
        })
    }

    static let background = adaptive(light: 0xFFFFFF, dark: 0x161B22, lightAlpha: 0.86, darkAlpha: 0.88)
    static let text = adaptive(light: 0x111827, dark: 0xE8EDF3)
    static let sub = adaptive(light: 0x5B6472, dark: 0x9AA4B2)
    static let track = adaptive(light: 0xD9DEE5, dark: 0x2B333D)
    static let halo = adaptive(light: 0xF1F4F8, dark: 0x1A2029)
    static let fill = adaptive(light: 0x0E4A84, dark: 0x7FB2E5)
    static let soon = adaptive(light: 0xC2410C, dark: 0xFDBA74)
    static let soonOnDark = Color(red: 0xFD / 255, green: 0xBA / 255, blue: 0x74 / 255)
    static let islandBlue = Color(red: 0x7F / 255, green: 0xB2 / 255, blue: 0xE5 / 255)

    static func chip(_ kind: String?) -> Color {
        switch kind {
        case "circular": Color(red: 0x1D / 255, green: 0x4E / 255, blue: 0xD8 / 255)
        case "jungang": Color(red: 0x00 / 255, green: 0x7A / 255, blue: 0x5A / 255)
        case "terminal": Color(red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255)
        case "fallback": Color(red: 0x5B / 255, green: 0x64 / 255, blue: 0x72 / 255)
        default: Color(red: 0xD1 / 255, green: 0x00 / 255, blue: 0x1C / 255)
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
struct ShuttleLiveModel {
    enum Phase { case wait, ride, soon }

    let attributes: ShuttleBoardingActivityAttributes
    let now: Date

    private var isAlighting: Bool {
        attributes.alarmKind == "alighting"
    }

    private var names: [String] {
        attributes.checkpointStopNames
    }

    private var times: [Date] {
        attributes.checkpointTimes
    }

    private var endName: String {
        attributes.targetStopName ?? names.last ?? attributes.boardingStopName
    }

    private var endTime: Date {
        times.last ?? attributes.departureTime
    }

    var minutes: Int? {
        let seconds = attributes.departureTime.timeIntervalSince(now)
        return max(0, Int((seconds / 60).rounded(.up)))
    }

    var phase: Phase {
        guard isAlighting else { return .wait }
        return (minutes ?? 0) <= 2 ? .soon : .ride
    }

    var isSoon: Bool {
        phase == .soon
    }

    var chipText: String {
        attributes.routeDisplayName
    }

    var statusText: String {
        switch phase {
        case .wait: String(localized: "shuttle.live.status.boarding")
        case .ride: String(format: String(localized: "shuttle.live.status.alighting.%@"), endName)
        case .soon: String(localized: "shuttle.live.status.soon")
        }
    }

    var title: String {
        switch phase {
        case .wait:
            String(
                format: String(localized: "shuttle.live.title.boarding.%@.%@"),
                attributes.boardingStopName,
                Self.clock(attributes.departureTime)
            )
        case .ride:
            String(format: String(localized: "shuttle.live.title.ride.%@"), endName)
        case .soon:
            String(format: String(localized: "shuttle.live.title.soon.%@"), endName)
        }
    }

    var subtitle: String {
        let arrival = "\(names.last ?? endName) \(Self.clock(endTime))"
        switch phase {
        case .wait:
            return String(format: String(localized: "shuttle.live.sub.wait.%@.%@"), attributes.boardingStopName, arrival)
        case .ride:
            let passed = Array(zip(names, times)).last { $0.1 <= now && $0.0 != names.last }?.0 ?? attributes.boardingStopName
            return String(format: String(localized: "shuttle.live.sub.ride.%@.%@"), passed, arrival)
        case .soon:
            return String(format: String(localized: "shuttle.live.sub.soon.%@"), Self.clock(endTime))
        }
    }

    var bigLabel: String {
        phase == .wait ? String(localized: "shuttle.live.until_departure") : String(localized: "shuttle.live.until_arrival")
    }

    var bigText: String {
        String(format: String(localized: "shuttle.live.minutes.%d"), minutes ?? 0)
    }

    var compactLead: String {
        phase == .wait ? attributes.boardingStopName : endName
    }

    var progress: Double {
        guard times.count >= 2, let start = times.first, let end = times.last else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }

    /// First, middle and last checkpoint used by the 3-stop track.
    var track: [(name: String, time: Date)] {
        guard names.count == times.count, names.count >= 2 else { return [] }
        let middle = names.count / 2
        let indices = names.count == 2 ? [0, 1] : [0, middle, names.count - 1]
        return indices.map { (names[$0], times[$0]) }
    }

    static func clock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

@available(iOSApplicationExtension 16.1, *)
struct ShuttleLiveChip: View {
    let model: ShuttleLiveModel

    var body: some View {
        Text(verbatim: model.chipText)
            .font(.godo(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .frame(minWidth: 20, minHeight: 20)
            .background(ShuttleLivePalette.chip(model.attributes.routeChipKind), in: RoundedRectangle(cornerRadius: 6))
    }
}

@available(iOSApplicationExtension 16.1, *)
struct ShuttleLiveLockScreenView: View {
    let attributes: ShuttleBoardingActivityAttributes
    let now: Date

    private var model: ShuttleLiveModel {
        ShuttleLiveModel(attributes: attributes, now: now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bus.fill")
                    .font(.godo(size: 13, weight: .bold))
                    .foregroundStyle(ShuttleLivePalette.fill)
                Text(verbatim: model.statusText)
                    .font(.godo(size: 13, weight: .bold))
                    .foregroundStyle(ShuttleLivePalette.sub)
                    .lineLimit(1)
            }
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        ShuttleLiveChip(model: model)
                        Text(verbatim: model.title)
                            .font(.godo(size: 15, weight: .bold))
                            .foregroundStyle(ShuttleLivePalette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    Text(verbatim: model.subtitle)
                        .font(.godo(size: 13, weight: .regular))
                        .foregroundStyle(ShuttleLivePalette.sub)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(verbatim: model.bigLabel)
                        .font(.godo(size: 12, weight: .regular))
                        .foregroundStyle(ShuttleLivePalette.sub)
                    Text(verbatim: model.bigText)
                        .font(.godo(size: 34, weight: .bold))
                        .foregroundStyle(model.isSoon ? ShuttleLivePalette.soon : ShuttleLivePalette.text)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            if model.track.count >= 2 {
                ShuttleLiveTrack(model: model)
            }
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct ShuttleLiveTrack: View {
    let model: ShuttleLiveModel

    var body: some View {
        let stops = model.track
        VStack(spacing: 6) {
            GeometryReader { proxy in
                let columnWidth = proxy.size.width / CGFloat(stops.count)
                let startX = columnWidth / 2
                let endX = proxy.size.width - columnWidth / 2
                let span = endX - startX
                ZStack(alignment: .leading) {
                    Capsule().fill(ShuttleLivePalette.track)
                        .frame(width: span, height: 3)
                        .offset(x: startX)
                    Capsule().fill(ShuttleLivePalette.fill)
                        .frame(width: span * model.progress, height: 3)
                        .offset(x: startX)
                    ForEach(stops.indices, id: \.self) { index in
                        let isEnd = index == stops.count - 1
                        let size: CGFloat = isEnd ? 11 : 8
                        Circle()
                            .fill(isEnd ? ShuttleLivePalette.halo : ShuttleLivePalette.fill)
                            .overlay(Circle().stroke(ShuttleLivePalette.fill, lineWidth: isEnd ? 2.5 : 0))
                            .frame(width: size, height: size)
                            .offset(x: startX + span * CGFloat(index) / CGFloat(stops.count - 1) - size / 2)
                    }
                    ZStack {
                        Circle().fill(ShuttleLivePalette.halo)
                        Image(systemName: "bus.fill")
                            .font(.godo(size: 12, weight: .bold))
                            .foregroundStyle(ShuttleLivePalette.fill)
                    }
                    .frame(width: 24, height: 24)
                    .offset(x: startX + span * model.progress - 12)
                }
                .frame(height: 24)
            }
            .frame(height: 24)
            HStack(spacing: 0) {
                ForEach(stops.indices, id: \.self) { index in
                    let isEnd = index == stops.count - 1
                    Text(verbatim: "\(stops[index].name) \(ShuttleLiveModel.clock(stops[index].time))")
                        .font(.godo(size: 12, weight: isEnd ? .bold : .regular))
                        .foregroundStyle(isEnd ? ShuttleLivePalette.text : ShuttleLivePalette.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
