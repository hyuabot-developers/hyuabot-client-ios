// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == QueryAPI.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == QueryAPI.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == QueryAPI.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == QueryAPI.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "BuildingQuery": return QueryAPI.Objects.BuildingQuery
    case "BusDepartureLogQuery": return QueryAPI.Objects.BusDepartureLogQuery
    case "BusRealtimeQuery": return QueryAPI.Objects.BusRealtimeQuery
    case "BusRouteQuery": return QueryAPI.Objects.BusRouteQuery
    case "BusRunningListQuery": return QueryAPI.Objects.BusRunningListQuery
    case "BusRunningTimeQuery": return QueryAPI.Objects.BusRunningTimeQuery
    case "BusStopItem": return QueryAPI.Objects.BusStopItem
    case "BusStopRouteQuery": return QueryAPI.Objects.BusStopRouteQuery
    case "BusTimetableQuery": return QueryAPI.Objects.BusTimetableQuery
    case "CafeteriaQuery": return QueryAPI.Objects.CafeteriaQuery
    case "CafeteriaRunningTimeQuery": return QueryAPI.Objects.CafeteriaRunningTimeQuery
    case "CalendarCategoryQuery": return QueryAPI.Objects.CalendarCategoryQuery
    case "CalendarQuery": return QueryAPI.Objects.CalendarQuery
    case "ContactItemQuery": return QueryAPI.Objects.ContactItemQuery
    case "ContactQuery": return QueryAPI.Objects.ContactQuery
    case "EventQuery": return QueryAPI.Objects.EventQuery
    case "MenuQuery": return QueryAPI.Objects.MenuQuery
    case "Query": return QueryAPI.Objects.Query
    case "ReadingRoomQuery": return QueryAPI.Objects.ReadingRoomQuery
    case "RealtimeListQuery": return QueryAPI.Objects.RealtimeListQuery
    case "RealtimeQuery": return QueryAPI.Objects.RealtimeQuery
    case "RoomQuery": return QueryAPI.Objects.RoomQuery
    case "ShuttlePeriodQuery": return QueryAPI.Objects.ShuttlePeriodQuery
    case "ShuttleQuery": return QueryAPI.Objects.ShuttleQuery
    case "ShuttleStopQuery": return QueryAPI.Objects.ShuttleStopQuery
    case "ShuttleTimetableQuery": return QueryAPI.Objects.ShuttleTimetableQuery
    case "ShuttleViaQuery": return QueryAPI.Objects.ShuttleViaQuery
    case "StationQuery": return QueryAPI.Objects.StationQuery
    case "StopQuery": return QueryAPI.Objects.StopQuery
    case "TimetableListQuery": return QueryAPI.Objects.TimetableListQuery
    case "TimetableQuery": return QueryAPI.Objects.TimetableQuery
    case "TimetableStation": return QueryAPI.Objects.TimetableStation
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
