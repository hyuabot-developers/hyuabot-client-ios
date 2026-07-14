//
//  ContentView.swift
//  watch Watch App
//
//  Created by 이정인 on 4/12/25.
//

import Api
import CoreLocation
import SwiftUI

struct WatchShuttleStop: Hashable {
    let id: String
    let queryStops: [String]
    let localizationKey: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    var localizedName: String {
        WatchLocalization.text(localizationKey)
    }

    static let all: [WatchShuttleStop] = [
        WatchShuttleStop(
            id: "dormitory", queryStops: ["dormitory_o"], localizationKey: "stop.dormitory",
            latitude: 37.29339607529377, longitude: 126.83630604103446
        ),
        WatchShuttleStop(
            id: "shuttlecock", queryStops: ["shuttlecock_o", "shuttlecock_i"], localizationKey: "stop.shuttlecock",
            latitude: 37.29875417910844, longitude: 126.83784054072336
        ),
        WatchShuttleStop(
            id: "station", queryStops: ["station"], localizationKey: "stop.station",
            latitude: 37.309700971618255, longitude: 126.85207173389148
        ),
        WatchShuttleStop(
            id: "terminal", queryStops: ["terminal"], localizationKey: "stop.terminal",
            latitude: 37.319338173415936, longitude: 126.8455263115596
        ),
        WatchShuttleStop(
            id: "jungang", queryStops: ["jungang_stn"], localizationKey: "stop.jungang",
            latitude: 37.31487247528457, longitude: 126.83963540399434
        )
    ]

    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

enum WatchLocalization {
    static func text(_ key: String) -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "ko"
        let table = values[language] ?? values["ko"]!
        return table[key] ?? values["ko"]?[key] ?? key
    }

    private static let values: [String: [String: String]] = [
        "ko": [
            "stop.dormitory": "기숙사",
            "stop.shuttlecock": "셔틀콕",
            "stop.station": "한대앞",
            "stop.terminal": "예술인",
            "stop.jungang": "중앙역",
            "route.circular": "순환",
            "route.direct": "직행",
            "no.scheduled.shuttle": "도착 예정인\n셔틀이 없습니다.",
            "finding.nearest.stop": "가까운 정류장을 찾고 있습니다",
            "nearest.stop": "가장 가까운 정류장",
            "other.stops": "다른 정류장 보기",
            "load.failed": "시간표를 불러오지 못했습니다.",
            "retry": "다시 시도"
        ],
        "en": [
            "stop.dormitory": "Dormitory",
            "stop.shuttlecock": "Shuttlecock",
            "stop.station": "Station",
            "stop.terminal": "Terminal",
            "stop.jungang": "Jungang Stn.",
            "route.circular": "Circular",
            "route.direct": "Direct",
            "no.scheduled.shuttle": "No scheduled\nshuttle.",
            "finding.nearest.stop": "Finding the nearest stop",
            "nearest.stop": "Nearest stop",
            "other.stops": "Other stops",
            "load.failed": "Couldn’t load the timetable.",
            "retry": "Retry"
        ],
        "ja": [
            "stop.dormitory": "寮",
            "stop.shuttlecock": "シャトルコック",
            "stop.station": "韓大前駅",
            "stop.terminal": "芸術人村",
            "stop.jungang": "中央駅",
            "route.circular": "循環",
            "route.direct": "直行",
            "no.scheduled.shuttle": "予定されている\nシャトルがありません。",
            "finding.nearest.stop": "最寄りの停留所を検索中",
            "nearest.stop": "最寄りの停留所",
            "other.stops": "他の停留所を見る",
            "load.failed": "時刻表を読み込めませんでした。",
            "retry": "再試行"
        ],
        "zh": [
            "stop.dormitory": "宿舍",
            "stop.shuttlecock": "羽毛球场",
            "stop.station": "汉大前站",
            "stop.terminal": "艺术人村",
            "stop.jungang": "中央站",
            "route.circular": "循环",
            "route.direct": "直达",
            "no.scheduled.shuttle": "暂无预定\n校车。",
            "finding.nearest.stop": "正在查找最近的车站",
            "nearest.stop": "最近的车站",
            "other.stops": "查看其他车站",
            "load.failed": "无法载入时刻表。",
            "retry": "重试"
        ]
    ]
}

struct ContentView: View {
    @StateObject private var locationModel = WatchLocationModel()
    @State private var path: [WatchShuttleStop] = []
    @State private var didApplyInitialStop = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if locationModel.resolution == .locating {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(WatchLocalization.text("finding.nearest.stop"))
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    StopListView { stop in
                        locationModel.remember(stop)
                        path.append(stop)
                        Task {
                            await WatchAnalyticsTracker.shared.trackStopSelected(stop.id)
                        }
                    }
                }
            }
            .navigationDestination(for: WatchShuttleStop.self) { stop in
                DepartureListView(
                    stop: stop,
                    isNearest: stop.id == locationModel.nearestStopID,
                    onShowOtherStops: { path.removeAll() }
                )
            }
        }
        .onAppear {
            locationModel.resolve()
        }
        .onReceive(locationModel.$resolution) { resolution in
            guard !didApplyInitialStop,
                  let stopID = resolution.stopID,
                  let stop = WatchShuttleStop.all.first(where: { $0.id == stopID }) else { return }
            didApplyInitialStop = true
            path = [stop]
        }
    }
}

private struct StopListView: View {
    let onSelect: (WatchShuttleStop) -> Void

    var body: some View {
        List {
            ForEach(WatchShuttleStop.all, id: \.self) { stop in
                Button {
                    onSelect(stop)
                } label: {
                    HStack {
                        Text(stop.localizedName)
                            .font(.body)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ContentView()
}
