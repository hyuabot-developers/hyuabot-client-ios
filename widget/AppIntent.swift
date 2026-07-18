import AppIntents
import WidgetKit

struct RefreshCafeteriaIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Cafeteria Widget"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "CafeteriaWidget")
        return .result()
    }
}

struct RefreshShuttleIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Shuttle Widget"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "ShuttleWidget")
        return .result()
    }
}

struct RefreshTransferIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Transfer Widget"
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadTimelines(ofKind: "TransferWidget")
        return .result()
    }
}
