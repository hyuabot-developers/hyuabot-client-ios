import QueryAPI

struct SubwayTransferItem {
    let upFrom: SubwayRealtimePageQuery.Data.Subway.Realtime.Up?
    let upTo: SubwayRealtimePageQuery.Data.Subway.Timetable.Up?
    let downFrom: SubwayRealtimePageQuery.Data.Subway.Realtime.Down?
    let downTo: SubwayRealtimePageQuery.Data.Subway.Timetable.Down?
}
