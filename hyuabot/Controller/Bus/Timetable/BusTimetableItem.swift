import QueryAPI

struct BusTimetableItem {
    var routeName: String
    var timetable: BusRealtimePageQuery.Data.Bus.Route.Timetable
}
