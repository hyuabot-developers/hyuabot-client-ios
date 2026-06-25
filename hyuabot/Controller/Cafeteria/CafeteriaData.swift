import Api
import Foundation
import RxSwift

class CafeteriaData {
    static let shared = CafeteriaData()
    private init() {}

    let isLoading = BehaviorSubject<Bool>(value: true)
    let feedDate = BehaviorSubject(value: Date.now)
    let breakfastItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]>(value: [])
    let lunchItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]>(value: [])
    let dinnerItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]>(value: [])
}
