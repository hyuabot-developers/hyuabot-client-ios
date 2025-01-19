import Foundation

import RxSwift
import QueryAPI

class CafeteriaData {
    static let shared = CafeteriaData()
    private init() {}
    
    let feedDate = BehaviorSubject(value: Date.now)
    let cafeteriaMenu = BehaviorSubject<[CafeteriaPageQuery.Data.Menu]> (value: [])
}
