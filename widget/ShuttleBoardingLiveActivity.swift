//
//  ShuttleBoardingLiveActivity.swift
//  hyuabot
//

import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.1, *)
struct ShuttleBoardingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShuttleBoardingActivityAttributes.self) { context in
            TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                ShuttleLiveLockScreenView(attributes: context.attributes, now: timeline.date)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
            .activityBackgroundTint(ShuttleLivePalette.background)
            .activitySystemActionForegroundColor(ShuttleLivePalette.fill)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                        let model = ShuttleLiveModel(attributes: context.attributes, now: timeline.date)
                        HStack(spacing: 6) {
                            ShuttleLiveChip(model: model)
                            Text(verbatim: model.title)
                                .font(.godoCaptionSemibold)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .padding(.leading, 6)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                        let model = ShuttleLiveModel(attributes: context.attributes, now: timeline.date)
                        Text(verbatim: model.bigText)
                            .font(.godo(size: 30, weight: .bold))
                            .foregroundStyle(model.isSoon ? ShuttleLivePalette.soonOnDark : ShuttleLivePalette.islandBlue)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.trailing, 4)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                        let model = ShuttleLiveModel(attributes: context.attributes, now: timeline.date)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbatim: model.subtitle)
                                .font(.godoCaption2)
                                .foregroundStyle(Color.white.opacity(0.78))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.18))
                                    Capsule().fill(ShuttleLivePalette.islandBlue)
                                        .frame(width: proxy.size.width * model.progress)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.horizontal, 6)
                    }
                }
            } compactLeading: {
                TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                    let model = ShuttleLiveModel(attributes: context.attributes, now: timeline.date)
                    HStack(spacing: 4) {
                        ShuttleLiveChip(model: model)
                        Text(verbatim: model.compactLead)
                            .font(.godoCaption2Semibold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            } compactTrailing: {
                TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                    let model = ShuttleLiveModel(attributes: context.attributes, now: timeline.date)
                    Text(verbatim: model.bigText)
                        .font(.godoCaption2Bold)
                        .foregroundStyle(model.isSoon ? ShuttleLivePalette.soonOnDark : ShuttleLivePalette.islandBlue)
                        .monospacedDigit()
                        .frame(maxWidth: 52)
                }
            } minimal: {
                TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                    let model = ShuttleLiveModel(attributes: context.attributes, now: timeline.date)
                    Text(verbatim: model.minutes.map { "\($0)" } ?? "0")
                        .font(.godoCaption2Bold)
                        .foregroundStyle(model.isSoon ? ShuttleLivePalette.soonOnDark : ShuttleLivePalette.islandBlue)
                        .monospacedDigit()
                }
            }
        }
    }
}

private struct ShuttleCheckpointTimelineSchedule: TimelineSchedule {
    let dates: [Date]

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        let endDate = dates.last ?? startDate.addingTimeInterval(60 * 30)
        let interval: TimeInterval = mode == .lowFrequency ? 60 : 15
        let periodicDates = Array(stride(
            from: startDate,
            through: endDate.addingTimeInterval(60),
            by: interval
        ))
        let checkpointDates = dates
            .flatMap { [$0.addingTimeInterval(-60), $0, $0.addingTimeInterval(1)] }
            .filter { $0 >= startDate }
        let entries = Set([startDate] + periodicDates + checkpointDates).sorted()
        return Array(entries.prefix(mode == .lowFrequency ? 32 : 96))
    }
}

private func liveCheckpointStatus(attributes: ShuttleBoardingActivityAttributes, now: Date) -> String {
    let names = attributes.checkpointStopNames
    let times = attributes.checkpointTimes
    guard !names.isEmpty, names.count == times.count else { return "" }
    guard names.count >= 2 else {
        return String(format: attributes.checkpointWaitingFormat, names[0])
    }

    if now < times[0] {
        return String(format: attributes.checkpointWaitingFormat, names[0])
    }

    for index in 1 ..< times.count where now < times[index] && times[index].timeIntervalSince(now) <= 60 {
        return String(format: attributes.checkpointApproachingFormat, names[index])
    }

    for index in stride(from: times.count - 2, through: 0, by: -1) where times[index] <= now {
        return String(format: attributes.checkpointDepartedFormat, names[index])
    }

    return String(format: attributes.checkpointWaitingFormat, names[0])
}

private func liveProgress(attributes: ShuttleBoardingActivityAttributes, fallback: Int, now: Date) -> Int {
    let times = attributes.checkpointTimes
    guard times.count >= 2,
          let start = times.first,
          let end = times.last
    else {
        return fallback
    }
    let totalDuration = end.timeIntervalSince(start)
    guard totalDuration > 0 else { return fallback }
    let elapsed = now.timeIntervalSince(start).clamped(to: 0 ... totalDuration)
    return Int((elapsed * 100) / totalDuration).clamped(to: 0 ... 100)
}

extension Comparable {
    fileprivate func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
