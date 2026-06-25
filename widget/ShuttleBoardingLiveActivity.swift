import ActivityKit
import SwiftUI
import WidgetKit

@available(iOSApplicationExtension 16.1, *)
struct ShuttleBoardingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShuttleBoardingActivityAttributes.self) { context in
            TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                let checkpointStatus = liveCheckpointStatus(attributes: context.attributes, now: timeline.date)
                let statusText = joinedStatusText(context.state.statusText, checkpointStatus)
                let progress = liveProgress(attributes: context.attributes, fallback: context.state.progress, now: timeline.date)
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: context.state.titleText)
                        .font(.headline)
                    Text(verbatim: statusText)
                        .font(.subheadline)
                    ShuttleBoardingSegmentedProgress(
                        progress: progress,
                        segments: context.state.progressSegments
                    )
                    ShuttleBoardingStopLabels(
                        names: context.attributes.checkpointStopNames,
                        segments: context.state.progressSegments
                    )
                    ShuttleBoardingCountdownText(departureTime: context.attributes.departureTime)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(hanyangBlue)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: context.state.titleText)
                            .font(.caption2)
                            .foregroundStyle(Color.white.opacity(0.78))
                            .lineLimit(1)
                        Text(context.attributes
                            .alarmKind == "alighting" ? (context.attributes.targetStopName ?? context.attributes.boardingStopName) : context
                            .attributes.boardingStopName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ShuttleBoardingCountdownText(departureTime: context.attributes.departureTime)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 78, alignment: .trailing)
                        .padding(.trailing, -2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimelineView(ShuttleCheckpointTimelineSchedule(dates: context.attributes.checkpointTimes)) { timeline in
                        let checkpointStatus = liveCheckpointStatus(attributes: context.attributes, now: timeline.date)
                        let statusText = joinedStatusText(context.state.dynamicIslandStatusText, checkpointStatus)
                        let progress = liveProgress(attributes: context.attributes, fallback: context.state.progress, now: timeline.date)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Text(verbatim: context.attributes.routeDisplayName)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Color.white)
                                    .lineLimit(1)
                                Text(verbatim: statusText)
                                    .font(.caption2)
                                    .foregroundStyle(Color.white.opacity(0.78))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            ShuttleBoardingDynamicIslandProgress(
                                progress: progress,
                                segments: context.state.progressSegments
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                    }
                }
            } compactLeading: {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.white)
            } compactTrailing: {
                ShuttleBoardingCountdownText(departureTime: context.attributes.departureTime)
                    .monospacedDigit()
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "bus.fill")
                    .foregroundStyle(.white)
            }
        }
    }

    private var hanyangBlue: Color {
        WidgetLiveActivityColor.hanyangBlue
    }
}

private func joinedStatusText(_ base: String, _ checkpointStatus: String) -> String {
    [base, checkpointStatus].filter { !$0.isEmpty }.joined(separator: " · ")
}

private struct ShuttleCheckpointTimelineSchedule: TimelineSchedule {
    let dates: [Date]

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        let endDate = dates.last ?? startDate.addingTimeInterval(60 * 30)
        let interval: TimeInterval = mode == .lowFrequency ? 60 : 15
        let periodicDates = stride(
            from: startDate,
            through: endDate.addingTimeInterval(60),
            by: interval
        ).map { $0 }
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

private struct ShuttleBoardingCountdownText: View {
    let departureTime: Date

    var body: some View {
        if departureTime > Date.now {
            Text(timerInterval: Date.now ... departureTime, countsDown: true)
        } else {
            Text(verbatim: "0:00")
        }
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

private struct ShuttleBoardingDynamicIslandProgress: View {
    let progress: Int
    let segments: [Int]
    private let spacing: CGFloat = 2
    private let hanyangBlue = WidgetLiveActivityColor.hanyangBlue

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(normalizedSegments.indices, id: \.self) { index in
                    let segment = normalizedSegments[index]
                    let segmentStart = normalizedSegments.prefix(index).reduce(0, +)
                    let filled = min(max(progress - segmentStart, 0), segment)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.24))
                        Capsule()
                            .fill(hanyangBlue)
                            .frame(width: segmentWidth(totalWidth: geometry.size.width, segment: filled))
                    }
                    .frame(width: segmentWidth(totalWidth: geometry.size.width, segment: segment), height: 4)
                }
            }
        }
        .frame(height: 4)
    }

    private var normalizedSegments: [Int] {
        let valid = segments.filter { $0 > 0 }
        return valid.isEmpty ? [100] : valid
    }

    private func segmentWidth(totalWidth: CGFloat, segment: Int) -> CGFloat {
        let totalSpacing = CGFloat(max(normalizedSegments.count - 1, 0)) * spacing
        let availableWidth = max(totalWidth - totalSpacing, 0)
        return availableWidth * CGFloat(segment) / 100
    }
}

private struct ShuttleBoardingStopLabels: View {
    let names: [String]
    let segments: [Int]

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(displayNames.enumerated()), id: \.offset) { index, name in
                Text(verbatim: name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.secondary)
                    .frame(width: labelWidth(totalWidth: geometry.size.width), alignment: alignment(for: index))
                    .position(
                        x: labelCenterX(index: index, totalWidth: geometry.size.width),
                        y: 8
                    )
            }
        }
        .frame(height: 16)
    }

    private var displayNames: [String] {
        names.isEmpty ? ["", ""] : names
    }

    private var normalizedSegments: [Int] {
        let valid = segments.filter { $0 > 0 }
        return valid.isEmpty ? [100] : valid
    }

    private func alignment(for index: Int) -> Alignment {
        if displayNames.count == 1 { return .center }
        if index == 0 { return .leading }
        if index == displayNames.count - 1 { return .trailing }
        return .center
    }

    private func labelWidth(totalWidth: CGFloat) -> CGFloat {
        min(max(totalWidth / CGFloat(max(displayNames.count, 1)), 56), 92)
    }

    private func labelCenterX(index: Int, totalWidth: CGFloat) -> CGFloat {
        guard displayNames.count > 1 else {
            return totalWidth / 2
        }
        let labelWidth = labelWidth(totalWidth: totalWidth)
        if index == 0 {
            return labelWidth / 2
        }
        if index == displayNames.count - 1 {
            return totalWidth - labelWidth / 2
        }
        guard normalizedSegments.count == displayNames.count - 1 else {
            let step = totalWidth / CGFloat(displayNames.count - 1)
            return step * CGFloat(index)
        }
        let spacing: CGFloat = 3
        let availableWidth = max(totalWidth - CGFloat(max(normalizedSegments.count - 1, 0)) * spacing, 0)
        let precedingPercent = normalizedSegments.prefix(index).reduce(0, +)
        let boundaryX = availableWidth * CGFloat(precedingPercent) / 100 + spacing * (CGFloat(index) - 0.5)
        return min(max(boundaryX, labelWidth / 2), totalWidth - labelWidth / 2)
    }
}

private struct ShuttleBoardingSegmentedProgress: View {
    let progress: Int
    let segments: [Int]
    private let spacing: CGFloat = 3
    private let hanyangBlue = WidgetLiveActivityColor.hanyangBlue

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: spacing) {
                    ForEach(normalizedSegments.indices, id: \.self) { index in
                        let segment = normalizedSegments[index]
                        let segmentStart = normalizedSegments.prefix(index).reduce(0, +)
                        let filled = min(max(progress - segmentStart, 0), segment)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.22))
                            Capsule()
                                .fill(hanyangBlue)
                                .frame(width: segmentWidth(totalWidth: geometry.size.width, segment: filled))
                        }
                        .frame(width: segmentWidth(totalWidth: geometry.size.width, segment: segment), height: 6)
                    }
                }
                .position(x: geometry.size.width / 2, y: 11)

                ZStack {
                    Circle()
                        .fill(hanyangBlue)
                        .frame(width: 18, height: 18)
                    Image(systemName: "bus.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .position(x: progressX(totalWidth: geometry.size.width), y: 11)
            }
        }
        .frame(height: 20)
    }

    private var normalizedSegments: [Int] {
        let valid = segments.filter { $0 > 0 }
        return valid.isEmpty ? [100] : valid
    }

    private func segmentWidth(totalWidth: CGFloat, segment: Int) -> CGFloat {
        let availableWidth = progressWidth(totalWidth: totalWidth)
        return availableWidth * CGFloat(segment) / 100
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        max(totalWidth - CGFloat(max(normalizedSegments.count - 1, 0)) * spacing, 0)
    }

    private func progressX(totalWidth: CGFloat) -> CGFloat {
        let clampedProgress = min(max(progress, 0), 100)
        let current = progressWidth(totalWidth: totalWidth) * CGFloat(clampedProgress) / 100
        let spacingOffset = progressSpacingOffset(progress: clampedProgress)
        let x = current + spacingOffset
        return min(max(x, 8), max(totalWidth - 8, 8))
    }

    private func progressSpacingOffset(progress: Int) -> CGFloat {
        var remaining = progress
        var passedSegments = 0
        for segment in normalizedSegments {
            if remaining <= segment {
                break
            }
            remaining -= segment
            passedSegments += 1
        }
        return spacing * CGFloat(passedSegments)
    }
}

private enum WidgetLiveActivityColor {
    static let hanyangBlue = Color(red: 0, green: 60 / 255, blue: 130 / 255)
}
