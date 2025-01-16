import QueryAPI

struct BusRealtimeItem {
    var routeName: String
    var realtime: BusRealtimePageQuery.Data.Bus.Route.Realtime? = nil
    var timetable: BusRealtimePageQuery.Data.Bus.Route.Timetable? = nil
}
