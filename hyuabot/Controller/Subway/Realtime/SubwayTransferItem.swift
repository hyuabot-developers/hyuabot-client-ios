import Api

struct SubwayTransferItem {
    let take: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry
    let transfer: SubwayRealtimePageQuery.Data.Subway.Arrival.Entry?
}
