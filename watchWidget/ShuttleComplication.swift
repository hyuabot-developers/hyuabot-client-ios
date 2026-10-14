import SwiftUI
import WidgetKit

struct ShuttleComplicationEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: ComplicationSnapshot

    init(snapshot: ComplicationSnapshot) {
        date = snapshot.date
        self.snapshot = snapshot
    }
}

struct ShuttleComplicationProvider: TimelineProvider {
    typealias Entry = ShuttleComplicationEntry

    func placeholder(in context: Context) -> ShuttleComplicationEntry {
        ShuttleComplicationEntry(snapshot: .placeholder(at: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ShuttleComplicationEntry) -> Void) {
        completion(ShuttleComplicationEntry(snapshot: .placeholder(at: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ShuttleComplicationEntry>) -> Void) {
        Task {
            await completion(Self.makeTimeline(now: .now))
        }
    }

    /// Builds the timeline from the selected stop. Falls back to the cached schedule when the network fails, marked stale.
    /// Shows the nearest stop the watch app last found. Falls back to the stop the user last picked when there is none.
    /// A nearest result older than `ComplicationStore.maximumNearestAge` is marked stale.
    static func makeTimeline(now: Date) async -> Timeline<ShuttleComplicationEntry> {
        let nearestStopID = ComplicationStore.nearestStopID()
        let stopID = nearestStopID ?? ComplicationStore.selectedStopID()
        guard let stopID, let stop = ComplicationStops.find(stopID) else {
            return timeline(
                ComplicationTimeline.snapshots(now: now, stopID: nil, schedule: nil, isStale: false),
                refreshAt: now.addingTimeInterval(ComplicationTimeline.window)
            )
        }
        let nearestStale = nearestStopID != nil && isNearestOutdated(now: now)

        do {
            let schedule = try await ComplicationFetcher.schedule(for: stop, now: now)
            ComplicationStore.save(CachedSchedule(stopID: stopID, fetchedAt: now, schedule: schedule))
            return timeline(
                ComplicationTimeline.snapshots(now: now, stopID: stopID, schedule: schedule, isStale: nearestStale),
                refreshAt: ComplicationTimeline.refreshDate(now: now, coverageEnd: schedule.coverageEnd)
            )
        } catch {
            if let cached = ComplicationStore.cachedSchedule(for: stopID),
               now.timeIntervalSince(cached.fetchedAt) <= ComplicationStore.maximumCacheAge
            {
                return timeline(
                    ComplicationTimeline.snapshots(now: now, stopID: stopID, schedule: cached.schedule, isStale: true),
                    refreshAt: now.addingTimeInterval(ComplicationTimeline.retryInterval)
                )
            }
            return timeline(
                ComplicationTimeline.snapshots(now: now, stopID: stopID, schedule: nil, isStale: nearestStale),
                refreshAt: now.addingTimeInterval(ComplicationTimeline.retryInterval)
            )
        }
    }

    private static func isNearestOutdated(now: Date) -> Bool {
        guard let checkedAt = ComplicationStore.nearestCheckedAt() else { return true }
        return now.timeIntervalSince(checkedAt) > ComplicationStore.maximumNearestAge
    }

    private static func timeline(_ snapshots: [ComplicationSnapshot], refreshAt: Date) -> Timeline<ShuttleComplicationEntry> {
        Timeline(entries: snapshots.map { ShuttleComplicationEntry(snapshot: $0) }, policy: .after(refreshAt))
    }
}

struct ShuttleComplication: Widget {
    let kind = "ShuttleComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShuttleComplicationProvider()) { entry in
            ShuttleComplicationView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("다음 셔틀")
        .description("선택한 정류장의 다음 셔틀 출발 시각을 보여줍니다.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
