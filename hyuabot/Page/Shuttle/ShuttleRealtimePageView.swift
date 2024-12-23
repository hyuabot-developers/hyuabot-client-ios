//
//  ShuttleRealtimePageView.swift
//  hyuabot
//
//  Created by 이정인 on 12/4/24.
//

import SwiftUI
import GraphQL

struct ShuttleRealtimePageView: View {
    @State private var selectedTab = 0
    @State private var dormitoryOutArrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @State private var shuttlecockOutArrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @State private var stationArrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @State private var terminalArrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @State private var jungangStationArrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @State private var shuttlecockInArrival: [ShuttleRealtimePageQuery.Data.Shuttle.Timetable] = []
    @ObservedObject private var pollingManager = PollingManager<String>(interval: 30.0)

    
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
                            ShuttleRealtimeTabView(
                                arrival: $dormitoryOutArrival,
                                stopID: self.stops[0],
                                desinations: [
                                    "shuttle.destination.station",
                                    "shuttle.destination.terminal",
                                    "shuttle.destination.jungang_station"
                                ]
                            ).tag(0)
                            ShuttleRealtimeTabView(
                                arrival: $shuttlecockOutArrival,
                                stopID: self.stops[1],
                                desinations: [
                                    "shuttle.destination.station",
                                    "shuttle.destination.terminal",
                                    "shuttle.destination.jungang_station"
                                ]
                            ).tag(1)
                            ShuttleRealtimeTabView(
                                arrival: $stationArrival,
                                stopID: self.stops[2],
                                desinations: [
                                    "shuttle.destination.campus",
                                    "shuttle.destination.terminal",
                                    "shuttle.destination.jungang_station"
                                ]
                            ).tag(2)
                            ShuttleRealtimeTabView(
                                arrival: $terminalArrival,
                                stopID: self.stops[3],
                                desinations: ["shuttle.destination.campus"]
                            ).tag(3)
                            ShuttleRealtimeTabView(
                                arrival: $jungangStationArrival,
                                stopID: self.stops[4],
                                desinations: ["shuttle.destination.campus"]
                            ).tag(4)
                            ShuttleRealtimeTabView(
                                arrival: $shuttlecockInArrival,
                                stopID: self.stops[5],
                                desinations: ["shuttle.destination.campus"]
                            ).tag(5)
                        }
                    ).tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
        }
        .onAppear(perform: {
            fetchShuttleRealtimeData()
            pollingManager.start {
                fetchShuttleRealtimeData()
            }
        })
        .refreshable {
            fetchShuttleRealtimeData()
            pollingManager.stop()
        }
    }
    
    private func fetchShuttleRealtimeData() {
        let now = Date.now
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        Network.shared.apollo.fetch(query: ShuttleRealtimePageQuery(
            shuttleStart: timeFormatter.string(from: now),
            shuttleDateTime: dateTimeFormatter.string(from: now)
        )) { result in
            switch result {
                case .success(let data):
                if let arrivals = data.data?.shuttle.timetable {
                    self.dormitoryOutArrival = arrivals.filter { $0.stop == "dormitory_o" && $0.time > timeFormatter.string(from: now) }
                    self.shuttlecockOutArrival = arrivals.filter { $0.stop == "shuttlecock_o" && $0.time > timeFormatter.string(from: now) }
                    self.stationArrival = arrivals.filter { $0.stop == "station" && $0.time > timeFormatter.string(from: now) }
                    self.terminalArrival = arrivals.filter { $0.stop == "terminal" && $0.time > timeFormatter.string(from: now) }
                    self.jungangStationArrival = arrivals.filter { $0.stop == "jungang_stn" && $0.time > timeFormatter.string(from: now) }
                    self.shuttlecockInArrival = arrivals.filter { $0.stop == "shuttlecock_i" && $0.time > timeFormatter.string(from: now) }
                }
                case .failure(_):
                    print("Error fetching data")
            }
        }
    }
}

#Preview {
    ShuttleRealtimePageView()
}
