// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == GraphQL.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == GraphQL.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == GraphQL.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == GraphQL.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "BuildingQuery": return GraphQL.Objects.BuildingQuery
    case "BusDepartureLogQuery": return GraphQL.Objects.BusDepartureLogQuery
    case "BusRealtimeQuery": return GraphQL.Objects.BusRealtimeQuery
    case "BusRouteQuery": return GraphQL.Objects.BusRouteQuery
    case "BusStopItem": return GraphQL.Objects.BusStopItem
    case "BusStopRouteQuery": return GraphQL.Objects.BusStopRouteQuery
    case "BusTimetableQuery": return GraphQL.Objects.BusTimetableQuery
    case "CafeteriaQuery": return GraphQL.Objects.CafeteriaQuery
    case "CafeteriaRunningTimeQuery": return GraphQL.Objects.CafeteriaRunningTimeQuery
    case "CalendarCategoryQuery": return GraphQL.Objects.CalendarCategoryQuery
    case "CalendarQuery": return GraphQL.Objects.CalendarQuery
    case "ContactItemQuery": return GraphQL.Objects.ContactItemQuery
    case "ContactQuery": return GraphQL.Objects.ContactQuery
    case "EventQuery": return GraphQL.Objects.EventQuery
    case "MenuQuery": return GraphQL.Objects.MenuQuery
    case "Query": return GraphQL.Objects.Query
    case "ReadingRoomQuery": return GraphQL.Objects.ReadingRoomQuery
    case "RealtimeListQuery": return GraphQL.Objects.RealtimeListQuery
    case "RealtimeQuery": return GraphQL.Objects.RealtimeQuery
    case "RoomQuery": return GraphQL.Objects.RoomQuery
    case "ShuttleQuery": return GraphQL.Objects.ShuttleQuery
    case "ShuttleStopQuery": return GraphQL.Objects.ShuttleStopQuery
    case "ShuttleTimetableQuery": return GraphQL.Objects.ShuttleTimetableQuery
    case "ShuttleViaQuery": return GraphQL.Objects.ShuttleViaQuery
    case "StationQuery": return GraphQL.Objects.StationQuery
    case "StopQuery": return GraphQL.Objects.StopQuery
    case "TimetableListQuery": return GraphQL.Objects.TimetableListQuery
    case "TimetableQuery": return GraphQL.Objects.TimetableQuery
    case "TimetableStation": return GraphQL.Objects.TimetableStation
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
