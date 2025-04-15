//
//  ContentView.swift
//  watch Watch App
//
//  Created by 이정인 on 4/12/25.
//

import SwiftUI
import Then
import QueryAPI
import RxSwift

struct ContentView: View {
    let stopList = ["기숙사", "셔틀콕", "한대앞", "예술인", "중앙역", "셔틀콕 건너편"]
    let disposeBag = DisposeBag()
    var body: some View {
        NavigationStack {
            List {
                ForEach(stopList, id: \.self) { stop in
                    NavigationLink(destination: DepartureListView(stop: stop)) {
                        HStack {
                            Text(stop).font(.godo(size: 16, weight: .regular))
                            Spacer()
                        }
                    }
                }
            }
        }.onAppear(perform: {
            self.startPolling()
            self.subscribeData()
                
        })
        .onDisappear(perform: {
            self.stopPolling()
        })
    }
    
    private func subscribeData() {
        ShuttleRealtimeData.shared.shuttleRealtimeData.subscribe(onNext: { data in
            ShuttleRealtimeData.shared.shuttleDormitoryData.onNext(data?.filter({ $0.stop == "dormitory_o" }))
            ShuttleRealtimeData.shared.shuttleShuttlecockData.onNext(data?.filter({ $0.stop == "shuttlecock_o" }))
            ShuttleRealtimeData.shared.shuttleStationData.onNext(data?.filter({ $0.stop == "station" }))
            ShuttleRealtimeData.shared.shuttleTerminalData.onNext(data?.filter({ $0.stop == "terminal" }))
            ShuttleRealtimeData.shared.shuttleJungangStatioData.onNext(data?.filter({ $0.stop == "jungang_stn" }))
            ShuttleRealtimeData.shared.shuttleShuttlecockOppositeData.onNext(data?.filter({ $0.stop == "shuttlecock_i" }))
        }).disposed(by: disposeBag)
    }
    
    private func startPolling() {
        self.fetchShuttleRealtimeData()
        ShuttleRealtimeData.shared.subscription = Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.fetchShuttleRealtimeData()
            })
    }
    
    private func stopPolling() {
        ShuttleRealtimeData.shared.subscription?.dispose()
    }
    
    private func fetchShuttleRealtimeData() {
        let now = Date.now
        let timeFormatter = DateFormatter().then { $0.dateFormat = "HH:mm" }
        let dateTimeFormatter = DateFormatter().then { $0.dateFormat = "yyyy-MM-dd HH:mm" }
        let dataDelegate = ShuttleRealtimeData.shared
        Network.shared.client.fetch(query: ShuttleRealtimePageQuery(shuttleStart: timeFormatter.string(from: now), shuttleDateTime: dateTimeFormatter.string(from: now))) { result in
            if case .success(let response) = result {
                dataDelegate.shuttleRealtimeData.onNext(response.data?.shuttle.timetable.filter({ self.isAfterNow(item: $0) }))
            }
            ShuttleRealtimeData.shared.isLoading.onNext(false)
        }
    }
    
    private func isAfterNow(item: ShuttleRealtimePageQuery.Data.Shuttle.Timetable) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let now = Date.now
        let nowString = dateFormatter.string(from: now)
        return nowString < item.time
    }
}

#Preview {
    ContentView()
}
