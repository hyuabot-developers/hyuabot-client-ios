import RxSwift
import QueryAPI

class MapData {
    static let shared = MapData()
    let searchKeyword = BehaviorSubject<String?>(value: nil)
    let searchResult = BehaviorSubject<[MapPageSearchQuery.Data.Room]>(value: [])
    let buildingResult = BehaviorSubject<[MapPageQuery.Data.Building]>(value: [])
    let searchMode = BehaviorSubject<Bool>(value: false)
}
