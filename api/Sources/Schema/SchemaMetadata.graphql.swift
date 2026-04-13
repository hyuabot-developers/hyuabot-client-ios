// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == Api.SchemaMetadata {}

nonisolated public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == Api.SchemaMetadata {}

nonisolated public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == Api.SchemaMetadata {}

nonisolated public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == Api.SchemaMetadata {}

nonisolated public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  private static let objectTypeMap: [String: ApolloAPI.Object] = [
    "AcademicCalendar": Api.Objects.AcademicCalendar,
    "AcademicCalendarCategory": Api.Objects.AcademicCalendarCategory,
    "AcademicCalendarEvent": Api.Objects.AcademicCalendarEvent,
    "Building": Api.Objects.Building,
    "BusArrival": Api.Objects.BusArrival,
    "BusDepartureLog": Api.Objects.BusDepartureLog,
    "BusRoute": Api.Objects.BusRoute,
    "BusRouteStop": Api.Objects.BusRouteStop,
    "BusRunningTime": Api.Objects.BusRunningTime,
    "BusRunningTimeEntry": Api.Objects.BusRunningTimeEntry,
    "BusStop": Api.Objects.BusStop,
    "BusTimetable": Api.Objects.BusTimetable,
    "Cafeteria": Api.Objects.Cafeteria,
    "CafeteriaRunningTime": Api.Objects.CafeteriaRunningTime,
    "Menu": Api.Objects.Menu,
    "Notice": Api.Objects.Notice,
    "NoticeCategory": Api.Objects.NoticeCategory,
    "Phonebook": Api.Objects.Phonebook,
    "PhonebookCategory": Api.Objects.PhonebookCategory,
    "PhonebookEntry": Api.Objects.PhonebookEntry,
    "Query": Api.Objects.Query,
    "ReadingRoom": Api.Objects.ReadingRoom,
    "ReadingRoomSeat": Api.Objects.ReadingRoomSeat,
    "Room": Api.Objects.Room,
    "Shuttle": Api.Objects.Shuttle,
    "ShuttleArrival": Api.Objects.ShuttleArrival,
    "ShuttlePeriod": Api.Objects.ShuttlePeriod,
    "ShuttleRoute": Api.Objects.ShuttleRoute,
    "ShuttleStop": Api.Objects.ShuttleStop,
    "ShuttleTimetable": Api.Objects.ShuttleTimetable,
    "ShuttleTimetableEntry": Api.Objects.ShuttleTimetableEntry,
    "ShuttleTimetableGroup": Api.Objects.ShuttleTimetableGroup,
    "SubwayArrival": Api.Objects.SubwayArrival,
    "SubwayArrivalGroup": Api.Objects.SubwayArrivalGroup,
    "SubwayOriginTerminal": Api.Objects.SubwayOriginTerminal,
    "SubwayStation": Api.Objects.SubwayStation,
    "SubwayTimetable": Api.Objects.SubwayTimetable
  ]

  @_spi(Execution) public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    objectTypeMap[typename]
  }
}

nonisolated public enum Objects {}
nonisolated public enum Interfaces {}
nonisolated public enum Unions {}
