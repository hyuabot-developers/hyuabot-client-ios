import QueryAPI

struct SubwayRealtimeItem {
    var realtimeUp: SubwayRealtimePageQuery.Data.Subway.Realtime.Up? = nil
    var realtimeDown: SubwayRealtimePageQuery.Data.Subway.Realtime.Down? = nil
    var timetableUp: SubwayRealtimePageQuery.Data.Subway.Timetable.Up? = nil
    var timetableDown: SubwayRealtimePageQuery.Data.Subway.Timetable.Down? = nil
}
