//
//  ContentView.swift
//  hyuabot
//
//  Created by 이정인 on 12/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ShuttleRealtimePageView().tabItem {
                Image(systemName: "bus")
                Text("shuttle.realtime")
            }.tag(0)
            BusRealtimePageView().tabItem {
                Image(systemName: "bus.doubledecker")
                Text("bus.realtime")
            }.tag(1)
            SubwayRealtimePageView().tabItem {
                Image(systemName: "tram")
                Text("subway.realtime")
            }.tag(2)
            CafeteriaPageView().tabItem {
                Image(systemName: "fork.knife")
                Text("cafeteria")
            }.tag(3)
            ReadingRoomPageView().tabItem {
                Image(systemName: "book")
                Text("readingRoom")
            }.tag(4)
            CalendarPageView().tabItem {
                Image(systemName: "calendar")
                Text("calendar")
            }.tag(5)
            MapPageView().tabItem {
                Image(systemName: "map")
                Text("map")
            }.tag(6)
            SettingPageView().tabItem {
                Image(systemName: "gear")
                Text("setting")
            }.tag(7)
        }
    }
}

#Preview {
    ContentView()
}
