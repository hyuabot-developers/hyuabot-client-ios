import RxSwift
import Api

class MapData {
    static let shared = MapData()
    let searchKeyword = BehaviorSubject<String?>(value: nil)
    let searchResult = BehaviorSubject<[RoomItem]>(value: [])
    let buildingResult = BehaviorSubject<[MapPageQuery.Data.Building]>(value: [])
    let searchMode = BehaviorSubject<Bool>(value: false)
}
