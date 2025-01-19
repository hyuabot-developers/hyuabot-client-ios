import Foundation

import RxSwift
import QueryAPI

class CafeteriaData {
    static let shared = CafeteriaData()
    private init() {}
    
    let feedDate = BehaviorSubject(value: Date.now)
    let cafeteriaMenu = BehaviorSubject<[CafeteriaPageQuery.Data.Menu]> (value: [])
    let breakfastItems = BehaviorSubject<[CafeteriaItem]> (value: [])
    let lunchItems = BehaviorSubject<[CafeteriaItem]> (value: [])
    let dinnerItems = BehaviorSubject<[CafeteriaItem]> (value: [])
}
