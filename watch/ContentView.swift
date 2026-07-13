//
//  ContentView.swift
//  watch Watch App
//
//  Created by 이정인 on 4/12/25.
//

import Api
import SwiftUI
import Then

struct WatchShuttleStop: Hashable {
    let id: String
    let queryStops: [String]
    let localizationKey: String

    var localizedName: String {
        WatchLocalization.text(localizationKey)
    }

    static let all: [WatchShuttleStop] = [
        WatchShuttleStop(id: "dormitory", queryStops: ["dormitory_o"], localizationKey: "stop.dormitory"),
        WatchShuttleStop(id: "shuttlecock", queryStops: ["shuttlecock_o", "shuttlecock_i"], localizationKey: "stop.shuttlecock"),
        WatchShuttleStop(id: "station", queryStops: ["station"], localizationKey: "stop.station"),
        WatchShuttleStop(id: "terminal", queryStops: ["terminal"], localizationKey: "stop.terminal"),
        WatchShuttleStop(id: "jungang", queryStops: ["jungang_stn"], localizationKey: "stop.jungang")
    ]
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
            "no.scheduled.shuttle": "도착 예정인\n셔틀이 없습니다."
        ],
        "en": [
            "stop.dormitory": "Dormitory",
            "stop.shuttlecock": "Shuttlecoke",
            "stop.station": "Station",
            "stop.terminal": "Terminal",
            "stop.jungang": "Jungang Stn.",
            "route.circular": "Circular",
            "route.direct": "Direct",
            "no.scheduled.shuttle": "No scheduled\nshuttle."
        ],
        "ja": [
            "stop.dormitory": "寮",
            "stop.shuttlecock": "シャトルコック",
            "stop.station": "韓大前駅",
            "stop.terminal": "芸術人村",
            "stop.jungang": "中央駅",
            "route.circular": "循環",
            "route.direct": "直行",
            "no.scheduled.shuttle": "予定されている\nシャトルがありません。"
        ],
        "zh": [
            "stop.dormitory": "宿舍",
            "stop.shuttlecock": "羽毛球场",
            "stop.station": "汉大前站",
            "stop.terminal": "艺术人村",
            "stop.jungang": "中央站",
            "route.circular": "循环",
            "route.direct": "直达",
            "no.scheduled.shuttle": "暂无预定\n校车。"
        ]
    ]
}

struct ContentView: View {
    let stopList = WatchShuttleStop.all
    var body: some View {
        NavigationStack {
            List {
                ForEach(stopList, id: \.self) { stop in
                    NavigationLink(destination: DepartureListView(stop: stop)) {
                        HStack {
                            Text(stop.localizedName).font(.godo(size: 16, weight: .regular))
                            Spacer()
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Task {
                                await WatchAnalyticsTracker.shared.trackStopSelected(stop.id)
                            }
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
