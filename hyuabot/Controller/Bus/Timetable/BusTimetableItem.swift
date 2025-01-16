import QueryAPI

struct BusTimetableItem {
    var routeName: String
    var timetable: BusTimetablePageQuery.Data.Bus.Route.Timetable
}
