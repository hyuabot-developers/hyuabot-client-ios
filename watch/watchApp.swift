//
//  watchApp.swift
//  watch Watch App
//
//  Created by 이정인 on 4/12/25.
//

import SwiftUI

@main
struct watch_Watch_AppApp: App {
    @Environment(\.scenePhase)
    private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        await WatchAnalyticsTracker.shared.trackAppOpen()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    Task {
                        await WatchAnalyticsTracker.shared.trackAppOpen()
                    }
                }
        }
    }
}
