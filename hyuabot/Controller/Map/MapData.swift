//
//  MapData.swift
//  hyuabot
//

import Api
import RxRelay
import RxSwift

@MainActor
class MapData {
    static let shared = MapData()
    let searchKeyword = BehaviorRelay<String?>(value: nil)
    let searchResult = BehaviorRelay<[RoomItem]>(value: [])
    let buildingResult = BehaviorRelay<[MapPageQuery.Data.Building]>(value: [])
    let searchMode = BehaviorRelay<Bool>(value: false)
}
