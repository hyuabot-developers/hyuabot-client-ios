import Api
import CoreLocation
import Foundation
import RxSwift

/// Canonical stop coordinates used when a stop is missing from the realtime payload
/// (e.g. neither of its routes has a live vehicle) but we still need to compute
/// GPS-based selection or containment.
enum BusStopFallbackCoordinate {
    static let suwonStation = CLLocationCoordinate2D(latitude: 37.2678485, longitude: 127.0001900)

    static func coordinate(for stopSeq: Int32) -> (lat: Double, lng: Double)? {
        switch stopSeq {
        case 202_000_106: (suwonStation.latitude, suwonStation.longitude)
        default: nil
        }
    }
}

@MainActor
class BusRealtimeData {
    static let shared = BusRealtimeData()
    private init() {}
    /// Realtime Query
    let busRealtimeData = BehaviorSubject<[BusRealtimePageQuery.Data.Bus]>(value: [])
    let busRealtimeCityFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeCityFromStation = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeSeoulFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeGunpoFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeSuwonFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeKTXFromCampus = BehaviorSubject<[BusArrivalItem]>(value: [])
    let busRealtimeKTXFromStation = BehaviorSubject<[BusArrivalItem]>(value: [])
    let notices = BehaviorSubject<[BusRealtimePageQuery.Data.Notice.Notice]>(value: [])
    /// Loading State
    let isLoading = BehaviorSubject<Bool>(value: true)
    /// Selected Bus Stop (GPS-based, City tab only)
    let selectedBusStopID: BehaviorSubject<Int32> = {
        let savedID = UserDefaults.standard.integer(forKey: "busStopID")
        return BehaviorSubject(value: savedID == 0 ? 216_000_379 : Int32(savedID))
    }()

    /// Seoul tab section 1 (3102) selected stop — campus stops or one of the 5 remote Seoul-bound stops
    let seoulFirstSelectedStopID: BehaviorSubject<Int32> = {
        let savedID = UserDefaults.standard.integer(forKey: "bus.seoulFirstStopID")
        return BehaviorSubject(value: savedID == 0 ? 216_000_379 : Int32(savedID))
    }()

    /// Seoul tab section 2 (3100/3101/3100N) selected stop — main gate or one of the 5 remote Seoul-bound stops
    let seoulSecondSelectedStopID: BehaviorSubject<Int32> = {
        let savedID = UserDefaults.standard.integer(forKey: "bus.seoulSecondStopID")
        return BehaviorSubject(value: savedID == 0 ? 216_000_719 : Int32(savedID))
    }()

    /// Suwon tab selected stop — campus entrance or Suwon station
    let suwonSelectedStopID: BehaviorSubject<Int32> = {
        let savedID = UserDefaults.standard.integer(forKey: "bus.suwonStopID")
        return BehaviorSubject(value: savedID == 0 ? 216_000_070 : Int32(savedID))
    }()

    /// Whether to show the secondary arrival-time suffix ("▶ HH:mm 도착 예정")
    let showSecondaryEta = BehaviorSubject<Bool>(value: BusRealtimeDisplaySettings.showsSecondaryEta)
    /// Seoul-bound destination used for the secondary ETA when the primary section is on campus
    let seoulTargetStop = BehaviorSubject<BusSeoulTargetStop>(value: BusRealtimeDisplaySettings.seoulTargetStop)
}
