import Foundation

import RxSwift
import Api

class CafeteriaData {
    static let shared = CafeteriaData()
    private init() {}
    
    let feedDate = BehaviorSubject(value: Date.now)
    let breakfastItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]> (value: [])
    let lunchItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]> (value: [])
    let dinnerItems = BehaviorSubject<[CafeteriaPageQuery.Data.Cafeterium]> (value: [])
}
