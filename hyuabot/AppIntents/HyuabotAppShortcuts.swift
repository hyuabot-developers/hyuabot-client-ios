//
//  HyuabotAppShortcuts.swift
//  hyuabot
//

import AppIntents

struct HyuabotAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShuttleArrivalIntent(),
            phrases: [
                "\(.applicationName) 셔틀 언제 와",
                "\(.applicationName)에서 셔틀 시간 알려줘",
                "\(.applicationName) \(\.$stop) 셔틀 언제 와",
                "\(.applicationName)에서 \(\.$stop) 셔틀 시간 알려줘",
                "\(.applicationName) \(\.$direction) 셔틀 언제 와",
                "\(.applicationName) 다음 셔틀",
                "\(.applicationName) 셔틀 시간 알려줘",
                "\(.applicationName) \(\.$stop) 다음 셔틀"
            ],
            shortTitle: "intent.shuttle.short.title",
            systemImageName: "bus.fill"
        )
        AppShortcut(
            intent: CafeteriaMenuIntent(),
            phrases: [
                "\(.applicationName) 오늘 학식 뭐야",
                "\(.applicationName)에서 학식 메뉴 알려줘",
                "\(.applicationName) \(\.$day) 학식 뭐야",
                "\(.applicationName) 오늘 \(\.$meal) 메뉴 뭐야",
                "\(.applicationName) \(\.$restaurant) 메뉴 뭐야",
                "\(.applicationName) \(\.$meal) 뭐야",
                "\(.applicationName) \(\.$meal) 메뉴 알려줘",
                "\(.applicationName) 학식 알려줘",
                "\(.applicationName) 오늘 뭐 먹지"
            ],
            shortTitle: "intent.cafeteria.short.title",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: SubwayArrivalIntent(),
            phrases: [
                "\(.applicationName) 전철 언제 와",
                "\(.applicationName)에서 지하철 도착 정보 알려줘",
                "\(.applicationName) \(\.$line) 언제 와",
                "\(.applicationName) \(\.$direction) 전철 언제 와",
                "\(.applicationName) 지하철 언제 와",
                "\(.applicationName) \(\.$line) 도착 정보"
            ],
            shortTitle: "intent.subway.short.title",
            systemImageName: "tram.fill"
        )
        AppShortcut(
            intent: BusArrivalIntent(),
            phrases: [
                "\(.applicationName) 버스 언제 와",
                "\(.applicationName)에서 버스 도착 정보 알려줘",
                "\(.applicationName) \(\.$route) 버스 언제 와",
                "\(.applicationName) 다음 버스",
                "\(.applicationName) \(\.$route) 도착 정보",
                "\(.applicationName) 버스 알려줘"
            ],
            shortTitle: "intent.bus.short.title",
            systemImageName: "bus.doubledecker.fill"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .navy
}
