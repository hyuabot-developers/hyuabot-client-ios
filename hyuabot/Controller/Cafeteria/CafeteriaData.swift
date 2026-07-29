import Api
import Foundation
import RxSwift

@MainActor
class CafeteriaData {
    static let shared = CafeteriaData()
    private init() {}

    let isLoading = BehaviorSubject<Bool>(value: true)
    let feedDate = BehaviorSubject(value: Date.now)
    let breakfastItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]>(value: [])
    let lunchItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]>(value: [])
    let dinnerItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]>(value: [])
}

extension CafeteriaData {
    /// 현재 시각(hour)을 기준으로 홈 화면과 동일하게 조식/중식/석식을 자동 선택한다.
    /// - 10시 이전: 오늘 조식(0)
    /// - 15시 이전: 오늘 중식(1)
    /// - 20시 이전: 오늘 석식(2)
    /// - 20시 이후: 내일 조식(0)
    nonisolated static func automaticMealSelection(
        at date: Foundation.Date = .now
    ) -> (date: Foundation.Date, mealIndex: Int) {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case ..<10:
            return (date, 0)
        case ..<15:
            return (date, 1)
        case ..<20:
            return (date, 2)
        default:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            return (tomorrow, 0)
        }
    }
}
