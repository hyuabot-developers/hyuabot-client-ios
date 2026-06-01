import WidgetKit
import AppIntents

struct RefreshCafeteriaIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Cafeteria Widget"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "CafeteriaWidget")
        return .result()
    }
}

struct RefreshShuttleIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Shuttle Widget"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "ShuttleWidget")
        return .result()
    }
}

struct RefreshTransferIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Transfer Widget"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "TransferWidget")
        return .result()
    }
}
