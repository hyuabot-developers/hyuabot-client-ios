import StoreKit
import UIKit

@MainActor
final class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    private init() {}

    private enum Keys {
        static let launchCount = "reviewLaunchCount"
        static let firstLaunchDate = "reviewFirstLaunchDate"
        static let lastRequestDate = "reviewLastRequestDate"
    }

    func trackLaunch() {
        let count = UserDefaults.standard.integer(forKey: Keys.launchCount) + 1
        UserDefaults.standard.set(count, forKey: Keys.launchCount)
        if UserDefaults.standard.object(forKey: Keys.firstLaunchDate) == nil {
            UserDefaults.standard.set(Date(), forKey: Keys.firstLaunchDate)
        }
    }

    func requestReviewIfAppropriate(in scene: UIWindowScene) {
        let launchCount = UserDefaults.standard.integer(forKey: Keys.launchCount)
        let firstLaunch = (UserDefaults.standard.object(forKey: Keys.firstLaunchDate) as? Date) ?? Date()
        let lastRequest = UserDefaults.standard.object(forKey: Keys.lastRequestDate) as? Date

        let daysSinceFirst = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        let daysSinceLast = lastRequest.map {
            Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0
        } ?? Int.max

        guard launchCount >= 5,
              daysSinceFirst >= 7,
              daysSinceLast >= 60 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(Date(), forKey: Keys.lastRequestDate)
        }
    }
}
