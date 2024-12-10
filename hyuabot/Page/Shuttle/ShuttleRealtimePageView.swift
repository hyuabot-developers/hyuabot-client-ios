//
//  ShuttleRealtimePageView.swift
//  hyuabot
//
//  Created by 이정인 on 12/4/24.
//

import SwiftUI

struct ShuttleRealtimePageView: View {
    @State private var selectedTab = 0
    let stops: [String.LocalizationValue] = [
        "shuttle.dormitory_o",
        "shuttle.shuttlecock_o",
        "shuttle.station",
        "shuttle.terminal",
        "shuttle.jungang_station",
        "shuttle.shuttlecock_i"
    ]

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Tabs(
                        fixedSize: false,
                        tabs: self.stops.map { Tab(title: String(localized: $0)) },
                        geoWidth: geo.size.width,
                        selectedTab: $selectedTab
                    )
                    TabView(
                        selection: $selectedTab,
                        content: {
                            ShuttleRealtimeTabView(stopID: self.stops[0]).tag(0)
                            ShuttleRealtimeTabView(stopID: self.stops[1]).tag(1)
                            ShuttleRealtimeTabView(stopID: self.stops[2]).tag(2)
                            ShuttleRealtimeTabView(stopID: self.stops[3]).tag(3)
                            ShuttleRealtimeTabView(stopID: self.stops[4]).tag(4)
                            ShuttleRealtimeTabView(stopID: self.stops[5]).tag(5)
                        }
                    ).tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
        }
    }
}

#Preview {
    ShuttleRealtimePageView()
}
